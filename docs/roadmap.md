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

A3a: import/export and field reconciliation implemented, pending local verification. A3b: source references and verification filters after acceptance.
- [ ] Import TSV/CSV exports of the original spreadsheet (no online dependency).
- [ ] Match by stable card ID, preview field-by-field changes, preserve existing values unless explicitly replaced, and allow skip/accept choices.
- [ ] Flag duplicate IDs, conflicts and incomplete records. No silent destructive bulk import.
- [ ] Export interoperable TSV/CSV; document limitations for richer fields.
- [ ] Add optional source references and verification status (e.g. unverified/transcribed/verified/conflicting), independent of personal ownership.
- [ ] Test round trip, conflicts, cancellation and no-op imports.

## P — Profiles and two collections

### P1 — Profile foundation
- [ ] Versioned profile storage under user://profiles/; default profile, create/switch profiles, safe save/load and backup/recovery.
- [ ] Shared inventory operations keyed by stable card ID: count, add, remove, validate nonnegative quantities; handle unknown IDs without losing data.
- [ ] Test two profiles and persistence across restart; no res:// changes.

### P2 — Physical collection
- [ ] Track real card quantities independently of digital inventory; fast increment/decrement and completion filters.
- [ ] Optional condition, wishlist and personal notes. Keep source verification of definitions separate from personal notes.
- [ ] Physical collection import/export later, with explicit quantities and merge behavior.
- [ ] Test zero, duplicates, missing IDs, persistence and isolation.

### P3 — Digital collection
- [ ] Separate digital inventory and acquisition operations; no automatic physical-to-digital conversion.
- [ ] View owned/unowned, duplicate counts, completion, and acquisition history if useful.
- [ ] Test additions/removals, persistence and physical/digital independence.

## V — Card presentation vertical slice

- [ ] V1: Assign actual available artwork by stable ID; graceful placeholder, no invented art or card stats.
- [ ] V2: Make one beautiful B.B. using shared components (Pop Heart); typography, readable text, Style/Groove iconography and card back.
- [ ] V3: Support Item, Surprise and landscape Place layouts, retaining existing scene reuse where sensible.
- [ ] V4: Inspect original 3D card, bind its printed fields to the catalogue, and provide optional 2D/3D workshop preview for supported assets.
- [ ] V5: Consider animation, materials, rarity finishes and model variants only after the first slice works; missing 3D assets fall back to 2D.
- [ ] Verify resizing, long names/effects, missing artwork and 2D/3D data parity. Never make 3D mandatory for gameplay.

## D — Deck builder

- [ ] D1: Save/load named decks in profiles using card IDs and quantities; show count, total Rank, type/club composition.
- [ ] D2: Three modes: physical ownership, digital ownership, unrestricted sandbox.
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
3. A3: import reconciliation (next).
4. P1–P3: profiles and independent inventories.
5. Choose the next slice together (presentation, deck building or test pack). Rules work remains independent and may be interleaved in small checkpoints.

At the end of each checkpoint: update this file and the restoration journal; keep the next action small enough for a single shared review.
