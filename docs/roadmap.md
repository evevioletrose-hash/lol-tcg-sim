# Dance Off / Restoration roadmap

Living checklist. Current branch: restoration. Original main is our historical baseline.

## Working agreement

- Small reviewable changes; one checkpoint at a time. Read existing code before replacing it.
- Each checkpoint gets a test or explicit manual acceptance check, a local verification, and a journal entry. Do not mark untested features complete.
- Preserve original source data and assets. Record unknown or contradictory information instead of filling gaps by guesswork.
- Game rules reference: [rule-book.pdf](rule-book.pdf), especially printed PDF pages 6–10 for Championship play. Keep rules, source observations, and deliberate simulator deviations distinguishable.
- Prefer data-driven definitions, shared mechanisms and inspectable state. No need to solve the entire effects system before we can collect or preview a card.
- Developer catalogue editing is separate from player profile management. Physical ownership never automatically grants digital ownership.
- Windows test commands should capture logs, exit code, commit and git status and copy the result to the clipboard when practical.

## R — Restoration baseline

- [x] R1: Create restoration branch; preserve main.
- [x] R2: Boot and load 311 typed definitions from 400 numbered rows.
- [x] R3: Reconcile Godot 4.8 migration and card mesh UID references.
- [x] R4: Restore searchable workshop, type filters and 2D previews for B.B., Item and Surprise; text-only Places.
- [x] R5: Verify definition population (306 scenes + 5 text-only entries) and graphical workshop launch.
- [x] R6a: Record final headless layout/test verification (66e0ab5, zero failures).
- [ ] R6b: Visually inspect the migrated 3D mesh before modifying it.

Evidence: 168d43d (migration), 5ecffaf (definition test: 311, zero failures), 28c6c14 (graphical workshop screenshot and successful graphical exit). Two known incomplete named records remain. See [restoration.md](restoration.md).

## A — Card Archivist (next)

### A1 — Lossless catalogue migration
- [x] Review actual TSV columns and original entries, including 87 unnamed slots and two named but untyped slots.
- [x] Draft versioned schema and stable IDs; see [catalogue-schema.md](catalogue-schema.md). Review together at checkpoint close.
- [x] Create deterministic importer and one JSON per ID under data/cards/; preserve original cardlist.txt.
- [x] Store all 400 slots, including incomplete records; runtime projection retains 311 typed definitions.
- [x] Route game and workshop through the same catalogue service; preserve existing runtime interface. Runtime verification passed.
- [x] Compare every migrated value and original typed-card count; verify 400 unique IDs, 311 typed entries, 89 incomplete slots; rerun card workshop tests. Local evidence at 66e0ab5: 3,600 fields verified, zero failures, import and workshop exit 0.
- [x] Review schema and migration results; A1 accepted for continuation. Keep schema v1 extensible; no premature normalization of unknown values.

### A2 — Edit and save (core verified)
- [x] Show all slots, with all-types, per-type and incomplete filters. Complete-only and verification filters can follow with A3.
- [x] Editable card fields, type-specific fields, rank, club, printed stats, text; live preview where a supported type exists.
- [x] Save/revert, field validation, and unsaved-change protection implemented; unknown data remains editable.
- [x] Save to canonical local dataset with same-directory verified temporary write and replacement; explicit developer/editor mode; no profile fields.
- [x] Local regression and fixture test passed at 40051ed: draft isolation, preview, invalid rank, revert, replacement, reload, runtime refresh and source preservation. Owner inspected graphical editor.
- [ ] Manual edge checks: dirty selection/close confirmation, external-file conflict, real developer-file save and diff review when first transcribing. Do not change actual data merely to test.

### A3 — Reconcile external data

A3a core verified at f388570; A3b core verified at 16a1726.
- [x] Import TSV/CSV exports (no online dependency).
- [x] Match by stable card ID, preview field-by-field changes, preserve existing values unless explicitly replaced, and allow skip/accept choices.
- [x] Block duplicate/unknown IDs and stale or external-file conflicts; validate selected records before writing. Incomplete definitions remain visible in the archivist.
- [x] Export interoperable TSV/CSV; document limitations for richer fields.
- [x] Automated round trips, selective save, no-op, stale snapshot, external conflict and duplicate/unknown IDs passed. Source equality restored after discarding owner's intentional test edit.
- [ ] Manual reconciliation-window review and cancel/confirmation checks. No bulk transaction guarantee; each successful save persists.
- [x] A3b: optional source references and verification status (unverified/transcribed/verified/conflicting), independent of personal ownership; typed-only and verification filters.
- [x] Distinguish physical tabletop edition from recovered original digital edition in provenance. Do not import digital definitions into the tabletop catalogue by ID alone.
- [x] Add a structural catalogue validator for routine regression; retain migration equality verifier as a historical snapshot check only.

- [ ] Manual graphical provenance controls and combined filter review.

## P — Profiles and two collections

### P1 — Profile foundation (core verified)
- [x] Versioned profile storage under user://profiles/; default profile, create/switch profiles, safe save/load and backup/recovery.
- [x] Shared inventory operations keyed by stable card ID: count, add, remove, validate nonnegative quantities; handle unknown IDs without losing data.
- [x] Two-profile fixture test passed; owner verified graphical creation/switching and active profile persistence across process restart. No res:// data changes.

### P2 — Physical collection (core verified)
- [x] Track real card quantities independently of digital inventory; fast increment/decrement and completion filters. All numbered slots available, including incomplete definitions.
- [ ] Optional condition, wishlist and personal notes. Keep source verification of definitions separate from personal notes.
- [ ] Physical collection import/export later, with explicit quantities and merge behavior.
- [x] Automated zero, duplicates, missing IDs, persistence and isolation checks passed; owner inspected graphical collection mode and reported it works.

### P3 — Digital collection (core verified)
- [x] Separate digital inventory and batch acquisition operations; no automatic physical-to-digital conversion.
- [x] View owned/unowned, duplicate counts and completion in shared browser.
- [ ] Optional acquisition history, event deduplication and progression (deferred to reward/product work).
- [x] Automated additions/removals, batch rejection, persistence and physical/digital independence passed; owner reports persistence in normal use. Manual editor-flag launch and individual graphical edge cases not separately confirmed.

## V — Card presentation vertical slice

- [x] V1: Artwork resolver, shared aperture and missing-art fallback verified. Existing 1-001.jpg is a temporary full-card reference photo, not isolated artwork.
- [ ] Actual artwork sourcing, cropping and production workflow explicitly deferred by owner; do not block layout work on it.
- [x] V2: B.B. layout, labeled stat badges, shared frame/footer/back and Workshop flip verified. Owner approved Pop Heart front/back screenshots.
- [x] V3: Item, Surprise and landscape Place layouts with shared power panel, frame and back passed automated verification across all 311 typed records.
- [ ] V3 graphical review of Item, Surprise and Place, including small-window sizing and text fit.
- [x] V4: Portable texture-fed 3D card and optional inspection verified at 23ae46c; V4b live Pop Heart model viewport verified at 29eac6b (five meshes, imported original model, headless pass and owner graphical confirmation).
- [ ] V5 (deferred, not a restoration blocker): Animation, materials, rarity finishes and model variants; keep 2D fallback.
- [ ] Verify resizing, long names/effects, missing artwork and 2D/3D data parity. Never make 3D mandatory for gameplay.

## D — Deck builder

- [x] D1: Profile-local named deck index, immediate save/edit, composition summary and unrestricted Workshop deck mode verified at 5a93af3; owner created a deck and approved core workflow.
- [ ] D2: Three non-destructive collection-aware building policies implemented; pending local verification.
- [ ] D3: Championship validation per rulebook p.10: 24–30 cards, one of each unique B.B./Surprise/Place, at most three of the same Item; opponent total Rank difference at most two. Approx. half B.B.s is advice, not mandatory. Flag unknown definitions or ranks; resolve unique-character/variant semantics before enforcement.
- [ ] D4: Build two decks, compare rank and legality, test boundary values and inventory caps. Do not assume both decks must have the same size.

## B — Booster and product experiments

- [ ] B1: Define products and explicit card pools separately from card definitions; record source or experimental status.
- [ ] B2: First deterministic/seedable test pack, open into digital inventory, preserve duplicates; test pack composition and save behavior.
- [ ] B3: Prototype opening animation and collection reveals; optional 3D cards.
- [ ] B4: Research actual products/rarity distributions; do not present speculative pull rates as authentic. Economy, rewards and progression deferred until agreed.

## G — Rules laboratory

- [ ] G1: Inspect zone movement and card instance ownership; single authoritative location, independent face/rest state, explicit attached items, shared active Place. Test transfers and visibility without rendering.
- [ ] G2: Deterministic round/phase state machine: setup, alternating Call B.B., Dress Up, Dance Off, cleanup, next first player. Distinguish round starter, turn player and response/timing windows.
- [ ] G3: Draw/shuffle, pass and recovery when no B.B. is available; test deck exhaustion. Note rulebook ambiguities (pass semantics, face-down cards and edge cases) before choosing policy.
- [ ] G4: Implement a minimal legal Dance Off with known numeric stats, audience tokens, strict comparison, ties, trophies, discard/attached items and resting state. Use the worked example on p.9 as a regression fixture.
- [ ] G5: Reusable effect primitives, target selection, resolution timing and persistent modifiers with source/lifetime; explicit custom effects for exceptions. Unknown or unimplemented powers must be visible, not silently treated as functional.
- [ ] G6: Implement a small curated card pool and a complete local two-player match; test win/end-of-deck rules and skipped phases.
- [ ] G7: Connect rules state to presentation, prompts and action legality; expand implemented cards incrementally. AI, multiplayer and alternate play modes are separate later projects.

## Open decisions (not commitments)

- JSON schema details, file-per-card vs grouped layout after migration review; export packaging of developer data and runtime resources.
- Definition variants, rarity and source evidence representation.
- Profile identity format, physical condition granularity and optional acquisition logs.
- Authentic vs experimental booster distributions and progression.
- Rules ambiguities, face-down card timing, optional modes and multiplayer scope.
- How much 3D belongs in a match versus the gallery.

## Immediate queue

1. A1: schema + lossless migration (verified).
2. A2: editable workshop + save/reload (core verified; manual edge checks remain).
3. A3a: import reconciliation (core verified); A3b: provenance and verification (core verified).
4. P1: profile foundation (core verified); P2: physical collection (core verified); P3: in-game collection (core verified).
5. V1: artwork binding and fallback (verified); V2: first polished B.B. presentation (verified, artwork workflow deferred); V3: Item, Surprise and Place (automated core verified); V4: optional 3D presentation and live illustration proof of concept (verified); further visual work deferred.
6. D1: Profile-local named deck persistence and deck composition summary (core verified). D2 collection-aware building modes next, then D3 championship validation and D4 two-deck comparison.
7. B: Seedable product/pack experiments; G: rules laboratory. Rules work remains independent and may be interleaved in small checkpoints.

At the end of each checkpoint: update this file and the restoration journal; keep the next action small enough for a single shared review.

## Deferred interface organization

Owner notes Workshop is increasingly crowded because it combines development and player-facing tools. Explicitly defer navigation and visual redesign while core systems are under construction. Treat current Workshop as a functional integration workbench, not the final game interface. Later extract shared card browser/preview components and separate player collection, deck building, products, play and developer Archivist workflows. Keep profile, catalogue and gameplay state independent of those screens; do not redesign now merely to reduce visual clutter.
