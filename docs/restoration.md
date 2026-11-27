# Restoration

Checkpoint 1: boot and catalogue, not gameplay.

- Godot project was originally authored for 4.5 (Mobile), now migrated to 4.8.beta5 (Mobile).
- Run main.tscn; the original two-player board should appear with a catalogue count.
- Expect 311 typed entries from 400 numbered rows: 161 B.B.s, 75 Surprises, 70 Items, 5 Places. The remaining 89 rows (87 unnamed, 2 named but untyped) remain in the original TSV.
- The catalogue can hold Places, but there is no Place scene yet. Unknown stats stay as printed strings.
- The original match initialization and library entry points remain available but are not called by default.
- The Pop Heart effect is still an unconnected draft. Its multi-target case intentionally does not resolve.
- No turn, phase, zone, UI card template, or rules redesign is included in this checkpoint.

## Local verification (PowerShell, from repository root)

```powershell
& godot --headless --editor --path . --import
& godot --headless --path . --quit-after 5
```

Use the local Godot executable path if it is not on PATH. Inspect the first import for errors. The second command should print `LOL_RESTORATION catalogue=311`. Open the project normally to inspect the board. Local verification on Godot 4.8.beta5: editor import completed and runtime printed `LOL_RESTORATION catalogue=311`. Two expected untyped-card warnings remain (1-055 Kawaii Queen and 1-244 Matchmaker); do not infer their types or effects. The initial Blender import reported stale mesh UID `uid://d0ohijftnfhoy`; the import settings now point to the existing mesh path instead. Reimport and the subsequent UID reconciliation passed; migration committed as 168d43d. Final visual comparison of the regenerated 3D mesh and old board remains optional follow-up.

## Next checkpoint

Restore card scene population and preview a few individual cards, then inspect zone transfers and phase progression separately.

## Checkpoint 2: Card workshop

- The primary rules reference is [rule-book.pdf](rule-book.pdf), supplied by the project owner. No new rules are implemented here.
- Godot 4.8 migration was committed locally as 168d43d after import and boot verification; the two incomplete catalogue warnings remain expected.
- Startup now opens the original card library scene, with a searchable list, type filter, existing 2D card previews and definition details. Use `-- --board` to see the old board.
- The five Places are inspectable as text only. The 3D card remains untouched. No artwork has been added.
- A preview is a disposable Card node with no zone or match. The existing factory accepts an optional parent so the board and workshop can share it.
- Preserve the printed card ID including leading zeroes; correct Surprise label paths and remove its orphaned button signal.
- Local smoke test: `godot --headless --path . -- --card-workshop-test` checks identity, text and B.B. stats across the current catalogue, and reports counts and failures. Runtime validation passed on Godot 4.8.beta5. The initial Control inheritance error was repaired in 5ecffaf; layout and empty-search issues were repaired in 2fc5edb and 28c6c14. The owner reported a successful graphical launch and supplied a screenshot showing 311/311 entries and the Pop Heart preview; graphical test exit code 0 is visible. Headless definition test reported zero failures before the final layout revisions; full final headless log was not supplied. Counts intentionally pin this restoration snapshot; update the test when the catalogue grows.

## Continuing work

See [roadmap.md](roadmap.md) for the living checklist. Next: A2, editable workshop. Do not start profile or gameplay work in the same checkpoint.

## A1: Local-first catalogue migration (verified)

400 versioned JSON records and an ordered manifest generated from the original TSV. All 3600 fields checked in memory against the source (including the missing final phase column if present); typed counts {"BB":161,"Surprise":75,"Items":70,"Place":5}. Original TSV unchanged. Catalogue loader is separate from Game and feeds the existing runtime projection. Python snapshot verifier and Godot smoke tests passed locally at 66e0ab5. No editing or profiles yet. See [catalogue-schema.md](catalogue-schema.md).

### A1 local acceptance evidence

Owner-supplied PowerShell results on Godot 4.8.beta5, HEAD 66e0ab5:

```text
LOL_MIGRATION slots=400 typed=311 incomplete=89 fields_verified=3600 failures=0
LOL_CATALOGUE slots=400 typed=311 incomplete=89
LOL_RESTORATION catalogue=311
LOL_WORKSHOP_LAYOUT display=headless viewport=[P: (0.0, 0.0), S: (2.0, 2.0)] root=[P: (0.0, 0.0), S: (1152.0, 648.0)] title=[P: (16.0, 12.0), S: (1120.0, 36.0)] list=[P: (16.0, 153.0), S: (340.0, 483.0)] items=311 filter=0 visible=true
LOL_WORKSHOP counts={ "B.B.": 161, "Surprise": 75, "Item": 70, "Place": 5 } failures=0
```

Migration verifier, editor import, and workshop test all exited 0. Expected untyped warnings for 1-055 and 1-244. Only untracked file: Godot-generated src/cards/card_catalogue.gd.uid; preserve via local commit. A1 is sealed; A2 is next. Graphical layout after migration has not been separately re-tested.

## A2: Archivist editor (implementation pending local acceptance)

Launch with `-- --catalogue-editor` in the Godot editor build. Normal startup remains read-only. All numbered slots are searchable; incomplete filter shows slots without runtime definitions. Drafts update preview using the shared factory without altering runtime data, save/revert unlocks navigation, closing prompts before discarding. Saves validate fields, detect changed disk records, write a temporary sibling and replace the original without deleting it first. Partial transcriptions remain legal; hidden type-specific fields are preserved. A test uses a disposable user:// copy of 1-055, not real catalogue data. Run `-- --catalogue-editor-test` and the original `-- --card-workshop-test`. Verify actual UI and Windows replacement behavior before checking off A2. Verification metadata and external reconciliation remain A3; profile data remains separate.
