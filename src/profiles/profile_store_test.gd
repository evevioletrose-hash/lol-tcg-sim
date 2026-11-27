extends RefCounted

const Store = preload("res://src/profiles/profile_store.gd")

func run() -> int:
	var failures: Array[String] = []
	var first = Store.new()
	first.root = "user://profile-test-" + str(Time.get_ticks_usec()) + "/"
	var problem = first.initialize()
	if not problem.is_empty():
		push_error(problem)
		return 1
	var key = first.card_key("tabletop", "1-001")
	var other_edition = first.card_key("digital", "1-001")
	var unknown = first.card_key("tabletop", "9-999")
	if first.active_id != "default" or first.list_profiles().size() != 1:
		failures.append("Default profile creation")
	if not first.add("physical", key, 3).is_empty() or not first.add("digital", key, 1).is_empty():
		failures.append("Add quantities")
	if first.count("physical", key) != 3 or first.count("digital", key) != 1:
		failures.append("Independent inventory counts")
	if not first.add("physical", other_edition, 2).is_empty() or not first.add("physical", unknown).is_empty():
		failures.append("Namespaced and unknown card preservation")
	if first.remove("physical", key, 4).is_empty() or first.add("physical", key, 2147483647).is_empty() or first.add("physical", "1-001").is_empty():
		failures.append("Invalid quantity or key accepted")
	if not first.remove("physical", key).is_empty() or first.count("physical", key) != 2:
		failures.append("Remove quantities")
	if not first.remove("physical", other_edition, 2).is_empty() or first.collection("physical").has(other_edition):
		failures.append("Zero quantity not removed")
	var created = first.create_profile("Second collector")
	if not created.error.is_empty():
		push_error(created.error)
		return 1
	var second_id: String = created.id
	if not first.switch_profile(second_id).is_empty() or first.count("physical", key) != 0 or first.count("digital", key) != 0:
		failures.append("Profile isolation")
	if not first.add("digital", key, 5).is_empty():
		failures.append("Second profile save")
	var reopened = Store.new()
	reopened.root = first.root
	if not reopened.initialize().is_empty() or reopened.active_id != second_id or reopened.count("digital", key) != 5:
		failures.append("Fresh-instance active profile persistence")
	if not reopened.switch_profile("default").is_empty() or reopened.count("physical", key) != 2 or reopened.count("digital", key) != 1 or reopened.count("physical", unknown) != 1:
		failures.append("Reload original collections")
	if first.add("digital", key).is_empty():
		failures.append("Stale session write accepted")
	# The previous valid physical snapshot is kept as backup.
	var path = reopened._inventory_path("default", "physical")
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("Cannot corrupt disposable fixture")
	else:
		file.store_string("broken JSON")
		file.close()
		var recovered = Store.new()
		recovered.root = first.root
		if not recovered.initialize().is_empty() or recovered.warnings.is_empty() or recovered.count("physical", key) != 2 or recovered.count("physical", other_edition) != 2:
			failures.append("Backup recovery")
		elif not recovered.add("physical", key).is_empty() or recovered.count("physical", key) != 3:
			failures.append("Save after backup recovery")
		# Both copies invalid: no automatic reset.
		for damaged in [path, path + ".bak"]:
			var bad = FileAccess.open(damaged, FileAccess.WRITE)
			if bad != null:
				bad.store_string("invalid fixture")
				bad.close()
		var refused = Store.new()
		refused.root = first.root
		if refused.initialize().is_empty() or not refused.active_id.is_empty():
			failures.append("Unreadable collection was reset")
	for id in ["default", second_id]:
		var directory = first.root.path_join(id)
		for name in ["profile.json", "physical_collection.json", "digital_collection.json"]:
			for suffix in ["", ".bak"]:
				var target = directory.path_join(name + suffix)
				if FileAccess.file_exists(target):
					DirAccess.remove_absolute(target)
		DirAccess.remove_absolute(directory.path_join("decks"))
		DirAccess.remove_absolute(directory)
	for suffix in ["", ".bak"]:
		var target = first._active_path() + suffix
		if FileAccess.file_exists(target):
			DirAccess.remove_absolute(target)
	DirAccess.remove_absolute(first.root)
	for failure in failures:
		push_error(failure)
	print("LOL_PROFILES profiles=2 namespaces=2 failures=%d" % failures.size())
	return 0 if failures.is_empty() else 1
