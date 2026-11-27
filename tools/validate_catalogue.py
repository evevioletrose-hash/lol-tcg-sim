"""Validate the current tabletop catalogue without comparing to the old TSV."""
import json
import re
from collections import Counter
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
FIELDS = ("id", "name", "type", "rank", "style", "groove", "text", "club", "phase")
TYPES = {"BB", "Items", "Surprise", "Place"}
STATES = {"unverified", "transcribed", "verified", "conflicting"}

def require(condition, message):
    if not condition:
        raise ValueError(message)

def unique_object(pairs):
    obj = {}
    for key, value in pairs:
        require(key not in obj, f"Duplicate JSON key: {key}")
        obj[key] = value
    return obj

def load(path):
    return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique_object)

def validate(data_dir):
    manifest = load(data_dir / "catalogue.json")
    require(isinstance(manifest, dict), "Invalid manifest")
    require(type(manifest.get("schema_version")) is int and manifest["schema_version"] == 1, "Wrong schema")
    require(manifest.get("edition", "tabletop") == "tabletop", "Wrong edition")
    ids = manifest.get("ids")
    require(isinstance(ids, list) and bool(ids), "Missing IDs")
    require(all(isinstance(i, str) and re.fullmatch(r"[0-9]+-[0-9]+", i) for i in ids), "Invalid card ID")
    require(len(ids) == len(set(ids)), "Duplicate manifest IDs")
    cards = data_dir / "cards"
    require({p.stem for p in cards.glob("*.json")} == set(ids), "Missing or extra card files")
    counts = Counter()
    states = Counter()
    for card_id in ids:
        record = load(cards / f"{card_id}.json")
        require(isinstance(record, dict) and record.get("id") == card_id, f"{card_id}: identity mismatch")
        for field in FIELDS:
            require(field in record and (record[field] is None or isinstance(record[field], str)), f"{card_id}: invalid {field}")
        kind = record["type"]
        require(kind is None or kind == "" or kind in TYPES, f"{card_id}: invalid type")
        require(record["rank"] in (None, "", "?", "1", "2", "3"), f"{card_id}: invalid rank")
        for field in ("style", "groove"):
            value = record[field]
            require(value in (None, "", "?", ".") or (re.fullmatch(r"[+-]?[0-9]+", value) and int(value) >= 0), f"{card_id}: invalid {field}")
        state = record.get("verification", "unverified")
        source = record.get("source", "")
        require(isinstance(state, str) and state in STATES, f"{card_id}: invalid verification")
        require(isinstance(source, str), f"{card_id}: invalid source reference")
        typed = bool((record["name"] or "").strip()) and kind in TYPES
        require(state != "verified" or (typed and bool(source.strip())), f"{card_id}: verified without identity/evidence")
        if typed:
            counts[kind] += 1
        states[state] += 1
    typed = sum(counts.values())
    print(f"LOL_VALIDATE edition=tabletop slots={len(ids)} typed={typed} incomplete={len(ids)-typed} verified={states['verified']} failures=0")
    return counts, states

if __name__ == "__main__":
    try:
        validate(ROOT / "data")
    except (OSError, ValueError, TypeError) as exc:
        print(f"LOL_VALIDATE failures=1: {exc}", file=sys.stderr)
        sys.exit(1)
