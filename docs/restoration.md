# Restoration

Checkpoint 1: boot and catalogue, not gameplay.

- Godot project was authored for 4.5 (Mobile). Preserve this configuration.
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

Use the local Godot executable path if it is not on PATH. Inspect the first import for errors. The second command should print `LOL_RESTORATION catalogue=311`. Open the project normally to inspect the board. Local verification on Godot 4.8.beta5: editor import completed and runtime printed `LOL_RESTORATION catalogue=311`. Two expected untyped-card warnings remain (1-055 Kawaii Queen and 1-244 Matchmaker); do not infer their types or effects. The initial Blender import reported stale mesh UID `uid://d0ohijftnfhoy`; the import settings now point to the existing mesh path instead. A forced reimport is still needed to verify this change. Visual board inspection is pending.

## Next checkpoint

Restore card scene population and preview a few individual cards, then inspect zone transfers and phase progression separately.
