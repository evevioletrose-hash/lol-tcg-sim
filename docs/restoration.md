# Restoration

Checkpoint 1: boot and catalogue, not gameplay.

- Godot project was authored for 4.5 (Mobile). Preserve this configuration.
- Run main.tscn; the original two-player board should appear with a catalogue count.
- Expect 311 populated entries from 400 numbered rows: 161 B.B.s, 75 Surprises, 70 Items, 5 Places. The 89 missing rows remain in the original TSV.
- The catalogue can hold Places, but there is no Place scene yet. Unknown stats stay as printed strings.
- The original match initialization and library entry points remain available but are not called by default.
- The Pop Heart effect is still an unconnected draft. Its multi-target case intentionally does not resolve.
- No turn, phase, zone, UI card template, or rules redesign is included in this checkpoint.

## Local verification (PowerShell, from repository root)

```powershell
& godot --headless --editor --path . --import
& godot --headless --path . --quit-after 5
```

Use the local Godot executable path if it is not on PATH. Inspect the first import for errors. The second command should print `LOL_RESTORATION catalogue=311`. Open the project normally to inspect the board. These tests have not yet been run locally.

## Next checkpoint

Restore card scene population and preview a few individual cards, then inspect zone transfers and phase progression separately.
