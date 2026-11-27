# Player profile storage (P1)

Local-only, versioned JSON under user://profiles/. No accounts, login, sync, or catalogue edits.

- active_profile.json: schema_version, active_id.
- <profile ID>/profile.json: schema_version, profile_id, name.
- <profile ID>/physical_collection.json and digital_collection.json: schema_version, profile_id, kind, counts.
- <profile ID>/decks/index.json: optional D1 deck index; created on first deck save.

Default profile ID is default; additional IDs are random 24-character hex strings. Display names may duplicate and are not paths. Names must be nonblank and at most 64 characters. Profiles are created empty; no deletion or rename in P1.

Inventory counts are positive integers up to 2147483647. Zero removes the key. Keys are edition-qualified, e.g. tabletop:1-001 and digital:1-001, where digital denotes the historical edition, not the inventory kind. Both inventory kinds can store any valid edition-qualified ID, including presently unknown definitions; neither automatically populates the other. No card definition needs to exist to preserve its count. No player data is written to res://.

Save: write and verify temporary sibling, preserve last valid primary as .bak, then replace primary. No cross-file transaction; incomplete newly created folders are not listed until identity is written. Read valid primary first, then valid backup with a visible warning; missing/corrupt inventories fail closed, never reset to empty. Backup represents previous successful save, not necessarily latest state. An unreadable active pointer fails closed. Inventory writes and switching check for stale active pointer; writes compare disk inventory to in-memory copy. Single-writer design; no file locking or multi-process guarantees. Interrupted initial default creation can resume only with no identity or active pointer and valid empty existing inventories/deck directory. Existing populated or unreadable data blocks automatic recovery. Other partial creations and manual backup management remain unsupported. JSON-decoded schema version and counts are normalized to integers before snapshot comparison.

Normal workshop shows active profile picker and create/switch controls. Developer archivist and catalogue tests do not initialize real profile storage. P1 intentionally exposes no quantity controls; P2/P3 will consume shared count/collection/add/remove/adjust operations.

Test: -- --profile-test creates disposable user://profile-test-* storage; two profiles, independent inventories, namespaced and unknown IDs, bounds, zero removal, reload into a new store, stale-session rejection, backup recovery and refusal to overwrite unreadable data. Actual restart and GUI checks remain manual.

## Physical collection mode (P2)

Normal workshop has an opt-in physical collection toggle. Lists all numbered tabletop slots, including incomplete records; type/search and all/owned/missing filters combine. Short numeric queries (1–3 digits, positive) select the corresponding set-one ID exactly. Row quantities, direct set, plus/minus, and next visible card controls use the active profile's physical inventory only. Changes persist immediately via ProfileStore; no implicit write from typing a quantity until Set copies or Enter. Summary counts distinct owned catalogue slots, total copies in those slots, and duplicates (copies minus owned slots), independent of active filters. Other edition/unknown keys remain stored and counted separately, not included in tabletop completion. Profile switch refreshes summary/selection. A failed write displays an error and retains stored quantities. A change under an owned/missing filter can remove the current selection and select the first remaining row. Normal catalogue browsing stays typed-only; developer archivist remains independent. No condition/wishlist/notes or spreadsheet ownership import yet.

Test: -- --physical-collection-test exercises normal Workshop with disposable profile storage, all slots, exact numeric search, +/- and set, invalid/zero counts, incomplete cards, owned/missing filters, summary, profile changes and reload, independent in-game ownership and outside-edition keys, unchanged canonical record and normal browsing. Actual graphical interactions still require local review.

## In-game collection (P3)

The shared Workshop selector replaces the physical toggle: Card Workshop / Physical collection / In-game collection. Both collection modes show all tabletop slots and their respective quantities, owned/missing filters and completion; normal workshop remains typed-only. In-game browsing is read-only; no direct quantity entry. Editor-build launch with -- --dev-grants explicitly enables labeled grant/remove buttons in the in-game view only. Development grants require a typed tabletop definition; removal may remove an owned incomplete definition. These are testing operations, not gameplay or security boundaries. Normal physical entry is unchanged.

ProfileStore.acquire_cards(rewards, expected_profile) accepts a nonempty map of edition-qualified keys to positive integer quantities. It preflights every change and writes the entire digital inventory in one existing safe-save operation, rejecting overflow, invalid keys, stale saves and wrong active profiles. adjust_many is the shared signed-delta primitive, and existing single-card adjust/add/remove use it. Reward pool eligibility is a caller responsibility; storage remains edition-agnostic and retains unknown keys. Acquisition history, reward event deduplication, economy, starter grants and booster generation are deferred. No automatic conversion from physical ownership. Historical digital edition remains a separate namespace; P3 browses simulator ownership of tabletop cards.

-- --digital-collection-test uses disposable profiles, tests normal read-only controls, batch rejection without partial changes, explicit development grant/removal, filters, summaries, profile switch, reload and physical independence. Actual GUI and editor-flag launch need local review.

## Deck builder (D1)

Optional decks/index.json: {"schema_version":1,"profile_id":"default","decks":{"<24 hex ID>":{"name":"Draft","counts":{"tabletop:1-001":2}}}}. Stable IDs, duplicate display names allowed, positive integer counts; empty decks allowed. Same verified temporary save, backup and stale snapshot checks as inventory. Missing index is empty; corrupt primary and backup fail closed. Single writer, no locks. Profiles do not need migration. Unknown edition-qualified keys preserved and removable; typed tabletop catalogue entries can be added via Workshop. No ownership reservation or changes, no legality checks, no delete or explicit ordering yet. Deck Builder mode replaces details with named deck selector, new/rename, composition and deck list; immediate save on successful mutation. Double click a known deck row to inspect; add catalogue selection, remove deck selection. Unrestricted only in D1. Rank sums raw known 1–3 values; missing/unknown definitions/ranks counted separately. Type and B.B. club composition weighted by copies. -- --deck-test tests disposable profile storage, UI handlers, independent decks, rename, add/remove, unknown keys, stale writes, invalid count, reload and profile isolation. Graphical layout and backup fault injection still pending.

### D1 acceptance

At 5a93af3 all thirteen validation/regression commands exited 0, including LOL_DECKS profiles=2 failures=0. Owner created a deck graphically and approved core flow. Restart observation not separately supplied; fixture reload passed. Deck-specific backup fault injection and small-window review remain outstanding. Interface reorganization explicitly deferred; current shared Workshop is an integration workbench.

## D2 ownership policy (core verified)

Deck storage unchanged. DeckOwnership is a pure read-only policy: shortage counts by edition-qualified key and positive addition caps against selected inventory. Workshop selector is session-local, defaults unrestricted at process start, retained across mode/profile changes. Restricted catalogue shows typed owned entries plus typed entries already in current deck; row deck/owned quantities, shortage labels and total shortage. Unknown/untyped keys remain removable in deck list. Switching policy or profile never rewrites a deck; removal always permitted; restricted additions check current profile and reject stale external inventory before enforcing cap. No inventory reservation/consumption, no cross-deck aggregate restrictions, no legality checks. Multiple decks can independently use the same owned card. --deck-ownership-test uses disposable profiles, verifies policy switching, capped additions, removal from shortage, edition isolation, non-consumption, profile switching and stale external inventory guard. UI remains provisional.

### D2 acceptance

At fc00dda all five targeted profile/collection/deck checks exited 0, including LOL_DECK_OWNERSHIP modes=3 failures=0. Owner confirmed graphical policy switching works. Clean working tree. Full suite not rerun at this checkpoint; simultaneous deck ownership requirements and championship legality remain separate future checks.

## D3 validation

Read-only printed Championship validation shown in deck builder. See [championship-validation.md](championship-validation.md). Decks remain drafts and save regardless of rules; ownership, individual legality and pairwise Rank compatibility are distinct. No schema changes.
