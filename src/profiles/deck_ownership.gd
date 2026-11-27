extends RefCounted
## Pure ownership policy. No writes, reservations or catalogue assumptions.
const MODES = ["unrestricted", "physical", "digital"]

static func shortages(counts: Dictionary, owned: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in counts:
		var missing = int(counts[key]) - int(owned.get(key, 0))
		if missing > 0:
			result[key] = missing
	return result

static func permits_addition(mode: String, key: String, quantity: int, owned: Dictionary) -> bool:
	if not mode in MODES or quantity <= 0:
		return false
	return mode == "unrestricted" or quantity <= int(owned.get(key, 0))
