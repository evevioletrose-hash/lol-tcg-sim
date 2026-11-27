# Player profile storage (P1)

Local-only, versioned JSON under user://profiles/. No accounts, login, sync, or catalogue edits.

- active_profile.json: schema_version, active_id.
- <profile ID>/profile.json: schema_version, profile_id, name.
- <profile ID>/physical_collection.json and digital_collection.json: schema_version, profile_id, kind, counts.
- <profile ID>/decks/: reserved for later deck work.

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
