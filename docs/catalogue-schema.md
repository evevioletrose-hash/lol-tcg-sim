# Catalogue schema v1

Canonical data: data/catalogue.json (version and ordered IDs) and data/cards/<id>.json (one record per numbered card). The original cardlist.txt is retained verbatim as the migration baseline, not the runtime source. No personal collection quantities or executable effects are stored here.

All nine fields exist in every file: id, name, type, rank, style, groove, text, club, phase. Values are strings or null. id must match the filename. Preserve raw printed/source spellings and spacing, including Items, ? and .; do not coerce numbers in the canonical record. A string "0" is a known zero; "" is an explicitly empty source cell (meaning not supplied, or not applicable according to type); null means no source column/value was supplied. An unknown numeric stat is not zero. The type determines which fields apply. No claim of physical verification is made by migration. Future verification metadata may be added separately.

For A1 a typed record has a nonempty name and a recognized type. Typed does NOT mean every field is known, the effect is implemented, or the card is legal to play. The 89 untyped/unnamed slots are retained but not yet shown in the workshop; A2 will expose them. The existing Game.card_database projection continues using enums and original display values, including numeric rank conversion; unknown ranks and rule validation will be handled before gameplay. No new rules.

The manifest avoids relying on directory enumeration in exported games; include data/*.json and data/cards/*.json in future Godot export filters (not configured in this checkpoint).

## Verification

Run `python tools/migrate_catalogue.py --verify` to compare every original field and all IDs to the committed JSON. This is a migration snapshot check, not a permanent constraint on future edits. After A2 intentional corrections will differ from the baseline. `--write` refuses to overwrite existing data; do not use it for spreadsheet reconciliation.

Run the existing Godot workshop smoke test. Expected startup: LOL_CATALOGUE slots=400 typed=311 incomplete=89, then LOL_RESTORATION catalogue=311, and LOL_WORKSHOP failures=0. The existing two named/untyped warnings are expected. Game fails explicitly if canonical files cannot load; no silent TSV fallback.

## Spreadsheet reconciliation (A3a)

In developer archivist mode, import CSV or TSV with a header (id/card number, name, type, rank, style, groove, text, club, phase; recognized aliases). Column order is arbitrary; missing columns are left unchanged. Unrecognized columns including Have are reported and ignored, not imported into definitions. The exact original nine-column headerless TSV is accepted as a special legacy format with literal quotes. Headered files use standard delimiter quoting. Use canonical type spellings BB, Items, Surprise, Place. Duplicate IDs, unknown IDs and malformed row widths block apply. All changes begin unchecked; select blank-field fills only chooses empty local cells with nonempty incoming text. Explicitly selecting an incoming blank clears that field. No inferred normalization. Preview is compared against the current canonical snapshot, and selected records are preflighted before saving. Individual record replacements are atomic in the same sense as A2; a multi-card operation is not a transaction and reports partial saves on error. Cancel closes without writes. Export includes all IDs and nine fields, but null and empty both become blank, and future metadata is not included. The original TSV is not an export target. Verification metadata and filters remain A3b.

Test with `-- --catalogue-reconciliation-test` (temporary user:// files only).

## Edition boundary (research note)

Schema v1 currently describes the tabletop catalogue only. Printed card numbers are edition-local identifiers. The archived original digital game's January 2022 configuration on research at da0d0c8 has different stats, effects, rank progression, available card types and ID assignments (e.g. 1-400). Never reconcile that configuration against tabletop records by bare ID. Future edition namespaces and explicit cross-edition mappings are separate decisions. Preserve raw evidence and distinguish transcription, original digital configuration, and interpreted rules. Do not conflate the simulator's future in-game inventory with the historical digital edition.

## Provenance (A3b)

Manifest now explicitly declares edition "tabletop"; loader also accepts the older implicit tabletop manifest. Optional record fields: verification (unverified, transcribed, verified, conflicting; absent = unverified) and source (free-text reference; absent = empty). Existing 400 definitions are unchanged, not automatically verified. Verified requires a typed identity and a nonblank source reference; this is a human attestation, not automatic proof. Printed edits and source-reference changes in the archivist, and selected printed changes from spreadsheet import, invalidate a previous verified status while retaining source evidence. Reconfirm explicitly after reviewing the changed record. Spreadsheet export/import still only covers the nine printed fields, not provenance. Metadata is per-card, not per-field or a full evidence ledger. Complete/typed filter means known name/type, not mechanically playable or every stat known.

Routine check: `python tools/validate_catalogue.py` validates current data, including metadata and file/manifest consistency, without enforcing historical field equality. The old migration verifier compares the original nine fields and ignores metadata; use only to verify the historical transcription remains unchanged. `-- --catalogue-provenance-test` exercises metadata saves, invalidation, verified filter, and import on a disposable fixture.
