extends RefCounted

const FIELDS = ["id", "name", "type", "rank", "style", "groove", "text", "club", "phase"]
const ALIASES = {"id":"id", "number":"id", "card number":"id", "card id":"id", "card name":"name", "name":"name", "type":"type", "card type":"type", "rank":"rank", "style":"style", "starting style":"style", "groove":"groove", "starting groove":"groove", "text":"text", "effect":"text", "card text":"text", "club":"club", "phase":"phase"}
var rows: Dictionary = {}
var changes: Dictionary = {}
var baseline: Dictionary = {}
var errors: Array[String] = []
var notes: Array[String] = []
var unchanged: int = 0

func cell(value) -> String:
	return "" if value == null else str(value)

func read_sheet(path: String) -> bool:
	rows.clear()
	errors.clear()
	notes.clear()
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Cannot open spreadsheet export.")
		return false
	var delimiter = "," if path.get_extension().to_lower() == "csv" else "\t"
	var first = file.get_line().trim_prefix("\ufeff")
	file.seek(0)
	var raw_first = first.split(delimiter)
	var pattern = RegEx.new()
	pattern.compile("^[0-9]+-[0-9]+$")
	# Original headerless TSV deliberately contains literal quotes.
	var legacy = delimiter == "\t" and pattern.search(raw_first[0].strip_edges()) != null
	var columns: Array = []
	if legacy:
		columns = FIELDS.duplicate()
		notes.append("Reading original headerless TSV; quotes are literal.")
	else:
		var header = file.get_csv_line(delimiter)
		for value in header:
			var key = value.trim_prefix("\ufeff").strip_edges().to_lower().replace("_", " ")
			var field = ALIASES.get(key, "")
			if field != "" and field in columns:
				errors.append("Duplicate column: " + field)
			if field == "" and not key.is_empty():
				notes.append("Ignored column: " + key)
			columns.append(field)
		if not "id" in columns:
			errors.append("Header must include id or card number.")
		if not errors.is_empty():
			return false
	var row_number = 0 if legacy else 1
	while not file.eof_reached():
		row_number += 1
		var values: PackedStringArray
		if legacy:
			values = file.get_line().trim_prefix("\ufeff").split("\t")
		else:
			values = file.get_csv_line(delimiter)
		if values.size() == 0 or (values.size() == 1 and values[0].strip_edges().is_empty()):
			continue
		if values.size() != columns.size() and not (legacy and values.size() == 8):
			errors.append("Row %d: expected %d columns, got %d." % [row_number, columns.size(), values.size()])
			continue
		var record: Dictionary = {}
		for i in range(values.size()):
			if columns[i] != "":
				record[columns[i]] = values[i]
		var id = cell(record.get("id")).strip_edges()
		if pattern.search(id) == null:
			errors.append("Row %d: invalid card ID %s." % [row_number, id])
			continue
		if rows.has(id):
			errors.append("Duplicate card ID: " + id)
			continue
		record.id = id
		rows[id] = record
	return errors.is_empty()

func compare(catalogue) -> bool:
	changes.clear()
	baseline.clear()
	unchanged = 0
	if not errors.is_empty():
		return false
	for id in rows:
		if not catalogue.records.has(id):
			errors.append("Unknown card ID: " + id)
			continue
		var local: Dictionary = catalogue.records[id]
		var incoming: Dictionary = rows[id]
		var diffs: Dictionary = {}
		for field in FIELDS:
			if field == "id" or not incoming.has(field):
				continue
			# A spreadsheet cannot distinguish null from empty; don't invent changes.
			if cell(local.get(field)) != cell(incoming[field]):
				diffs[field] = {"local":local.get(field), "incoming":incoming[field]}
		if diffs.is_empty():
			unchanged += 1
		else:
			changes[id] = diffs
			baseline[id] = local.duplicate(true)
	return errors.is_empty()

func missing_choices() -> Dictionary:
	var selected: Dictionary = {}
	for id in changes:
		for field in changes[id]:
			var diff: Dictionary = changes[id][field]
			if cell(diff.local).is_empty() and not cell(diff.incoming).is_empty():
				if not selected.has(id):
					selected[id] = {}
				selected[id][field] = true
	return selected

func apply_selected(catalogue, selected: Dictionary) -> Dictionary:
	var result = {"saved": [], "error": ""}
	if not errors.is_empty():
		result.error = "Import contains errors."
		return result
	var proposed: Dictionary = {}
	# Preflight the entire selected set before writing anything.
	for id in selected:
		if not changes.has(id) or not catalogue.records.has(id) or catalogue.records[id] != baseline[id]:
			result.error = "Catalogue changed since preview: " + str(id)
			return result
		var record: Dictionary = baseline[id].duplicate(true)
		for field in selected[id]:
			if not selected[id][field]:
				continue
			if not changes[id].has(field):
				result.error = "Invalid selected field."
				return result
			record[field] = changes[id][field].incoming
		if record == baseline[id]:
			continue
		var problem: String = catalogue.validate_edit(id, record)
		if not problem.is_empty():
			result.error = id + ": " + problem
			return result
		var disk = catalogue.read_json(catalogue.card_dir.path_join(id + ".json"))
		if disk != baseline[id]:
			result.error = "File changed since preview: " + id
			return result
		proposed[id] = record
	for id in proposed:
		var problem: String = catalogue.save_record(id, proposed[id])
		if not problem.is_empty():
			result.error = id + ": " + problem
			break
		result.saved.append(id)
	return result

func export_sheet(catalogue, path: String) -> String:
	var delimiter = "," if path.get_extension().to_lower() == "csv" else "\t"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return "Cannot write export."
	file.store_csv_line(PackedStringArray(FIELDS), delimiter)
	var ids = catalogue.records.keys()
	ids.sort()
	for id in ids:
		var values: PackedStringArray = []
		for field in FIELDS:
			values.append(cell(catalogue.records[id].get(field)))
		file.store_csv_line(values, delimiter)
	file.flush()
	var code = file.get_error()
	file.close()
	return "" if code == OK else error_string(code)
