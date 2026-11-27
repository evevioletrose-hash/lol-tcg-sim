extends RefCounted
const Rules = preload("res://src/rules/championship_deck.gd")

func run(game: Game) -> int:
	var failures: Array[String] = []
	var records: Dictionary = {}
	var draft: Dictionary = {}
	for i in range(1, 32):
		var id = "9-%03d" % i
		records[id] = {"name": "Fixture %d" % i, "type": "BB", "rank": "1"}
		if i <= 24:
			draft["tabletop:" + id] = 1
	var original = draft.duplicate(true)
	var valid = Rules.validate(draft, records)
	if valid.status != "passes" or valid.known_rank != 24 or draft != original:
		failures.append("24-card legal fixture or mutation")
	for i in range(25, 32):
		draft["tabletop:9-%03d" % i] = 1
		var report = Rules.validate(draft, records)
		if report.status != ("passes" if i <= 30 else "fails"):
			failures.append("Upper size boundary " + str(i))
	draft = original.duplicate(true)
	draft.erase("tabletop:9-024")
	if Rules.validate(draft, records).status != "fails":
		failures.append("23-card boundary")
	for kind in ["BB", "Surprise", "Place", "Items"]:
		records["9-001"].type = kind
		draft = original.duplicate(true)
		var cap: int = Rules.LIMITS[kind]
		draft["tabletop:9-001"] = cap
		if Rules.validate(draft, records).status != "passes":
			failures.append("Legal copy limit " + kind)
		draft["tabletop:9-001"] = cap + 1
		var report = Rules.validate(draft, records)
		if report.status != "fails" or report.errors[0].code != "copies":
			failures.append("Duplicate cap " + kind)
	records["9-001"].type = "BB"
	draft = original.duplicate(true)
	records["9-001"].rank = "?"
	var unknown = Rules.validate(draft, records)
	if unknown.status != "review" or unknown.known_rank != 23 or unknown.unresolved_rank != 1:
		failures.append("Unknown printed Rank")
	if Rules.compare_rank(valid, unknown).status != "review":
		failures.append("Unknown pair Rank")
	records["9-001"].rank = "1"
	records["9-001"].verification = "conflicting"
	if Rules.validate(draft, records).status != "review":
		failures.append("Conflicting record evidence")
	records["9-001"].erase("verification")
	draft.erase("tabletop:9-001")
	draft["digital:9-001"] = 1
	var wrong_edition = Rules.validate(draft, records)
	if wrong_edition.status != "review" or wrong_edition.unresolved_rank != 1:
		failures.append("Edition isolation")
	draft = original.duplicate(true)
	for i in range(1, 25):
		records["9-%03d" % i].type = "Items"
	var advisory = Rules.validate(draft, records)
	if advisory.status != "passes" or advisory.advice.is_empty():
		failures.append("Half B.B. advice incorrectly enforced")
	# Real same-name variants must remain distinct IDs, with uncertainty visible.
	draft = {"tabletop:1-001": 1, "tabletop:1-400": 1}
	var variant = Rules.validate(draft, game.catalogue.records)
	var found = false
	for issue in variant.review:
		if issue.code == "variant_identity" and issue.keys.size() == 2:
			found = true
	if not found or variant.errors.size() != 1 or variant.errors[0].code != "size":
		failures.append("Pop Heart variant review")
	# The rulebook example: different deck sizes are allowed.
	for i in range(1, 32):
		records["9-%03d" % i].type = "BB"
	draft = original.duplicate(true)
	for i in range(25, 31):
		draft["tabletop:9-%03d" % i] = 1
	var rank30 = Rules.validate(draft, records)
	draft.erase("tabletop:9-030")
	draft.erase("tabletop:9-029")
	var rank28 = Rules.validate(draft, records)
	draft.erase("tabletop:9-028")
	var rank27 = Rules.validate(draft, records)
	if rank30.status != "passes" or rank28.status != "passes" or Rules.compare_rank(rank30, rank28) != {"status": "passes", "difference": 2}:
		failures.append("Inclusive rank difference and unequal sizes")
	if Rules.compare_rank(rank30, rank27) != {"status": "fails", "difference": 3}:
		failures.append("Rank difference 3")
	for failure in failures:
		push_error(failure)
	print("LOL_CHAMPIONSHIP failures=%d" % failures.size())
	return 0 if failures.is_empty() else 1
