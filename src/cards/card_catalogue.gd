extends RefCounted

# Canonical source data is independent of Game enums, scenes and inventories.
const MANIFEST = "res://data/catalogue.json"
const CARD_DIR = "res://data/cards/"
const FIELDS = ["id", "name", "type", "rank", "style", "groove", "text", "club", "phase"]
const KNOWN_TYPES = ["BB", "Items", "Surprise", "Place"]

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
		var record = read_json(CARD_DIR + id + ".json")
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
