extends RefCounted

# Presentation assets are independent of printed definitions and ownership.
# Explicit mappings prevent accidental matches by name, rarity or another edition.
const ARTWORK = {
	"tabletop:1-001": "res://assets/card arts/1-001.jpg",
}

static func path_for(edition: String, card_id: String) -> String:
	return ARTWORK.get(edition + ":" + card_id, "")

static func load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path, "Texture2D"):
		return null
	return ResourceLoader.load(path, "Texture2D") as Texture2D

static func resolve(edition: String, card_id: String) -> Dictionary:
	var path = path_for(edition, card_id)
	var texture = load_texture(path)
	return {
		"path": path,
		"texture": texture,
		"status": "available" if texture != null else ("unmapped" if path.is_empty() else "missing_resource"),
	}
