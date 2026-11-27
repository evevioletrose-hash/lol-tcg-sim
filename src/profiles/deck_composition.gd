extends RefCounted
## Read-only composition; printed rank, not the legacy integer fallback.
static func summarize(counts: Dictionary, game: Game) -> Dictionary:
	var result = {"copies": 0, "known_rank": 0, "unknown_rank": 0, "unknown_definition": 0, "types": {}, "clubs": {}}
	for key in counts:
		var quantity: int = counts[key]
		result.copies += quantity
		var id = str(key).trim_prefix("tabletop:")
		if not str(key).begins_with("tabletop:") or not game.card_database.has(id):
			result.unknown_definition += quantity
			result.unknown_rank += quantity
			continue
		var raw: Dictionary = game.catalogue.records[id]
		var kind = str(raw.type)
		result.types[kind] = result.types.get(kind, 0) + quantity
		if game.card_database[id].type == Game.Card_Types.BB:
			var club = str(raw.club).strip_edges() if raw.club != null else ""
			if club.is_empty():
				club = "Not catalogued"
			result.clubs[club] = result.clubs.get(club, 0) + quantity
		var rank = str(raw.rank).strip_edges() if raw.rank != null else ""
		if rank in ["1", "2", "3"]:
			result.known_rank += int(rank) * quantity
		else:
			result.unknown_rank += quantity
	return result
