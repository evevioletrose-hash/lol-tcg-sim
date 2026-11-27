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

See [roadmap.md](roadmap.md) for the living checklist. Next: P1, profile foundation, with remaining manual edge checks retained. Do not start profile or gameplay work in the same checkpoint.

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

## A2: Archivist editor (core verified)

Launch with `-- --catalogue-editor` in the Godot editor build. Normal startup remains read-only. All numbered slots are searchable; incomplete filter shows slots without runtime definitions. Drafts update preview using the shared factory without altering runtime data, save/revert unlocks navigation, closing prompts before discarding. Saves validate fields, detect changed disk records, write a temporary sibling and replace the original without deleting it first. Partial transcriptions remain legal; hidden type-specific fields are preserved. A test uses a disposable user:// copy of 1-055, not real catalogue data. Run `-- --catalogue-editor-test` and the original `-- --card-workshop-test`. Owner inspected graphical UI; Windows replacement on a disposable fixture passed. Real developer-file save and dirty-close/conflict edge checks remain. Verification metadata and external reconciliation remain A3; profile data remains separate.

### A2 local acceptance evidence

Owner-supplied log at 40051ed, Godot 4.8.beta5:

```text
LOL_CATALOGUE slots=400 typed=311 incomplete=89
LOL_WORKSHOP counts={ "B.B.": 161, "Surprise": 75, "Item": 70, "Place": 5 } failures=0
LOL_ARCHIVIST slots=400 failures=0
LOL_MIGRATION slots=400 typed=311 incomplete=89 fields_verified=3600 failures=0
```

All three checks exited 0. Working tree clean. Owner inspected editor and reported satisfaction with the graphical interface. Fixture save/replace exercised on Windows in user://; source data unchanged. No claim that every interaction or actual res:// save has been manually tested. Expected warnings for two untyped records. A2 core accepted; A3 next, with deferred manual checks and verification filtering recorded in roadmap. Catalogue UID was preserved in ea1b2e4.

## A3a: Spreadsheet reconciliation (core verified)

Developer archivist toolbar opens CSV/TSV import and export. Preview shows per-card local/incoming field differences; no fields selected by default. Blank-fill shortcut, explicit field acceptance, no-op and cancel, duplicate and unknown ID rejection, preflight validation and external-change checks. No canonical source or profile changes during tests. Test `-- --catalogue-reconciliation-test` exercises both export round trips, original TSV literal quotes, multiline quoted text, selective save, no-op, stale baseline, external change, duplicate and unknown IDs. Actual reconciliation-window interaction remains pending. Source references and verification filtering deferred to A3b.

### A3a local acceptance evidence

Owner-supplied log on Godot 4.8.beta5, restoration at f388570: editor import completed, LOL_WORKSHOP failures=0, LOL_ARCHIVIST slots=400 failures=0, LOL_RECONCILIATION failures=0. The first migration verifier invocation stopped on a changed 1-010.json. Owner confirmed this was an intentional test edit and explicitly restored only that file; repeat verifier printed LOL_MIGRATION slots=400 typed=311 incomplete=89 fields_verified=3600 failures=0. Only two generated script UID files remained untracked. This establishes a real developer-file modification as well as fixture-based verification; exact edit content and manual reconciliation UI behavior were not inspected. Final exit codes from the earlier combined run were not captured. Keep snapshot equality out of ordinary regression once intentional corrections begin.

### Edition boundary from parallel research

Research branch da0d0c8 contains an archived January 4, 2022 digital configuration with 300 numbered cards (200 B.B., 88 Item, 12 Place; no Surprise entries), five B.B. stat tiers, structured effects, and tutorial strings with a minimum ten-card deck. This is evidence of a different implementation, not an authoritative replacement for printed rules. A concrete collision: digital 1-400 is Sports Stadium, tabletop 1-400 is rare Pop Heart in the owner's transcription. Keep current catalogue tabletop-only; future multi-edition identity must be namespaced and source-aware. In-game collection ownership is a separate concept from the historical digital edition. Research payloads remain on research, with no merge into restoration.

## A3b: Provenance and structural validation (core verified)

Optional source and verification fields on each tabletop record; existing 400 files unchanged. Manifest explicitly declares tabletop. Typed and verification filters in developer workshop; sources searchable. Verified requires identity and source, and printed changes (including imports) or source edits revoke verified status without deleting evidence. No automatic claims of verification; no historical digital data imported. Added structural Python validator and a disposable Godot provenance fixture. Historical migration verifier now ignores optional metadata but still checks all original printed fields. Automated regression passed; manual graphical review remains. See catalogue-schema.md.

### A3b local acceptance evidence

Owner-supplied complete PowerShell log at 16a1726, Godot 4.8.beta5:

```text
LOL_VALIDATE edition=tabletop slots=400 typed=311 incomplete=89 verified=0 failures=0
LOL_WORKSHOP counts={ "B.B.": 161, "Surprise": 75, "Item": 70, "Place": 5 } failures=0
LOL_ARCHIVIST slots=400 failures=0
LOL_RECONCILIATION failures=0
LOL_PROVENANCE edition=tabletop failures=0
```

All five commands exited 0. Working tree clean. Only expected untyped warnings for 1-055 and 1-244. Automated A3b acceptance complete; manual provenance UI and earlier reconciliation/cancel edge checks remain. No claims of actual physical verification. P1 next; preserve namespace and ownership independence.

## P1: Profile foundation (core verified)

Independent versioned local profile store, default and named profiles, active pointer, separate physical and earned-in-game collections with edition-qualified keys, count/add/remove/adjust, preserved unknown IDs, verified temporary saves and previous-valid backups. Normal workshop profile selector/create controls; no profile writes from developer archivist or catalogue tests. Disposable --profile-test covers isolation, fresh-instance reload, stale session, recovery and refusal to reset corrupt files. Actual process restart and graphical review pending. See profile-schema.md. No quantity editing UI, deck implementation, account system or cross-file atomic guarantee yet.

### P1 first local run and corrective patch

At d46b059, owner reported editor import, structural validation and all four catalogue Godot tests exit 0; profile-test exit 1 at temporary verification of default physical_collection.json. Normal workshop profile field disabled because initialization failed. Suspected Godot JSON numeric type mismatch in dictionary equality; normalize schema version and nested counts to integers before comparing. Split write vs schema vs round-trip error diagnostics. Resume interrupted empty default creation conservatively (no active pointer/identity, only valid empty inventory snapshots and no deck contents), without deleting files. Profile test now starts from interrupted default creation with one valid empty inventory; named profile tests fresh creation. Full visible initialization error and warning in normal workshop. Owner must rerun profile test and graphical creation/switch/restart; P1 remains pending.

### P1 local acceptance evidence

Owner-supplied Godot 4.8.beta5 log at 74674d8: LOL_PROFILES profiles=2 namespaces=2 failures=0, exit 0. Owner confirmed graphical profile creation and switching, and active profile persists after closing/reopening. The d46b059 run had editor import, structural validation and all four catalogue tests exit 0 before the initial profile-save failure; the corrective patch was tested with the targeted profile test, not a repeat of the full catalogue suite. Two new script UID files were untracked at acceptance and owner instructed to commit them. No canonical card edits. P1 core accepted; P2 next. Single-writer design, manual recovery limits and no deletion/rename UI remain documented in profile-schema.md.

## P2: Physical collection core (verified)

Opt-in normal Workshop mode with all numbered tabletop slots, short numeric lookup, owned/missing filters, per-row quantities, quick increment/decrement, direct set/Enter, next visible card, and collection-wide summary. Active profile only; incomplete definitions may be owned, other-edition/unknown IDs preserved outside tabletop completion. No digital inventory or canonical edits. Disposable --physical-collection-test exercises the same handlers, two profiles, persistence and isolation. Notes/condition/wishlist and ownership import/export remain deferred. See profile-schema.md. Full regression and graphical review pending.

### P2 local acceptance evidence

Owner-supplied complete regression log at 922b5e2, Godot 4.8.beta5: LOL_VALIDATE edition=tabletop slots=400 typed=311 incomplete=89 verified=0 failures=0; LOL_WORKSHOP failures=0; LOL_ARCHIVIST slots=400 failures=0; LOL_RECONCILIATION failures=0; LOL_PROVENANCE edition=tabletop failures=0; LOL_PROFILES profiles=2 namespaces=2 failures=0; LOL_PHYSICAL slots=400 failures=0. All seven commands exited 0. Working tree clean; expected unknown type warnings only. Owner inspected graphical mode and reported it works and is satisfactory. Core P2 accepted. Individual manual edge cases were not separately reported. Condition, wishlist, personal notes and ownership spreadsheet import/export remain deferred. P3 next: earned-in-game collection, independent of physical ownership and of the original historical digital edition.

## P3: In-game collection core (verified)

Shared collection browser with explicit three-way mode selector, read-only earned inventory, editor-build --dev-grants for testing, and acquisition batch API scoped to expected active profile. Reuses physical browser and existing safe profile saves. No starter grant, reward economy, acquisition history or historical digital-edition import. Full P2 and new P3 regressions passed. See profile-schema.md.

### P3 local acceptance evidence

Owner-supplied complete regression log at 74ecaf9, Godot 4.8.beta5: LOL_VALIDATE edition=tabletop slots=400 typed=311 incomplete=89 verified=0 failures=0; LOL_WORKSHOP failures=0; LOL_ARCHIVIST slots=400 failures=0; LOL_RECONCILIATION failures=0; LOL_PROVENANCE edition=tabletop failures=0; LOL_PROFILES profiles=2 namespaces=2 failures=0; LOL_PHYSICAL slots=400 failures=0; LOL_DIGITAL slots=400 failures=0. All eight checks exited 0, working tree clean. Only expected untyped warnings. Owner reports persistence in normal use ("it remembers me"); actual editor-flag launch and each graphical edge case not independently confirmed. Core P3 accepted, collection infrastructure checkpoint complete. No starter grant, acquisition history, event deduplication or economy yet. Next proposed V1 artwork binding/fallback and V2 first polished B.B., to be reviewed incrementally. Research remains separate.

## V1: Artwork binding and fallback (core verified)

Operation Glitter begins with a reusable edition-qualified artwork resolver and a shared texture/fallback aperture in the existing B.B., Item and Surprise card scenes. One existing file mapped: tabletop:1-001 -> assets/card arts/1-001.jpg. No name/rarity aliases, new art, catalogue edits, or research merge. Draft and normal preview use the same binding; face-down hides art, missing textures clear old artwork. Place still unsupported. Added --card-artwork-test and docs/card-presentation.md. Local import, regression and visual review pending; original texture's visual crop and exported resource packaging not validated.

### V1 local acceptance evidence

Owner-supplied log at 23055ac, Godot 4.8.beta5: editor import and structural validation plus eight Godot regression tests all exited 0. LOL_ARTWORK available=1 placeholders=305 unsupported=5 failures=0. Only expected unknown-card-type warnings; one generated artwork script UID remains untracked. Owner screenshot confirms the existing 1-001.jpg renders inside the aperture; the image is a photograph of the full physical card, not isolated illustration. Owner explicitly defers deciding how card artwork will work. Preserve the resolver and fallback, treat this binding as temporary reference, do not crop or generate assets without agreement. V2 may focus on card composition independent of final art. Export packaging remains untested.

## V2: B.B. presentation (core verified)

Shared card frame, explicit rank footer and simulator back, B.B. header/stat badges and high-contrast power panel, Workshop/Archivist flip control. Existing node paths and footprint retained. Artwork workflow deferred; temporary photo unchanged. Item/Surprise inherit shared components only. Added --bb-presentation-test across typed B.B. records and long-text fixture. Full regression, screenshot review and resizing remain pending. See card-presentation.md.

### V2 local acceptance evidence

Owner-supplied Godot 4.8.beta5 log at 3dcb612: structural validation and all nine Godot tests exited 0. LOL_BB_PRESENTATION cards=161 failures=0; LOL_ARTWORK available=1 placeholders=305 unsupported=5 failures=0. Only expected unknown-card-type warnings; clean working tree. Owner supplied actual front/back Pop Heart screenshots and approved the design. Plum frame, labeled stats, cream power panel, footer and simulator back visibly render. Temporary full-card reference photograph still present by design. Resizing, long-text readability in actual GUI, and gameplay interactions not independently inspected. V2 accepted; V3 next. No artwork sourcing or research merge.

## V3: Card family (automated core verified)

Mint Item and amber Surprise accents, reusable cream power panel extracted from approved B.B. scene, landscape Place scene using shared base/frame/back and name/effect binding. Normal and draft preview support all four types; landscape fits existing preview width. Surprise presentation preserves printed phase rather than substituting Any for missing text. Existing gameplay projection unchanged apart from retaining raw phase and explicit refusal of legacy board Place spawn. Added --card-family-test, updated smoke/artwork expectations. No artwork, catalogue or profile edits. Full local regression and visual review pending.

### V3 local acceptance evidence

Owner-supplied Godot 4.8.beta5 log at 429e65c: structural validation and ten Godot tests all exited 0. LOL_ARTWORK available=1 placeholders=310 unsupported=0 failures=0; LOL_BB_PRESENTATION cards=161 failures=0; LOL_CARD_FAMILY counts={ "B.B.": 161, "Surprise": 75, "Item": 70, "Place": 5 } failures=0. Working tree clean; only expected unknown-type warnings for 1-055 and 1-244. All 311 typed cards now have supported Workshop presentations. Automated field, orientation, bounds, flip and scale checks passed; actual Item, Surprise and Place screenshots and small-window/long-text graphical review not supplied. No gameplay Place support claimed. V4 proposed next: inspect original 3D prototype, bind supported assets by identity and add optional preview with 2D fallback. Artwork workflow remains deferred; research separate.

## V4: Portable 3D presentation (proof of concept verified)

Owner notes technology may transfer to Lanae/Lacunae FPS card game, but 3D is not a high priority. Inspected historical 3dCard scene, original mesh AABB/material surface metadata and rotator. Kept legacy prototype unchanged. Implemented host-independent texture-fed CardObject3D with authored mesh or generic body fallback, and thin Workshop adapter using existing front/back scenes as one-shot texture sources. Optional inspection only, no profile/canonical changes and no FPS repo edits. --card-3d-test covers four type adapters, identity/printed stats, face state, physical orientation, original body availability, generic fallback and disposal. Actual rendered textures and drag need local testing; no character staging or effects implemented. See card-presentation.md for portability boundary and limitations.

### V4a local acceptance / V4b experiment

Owner log at 23ae46c reports card-family-test and card-3d-test exit 0, LOL_3D_PREVIEW types=4 failures=0, clean working tree. Owner saw flat artwork on the rotating physical card as expected and requested a live Pop Heart experiment. Added generic model viewport producer, explicit tabletop:1-001 binding with imported/embedded model source fallback, continuous front rendering and cleanup checks. Actual character appearance and nested viewport rendering pending local graphical review. No changes to original assets, catalogue, profiles or Lacunae repository.

### V4b acceptance / return to restoration

Owner log at 29eac6b (Godot 4.8.beta5): LOL_LIVE_ART card=1-001 meshes=5 source=res://assets/3d/MERGED_popheart.blend (two inspector opens); LOL_3D_PREVIEW types=4 failures=0; exit 0; clean working tree. Owner confirmed live character renders in GUI. Targeted acceptance only, no full regression after live-art patch or fallback import, broad rendering/performance or export verification. Operation Glitter proof of concept complete; owner requested return to restoration. Defer V5 and broader art workflow. Portable CardObject3D and ModelArtView remain in this repo, no FPS integration. D1 profile-local deck storage and composition summary proposed next; no deck implementation yet.

## D1: Named deck drafts (pending local acceptance)

ProfileStore optional decks/index.json, same verified replacement/backup and stale expected snapshot guard as inventory; no changes to existing profiles required. Deck Builder mode reuses catalogue and preview, profile-local selector, creation/rename, add/remove copies, weighted type/club and known rank summary. No legality or ownership enforcement yet. Unknown edition-qualified keys retained; incomplete definitions not addable through typed browser. --deck-test exercises disposable profiles and snapshot writes, UI handlers and summary. GUI sizing, corrupt index recovery and full regression pending. No canonical data or research changes.
