extends RefCounted

# Canonical source data is independent of Game enums, scenes and inventories.
const MANIFEST = "res://data/catalogue.json"
const CARD_DIR = "res://data/cards/"
const FIELDS = ["id", "name", "type", "rank", "style", "groove", "text", "club", "phase"]
const KNOWN_TYPES = ["BB", "Items", "Surprise", "Place"]

var card_dir: String = CARD_DIR
var records: Dictionary = {}
var errors: Array[String] = []

func read_json(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Cannot open " + path)
		return null
	var parser = JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		errors.append("Invalid JSON: " + path + ": " + parser.get_error_message())
		return null
	return parser.data

func load_records() -> bool:
	records.clear()
	errors.clear()
	var manifest = read_json(MANIFEST)
	if not manifest is Dictionary:
		errors.append("Invalid catalogue manifest")
		return false
	if manifest.get("schema_version") != 1 or not manifest.get("ids") is Array:
		errors.append("Unsupported catalogue schema or missing IDs")
		return false
	var pattern = RegEx.new()
	pattern.compile("^[0-9]+-[0-9]+$")
	for id in manifest.ids:
		if not id is String:
			errors.append("Non-string card ID")
			continue
		if pattern.search(id) == null or records.has(id):
			errors.append("Invalid or duplicate card ID: " + id)
			continue
		var record = read_json(card_dir + id + ".json")
		if not record is Dictionary or record.get("id") != id:
			errors.append("Missing record or ID mismatch: " + id)
			continue
		var valid = true
		for field in FIELDS:
			if not record.has(field):
				errors.append(id + ": missing field " + field)
				valid = false
			elif record[field] != null and not record[field] is String:
				errors.append(id + ": invalid field type " + field)
				valid = false
		if valid:
			records[id] = record
	return errors.is_empty()

func is_typed(record: Dictionary) -> bool:
	return record.get("name") is String and not record.name.strip_edges().is_empty() and record.get("type") in KNOWN_TYPES

# Keep the original runtime projection while we restore the game.
# A missing column stays null in records, and is omitted from the legacy row.
func legacy_row(record: Dictionary) -> PackedStringArray:
	var row: PackedStringArray = []
	for field in FIELDS:
		if record[field] == null and field == "phase":
			break
		row.append("" if record[field] == null else str(record[field]))
	return row

func typed_count() -> int:
	var count = 0
	for record in records.values():
		if is_typed(record):
			count += 1
	return count

# Accept partial transcriptions. Preserve unknown values.
func validate_edit(id: String, record: Dictionary) -> String:
	if not records.has(id) or record.get("id") != id:
		return "Card identity cannot change."
	for field in FIELDS:
		if not record.has(field) or (record[field] != null and not record[field] is String):
			return "Invalid field: " + field
	var kind = record.get("type")
	if kind != null and kind != "" and not kind in KNOWN_TYPES:
		return "Unknown card type."
	var rank = record.get("rank")
	if rank != null and not rank in ["", "?", "1", "2", "3"]:
		return "Rank must be 1, 2, 3, ? or blank."
	for field in ["style", "groove"]:
		var value = record[field]
		if value != null and not value in ["", "?", "."]:
			if not value.is_valid_int() or int(value) < 0:
				return field.capitalize() + " must be nonnegative, ?, . or blank."
	return ""

func save_record(id: String, record: Dictionary) -> String:
	var problem = validate_edit(id, record)
	if not problem.is_empty():
		return problem
	if record == records[id]:
		return ""
	if card_dir.begins_with("res://") and not OS.has_feature("editor"):
		return "Catalogue editing requires the Godot editor build."
	var path = card_dir.path_join(id + ".json")
	var disk = read_json(path)
	if not disk is Dictionary or disk != records[id]:
		return "File changed outside the workshop. Restart and reconcile before saving."
	var temporary = path + ".tmp-" + str(Time.get_ticks_usec())
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return "Cannot write temporary card file."
	file.store_string(JSON.stringify(record, "\t", false) + "\n")
	file.flush()
	var write_error = file.get_error()
	file.close()
	var reread = read_json(temporary)
	if write_error != OK or not reread is Dictionary or reread != record:
		DirAccess.remove_absolute(temporary)
		return "Temporary write verification failed."
	var result = DirAccess.rename_absolute(temporary, path)
	if result != OK:
		DirAccess.remove_absolute(temporary)
		return "Could not replace card file: " + error_string(result)
	records[id] = record.duplicate(true)
	return ""
