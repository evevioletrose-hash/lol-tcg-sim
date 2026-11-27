extends RefCounted

# Local player data only. Never modifies catalogue definitions or res://.
const ROOT = "user://profiles/"
const KINDS = ["physical", "digital"]
const MAX_COUNT = 2147483647
var root: String = ROOT
var active_id: String = ""
var profile: Dictionary = {}
var inventories: Dictionary = {}
var warnings: Array[String] = []

func _valid_id(id: String) -> bool:
	var pattern = RegEx.new()
	pattern.compile("^(default|[a-f0-9]{24})$")
	return pattern.search(id) != null

func _valid_key(key: String) -> bool:
	var pattern = RegEx.new()
	pattern.compile("^[a-z][a-z0-9_-]*:[0-9]+-[0-9]+$")
	return pattern.search(key) != null

func card_key(edition: String, id: String) -> String:
	return edition + ":" + id

func _name_valid(value: String) -> bool:
	return not value.strip_edges().is_empty() and value.length() <= 64 and not value.contains("\n") and not value.contains("\r")

func _valid_data(data, kind: String, id: String = "") -> bool:
	if not data is Dictionary or data.get("schema_version") != 1:
		return false
	if kind == "active":
		return data.get("active_id") is String and _valid_id(data.active_id)
	if not _valid_id(id) or data.get("profile_id") != id:
		return false
	if kind == "profile":
		return data.get("name") is String and _name_valid(data.name)
	if not kind in KINDS or data.get("kind") != kind or not data.get("counts") is Dictionary:
		return false
	for key in data.counts:
		if not key is String or not _valid_key(key):
			return false
		var quantity = data.counts[key]
		if not (quantity is int or quantity is float):
			return false
		if quantity <= 0 or quantity > MAX_COUNT or quantity != floor(quantity):
			return false
	return true

func _read(path: String, kind: String, id: String = "") -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser = JSON.new()
	if parser.parse(file.get_as_text()) != OK or not _valid_data(parser.data, kind, id):
		return {}
	# Godot JSON decodes numbers as floats. Restore integer types before
	# comparing snapshots or verifying a write (including nested counts).
	var value: Dictionary = parser.data
	value["schema_version"] = int(value["schema_version"])
	if kind in KINDS:
		for key in value.counts:
			value.counts[key] = int(value.counts[key])
	return value

func _exists(path: String) -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")

func _load(path: String, kind: String, id: String = "") -> Dictionary:
	var value = _read(path, kind, id)
	if not value.is_empty():
		return value
	value = _read(path + ".bak", kind, id)
	if not value.is_empty():
		var warning = "Recovered last valid backup: " + path
		if not warning in warnings:
			warnings.append(warning)
	return value

func _replace(path: String, value: Dictionary, kind: String, id: String) -> String:
	var temporary = path + ".tmp-" + str(Time.get_ticks_usec())
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return "Cannot write " + path
	file.store_string(JSON.stringify(value, "  ", false) + "\n")
	file.flush()
	var write_error = file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary)
		return "Temporary save write failed: " + path + ": " + error_string(write_error)
	var reread = _read(temporary, kind, id)
	if reread != value:
		DirAccess.remove_absolute(temporary)
		return "Temporary save " + ("failed schema validation" if reread.is_empty() else "round-trip mismatch") + ": " + path
	var result = DirAccess.rename_absolute(temporary, path)
	if result != OK:
		DirAccess.remove_absolute(temporary)
		return "Could not replace " + path + ": " + error_string(result)
	return ""

func _save(path: String, value: Dictionary, kind: String, id: String = "") -> String:
	if not root.begins_with("user://") or not _valid_data(value, kind, id):
		return "Invalid profile save."
	var previous = _read(path, kind, id)
	if not previous.is_empty():
		var problem = _replace(path + ".bak", previous, kind, id)
		if not problem.is_empty():
			return problem
	elif _exists(path) and _read(path + ".bak", kind, id).is_empty():
		return "Refusing to overwrite unreadable profile data: " + path
	return _replace(path, value, kind, id)

func _profile_path(id: String) -> String:
	return root.path_join(id).path_join("profile.json")

func _inventory_path(id: String, kind: String) -> String:
	return root.path_join(id).path_join(kind + "_collection.json")

func _active_path() -> String:
	return root.path_join("active_profile.json")

func _create(id: String, display_name: String) -> String:
	if not _valid_id(id) or not _name_valid(display_name):
		return "Invalid profile identity or name."
	var directory = root.path_join(id)
	if DirAccess.dir_exists_absolute(directory):
		return "Profile folder already exists."
	if DirAccess.make_dir_recursive_absolute(directory.path_join("decks")) != OK:
		return "Cannot create profile folder."
	# Write identity last; incomplete new folders are not listed as usable.
	for kind in KINDS:
		var problem = _save(_inventory_path(id, kind), {"schema_version": 1, "profile_id": id, "kind": kind, "counts": {}}, kind, id)
		if not problem.is_empty():
			return problem
	return _save(_profile_path(id), {"schema_version": 1, "profile_id": id, "name": display_name}, "profile", id)

func initialize() -> String:
	if not root.begins_with("user://"):
		return "Profile storage must be under user://."
	if DirAccess.make_dir_recursive_absolute(root) != OK:
		return "Cannot open profile storage."
	var id = "default"
	var pointer = _load(_active_path(), "active")
	if not pointer.is_empty():
		id = pointer.active_id
	elif _exists(_active_path()):
		return "Active profile pointer is unreadable. No profile data overwritten."
	elif not DirAccess.dir_exists_absolute(root.path_join(id)):
		var problem = _create(id, "Default")
		if not problem.is_empty():
			return problem
	elif not _exists(_profile_path(id)):
		var problem = _resume_default_creation()
		if not problem.is_empty():
			return problem
	return switch_profile(id)

# A first-run crash may leave an empty folder or an empty inventory before
# identity is saved. Only resume when there is no active pointer or identity
# and all existing inventory snapshots are valid and empty.
func _resume_default_creation() -> String:
	var id = "default"
	for kind in KINDS:
		var path = _inventory_path(id, kind)
		for candidate in [path, path + ".bak"]:
			if FileAccess.file_exists(candidate):
				var existing = _read(candidate, kind, id)
				if existing.is_empty() or not existing.counts.is_empty():
					return "Incomplete default profile contains existing or unreadable collection data. No data overwritten: " + candidate
	if not DirAccess.dir_exists_absolute(root.path_join(id).path_join("decks")):
		if DirAccess.make_dir_recursive_absolute(root.path_join(id).path_join("decks")) != OK:
			return "Cannot resume default profile folder."
	var decks = DirAccess.open(root.path_join(id).path_join("decks"))
	if decks == null or not decks.get_files().is_empty() or not decks.get_directories().is_empty():
		return "Incomplete default profile has existing deck data. No data overwritten."
	for kind in KINDS:
		var path = _inventory_path(id, kind)
		if not _exists(path):
			var problem = _save(path, {"schema_version": 1, "profile_id": id, "kind": kind, "counts": {}}, kind, id)
			if not problem.is_empty():
				return problem
	var problem = _save(_profile_path(id), {"schema_version": 1, "profile_id": id, "name": "Default"}, "profile", id)
	if problem.is_empty():
		warnings.append("Resumed interrupted empty default profile creation.")
	return problem

func list_profiles() -> Array:
	var result: Array = []
	var directory = DirAccess.open(root)
	if directory == null:
		return result
	var ids = directory.get_directories()
	ids.sort()
	for id in ids:
		if not _valid_id(id):
			continue
		var entry = _load(_profile_path(id), "profile", id)
		if not entry.is_empty():
			result.append(entry)
	return result

func create_profile(display_name: String) -> Dictionary:
	display_name = display_name.strip_edges()
	if not _name_valid(display_name):
		return {"id": "", "error": "Enter a profile name (1–64 characters)."}
	var id = Crypto.new().generate_random_bytes(12).hex_encode()
	var problem = _create(id, display_name)
	return {"id": id if problem.is_empty() else "", "error": problem}

func switch_profile(id: String) -> String:
	if not _valid_id(id):
		return "Invalid profile ID."
	var next_profile = _load(_profile_path(id), "profile", id)
	if next_profile.is_empty():
		return "Profile identity is missing or unreadable: " + id
	var next_inventories: Dictionary = {}
	for kind in KINDS:
		var data = _load(_inventory_path(id, kind), kind, id)
		if data.is_empty():
			return "Inventory is missing or unreadable: " + id + "/" + kind
		next_inventories[kind] = data
	var current_pointer = _load(_active_path(), "active")
	if not active_id.is_empty() and current_pointer.get("active_id") != active_id:
		return "Active profile changed outside this session. Restart before switching."
	if current_pointer.get("active_id") != id:
		var problem = _save(_active_path(), {"schema_version": 1, "active_id": id}, "active")
		if not problem.is_empty():
			return problem
	active_id = id
	profile = next_profile
	inventories = next_inventories
	return ""

func count(kind: String, key: String) -> int:
	if not inventories.has(kind):
		return 0
	return int(inventories[kind].counts.get(key, 0))

func collection(kind: String) -> Dictionary:
	if not inventories.has(kind):
		return {}
	return inventories[kind].counts.duplicate(true)

# A batch is preflighted in full and committed as a single inventory snapshot.
# expected_profile prevents a delayed reward from landing in another profile.
func adjust_many(kind: String, changes: Dictionary, expected_profile: String) -> String:
	if active_id.is_empty() or active_id != expected_profile or not inventories.has(kind):
		return "Invalid inventory or changed active profile."
	var next: Dictionary = inventories[kind].duplicate(true)
	for key in changes:
		if not key is String or not _valid_key(key) or not changes[key] is int:
			return "Invalid edition-qualified card key or integer quantity."
		var current = int(next.counts.get(key, 0))
		var delta: int = changes[key]
		if delta < -current or delta > MAX_COUNT - current:
			return "Quantity must remain between 0 and " + str(MAX_COUNT) + "."
		var quantity = current + delta
		if quantity == 0:
			next.counts.erase(key)
		else:
			next.counts[key] = quantity
	if next == inventories[kind]:
		return ""
	var path = _inventory_path(active_id, kind)
	if _load(_active_path(), "active").get("active_id") != active_id or _load(path, kind, active_id) != inventories[kind]:
		return "Profile changed outside this session. Restart before editing."
	var problem = _save(path, next, kind, active_id)
	if problem.is_empty():
		inventories[kind] = next
	return problem

func adjust(kind: String, key: String, delta: int) -> String:
	return adjust_many(kind, {key: delta}, active_id)

# Game systems award positive quantities explicitly, never by copying physical ownership.
# The caller chooses the reward pool and edition; storage preserves unknown keys.
func acquire_cards(rewards: Dictionary, expected_profile: String) -> String:
	if rewards.is_empty():
		return "No cards to acquire."
	for key in rewards:
		if not rewards[key] is int or rewards[key] <= 0:
			return "Acquisition quantities must be positive integers."
	return adjust_many("digital", rewards, expected_profile)

func add(kind: String, key: String, quantity: int = 1) -> String:
	if quantity <= 0:
		return "Add quantity must be positive."
	return adjust(kind, key, quantity)

func remove(kind: String, key: String, quantity: int = 1) -> String:
	if quantity <= 0:
		return "Remove quantity must be positive."
	return adjust(kind, key, -quantity)
