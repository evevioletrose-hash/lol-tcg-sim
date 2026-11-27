"""One-time, lossless TSV migration. Never overwrite an existing catalogue.

Run from any directory: python tools/migrate_catalogue.py --verify
Use --write only for a fresh dataset, not to import new spreadsheets.
"""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIELDS = ("id", "name", "type", "rank", "style", "groove", "text", "club", "phase")

def read_source():
    records = {}
    for line in (ROOT / "cardlist.txt").read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        row = line.split("\t")
        if not 8 <= len(row) <= 9:
            raise ValueError(f"Unexpected column count: {row}")
        record = dict(zip(FIELDS, row + [None] * (len(FIELDS) - len(row))))
        card_id = record["id"]
        if card_id in records or not card_id or card_id != f"1-{len(records)+1:03d}":
            raise ValueError(f"Unexpected or duplicate ID: {card_id}")
        records[card_id] = record
    return records

def encode(value):
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true")
    mode.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    records = read_source()
    if len(records) != 400:
        raise ValueError("Expected 400 source records")
    manifest = {"schema_version": 1, "edition": "tabletop", "ids": list(records)}
    data_dir = ROOT / "data"
    manifest_path = data_dir / "catalogue.json"
    cards_dir = data_dir / "cards"
    if args.write:
        if manifest_path.exists() or cards_dir.exists():
            raise SystemExit("Refusing to overwrite an existing catalogue")
        cards_dir.mkdir(parents=True)
        for card_id, record in records.items():
            (cards_dir / f"{card_id}.json").write_text(encode(record), encoding="utf-8")
        manifest_path.write_text(encode(manifest), encoding="utf-8")
    actual_manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if actual_manifest.get("schema_version") != 1 or actual_manifest.get("edition", "tabletop") != "tabletop" or actual_manifest.get("ids") != manifest["ids"]:
        raise ValueError("Manifest differs from source")
    if {p.stem for p in cards_dir.glob("*.json")} != set(records):
        raise ValueError("Missing or extra card files")
    counts = {"BB": 0, "Surprise": 0, "Items": 0, "Place": 0}
    for card_id, expected in records.items():
        actual = json.loads((cards_dir / f"{card_id}.json").read_text(encoding="utf-8"))
        if any(key not in actual or actual[key] != value for key, value in expected.items()):
            raise ValueError(f"Source mismatch: {card_id}")
        if actual["name"].strip() and actual["type"] in counts:
            counts[actual["type"]] += 1
    typed = sum(counts.values())
    if counts != {"BB": 161, "Surprise": 75, "Items": 70, "Place": 5}:
        raise ValueError(f"Unexpected typed counts: {counts}")
    print(f"LOL_MIGRATION slots={len(records)} typed={typed} incomplete={len(records)-typed} fields_verified={len(records)*len(FIELDS)} failures=0")

if __name__ == "__main__":
    main()
