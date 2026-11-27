extends RefCounted
## Printed tabletop Championship, manual PDF p.10. No UI or profile dependency.
const MIN_CARDS = 24
const MAX_CARDS = 30
const MAX_RANK_DIFFERENCE = 2
const LIMITS = {"BB": 1, "Items": 3, "Surprise": 1, "Place": 1}

static func _issue(code: String, message: String, keys: Array = []) -> Dictionary:
	return {"code": code, "message": message, "keys": keys}

static func validate(counts: Dictionary, records: Dictionary) -> Dictionary:
	var errors: Array[Dictionary] = []
	var review: Array[Dictionary] = []
	var advice: Array[Dictionary] = []
	var total: int = 0
	var known_rank: int = 0
	var unresolved_rank: int = 0
	var bb_count: int = 0
	var unknown_count: int = 0
	var names: Dictionary = {}
	var keys = counts.keys()
	keys.sort()
	for key in keys:
		var value = counts[key]
		if not value is int or value <= 0 or value > 2147483647:
			errors.append(_issue("quantity", "%s: invalid positive integer count." % key, [key]))
			continue
		var quantity: int = value
		total += quantity
		var id = str(key).trim_prefix("tabletop:")
		var raw: Dictionary = records.get(id, {})
		var kind = str(raw.get("type", "")).strip_edges()
		var name = str(raw.get("name", "")).strip_edges() if raw.get("name") != null else ""
		if not str(key).begins_with("tabletop:") or name.is_empty() or not LIMITS.has(kind):
			unknown_count += quantity
			unresolved_rank += quantity
			review.append(_issue("definition", "%s: tabletop definition unavailable (%d copies)." % [key, quantity], [key]))
			continue
		var limit: int = LIMITS[kind]
		if quantity > limit:
			errors.append(_issue("copies", "%s (%s): %d copies, maximum %d." % [name, id, quantity, limit], [key]))
		if kind == "BB":
			bb_count += quantity
		var rank = str(raw.get("rank", "")).strip_edges() if raw.get("rank") != null else ""
		if rank in ["1", "2", "3"]:
			known_rank += int(rank) * quantity
		else:
			unresolved_rank += quantity
			review.append(_issue("rank", "%s (%s): printed Rank unresolved." % [name, id], [key]))
		if raw.get("verification", "") == "conflicting":
			review.append(_issue("conflicting_record", "%s (%s): catalogue evidence marked conflicting." % [name, id], [key]))
		# Same name + same type is a lead, not a proved shared card identity.
		# Never merge definitions, change counts or infer aliases from spelling.
		var group_key = kind + ":" + name.to_lower()
		if not names.has(group_key):
			names[group_key] = {"name": name, "limit": limit, "copies": 0, "keys": []}
		names[group_key].copies += quantity
		names[group_key].keys.append(key)
	for group in names.values():
		if group.keys.size() > 1 and group.copies > group.limit:
			review.append(_issue("variant_identity", "%s: distinct IDs share a name and together exceed %d copies; variant uniqueness is unresolved." % [group.name, group.limit], group.keys))
	if total < MIN_CARDS or total > MAX_CARDS:
		errors.append(_issue("size", "Deck has %d cards; Championship requires 24–30." % total))
	# Half is advice, not a requirement. A deck with unresolved definitions
	# cannot yet be assessed for this recommendation.
	if total > 0 and unknown_count == 0 and bb_count * 2 < total:
		advice.append(_issue("bb_advice", "%d of %d cards are B.B.s; the manual recommends about half." % [bb_count, total]))
	var status = "fails" if not errors.is_empty() else ("review" if not review.is_empty() else "passes")
	return {"status": status, "errors": errors, "review": review, "advice": advice, "copies": total, "known_rank": known_rank, "unresolved_rank": unresolved_rank, "bb_count": bb_count}

# Pairwise Rank only. Individual legality and ownership remain separate.
static func compare_rank(left: Dictionary, right: Dictionary) -> Dictionary:
	if left.unresolved_rank > 0 or right.unresolved_rank > 0:
		return {"status": "review", "difference": null}
	var difference = absi(int(left.known_rank) - int(right.known_rank))
	return {"status": "passes" if difference <= MAX_RANK_DIFFERENCE else "fails", "difference": difference}

static func describe(report: Dictionary) -> String:
	var lines: PackedStringArray = ["Printed Championship / rulebook p.10"]
	for section in ["errors", "review", "advice"]:
		for issue in report[section]:
			lines.append("%s: %s" % [section.capitalize(), issue.message])
	if report.errors.is_empty() and report.review.is_empty():
		lines.append("Meets checked individual deck rules.")
	lines.append("Opponent Rank difference must be at most two; compare separately.")
	lines.append("Ownership and effect implementation are separate checks. Catalogue transcriptions are not necessarily verified.")
	return "\n".join(lines)
