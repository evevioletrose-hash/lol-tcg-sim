# Catalogue schema v1

Canonical data: data/catalogue.json (version and ordered IDs) and data/cards/<id>.json (one record per numbered card). The original cardlist.txt is retained verbatim as the migration baseline, not the runtime source. No personal collection quantities or executable effects are stored here.

All nine fields exist in every file: id, name, type, rank, style, groove, text, club, phase. Values are strings or null. id must match the filename. Preserve raw printed/source spellings and spacing, including Items, ? and .; do not coerce numbers in the canonical record. A string "0" is a known zero; "" is an explicitly empty source cell (meaning not supplied, or not applicable according to type); null means no source column/value was supplied. An unknown numeric stat is not zero. The type determines which fields apply. No claim of physical verification is made by migration. Future verification metadata may be added separately.

For A1 a typed record has a nonempty name and a recognized type. Typed does NOT mean every field is known, the effect is implemented, or the card is legal to play. The 89 untyped/unnamed slots are retained but not yet shown in the workshop; A2 will expose them. The existing Game.card_database projection continues using enums and original display values, including numeric rank conversion; unknown ranks and rule validation will be handled before gameplay. No new rules.

The manifest avoids relying on directory enumeration in exported games; include data/*.json and data/cards/*.json in future Godot export filters (not configured in this checkpoint).

## Verification

Run `python tools/migrate_catalogue.py --verify` to compare every original field and all IDs to the committed JSON. This is a migration snapshot check, not a permanent constraint on future edits. After A2 intentional corrections will differ from the baseline. `--write` refuses to overwrite existing data; do not use it for spreadsheet reconciliation.

Run the existing Godot workshop smoke test. Expected startup: LOL_CATALOGUE slots=400 typed=311 incomplete=89, then LOL_RESTORATION catalogue=311, and LOL_WORKSHOP failures=0. The existing two named/untyped warnings are expected. Game fails explicitly if canonical files cannot load; no silent TSV fallback.
