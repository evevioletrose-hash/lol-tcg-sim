# Player profile storage (P1)

Local-only, versioned JSON under user://profiles/. No accounts, login, sync, or catalogue edits.

- active_profile.json: schema_version, active_id.
- <profile ID>/profile.json: schema_version, profile_id, name.
- <profile ID>/physical_collection.json and digital_collection.json: schema_version, profile_id, kind, counts.
- <profile ID>/decks/: reserved for later deck work.

Default profile ID is default; additional IDs are random 24-character hex strings. Display names may duplicate and are not paths. Names must be nonblank and at most 64 characters. Profiles are created empty; no deletion or rename in P1.

Inventory counts are positive integers up to 2147483647. Zero removes the key. Keys are edition-qualified, e.g. tabletop:1-001 and digital:1-001, where digital denotes the historical edition, not the inventory kind. Both inventory kinds can store any valid edition-qualified ID, including presently unknown definitions; neither automatically populates the other. No card definition needs to exist to preserve its count. No player data is written to res://.

Save: write and verify temporary sibling, preserve last valid primary as .bak, then replace primary. No cross-file transaction; incomplete newly created folders are not listed until identity is written. Read valid primary first, then valid backup with a visible warning; missing/corrupt inventories fail closed, never reset to empty. Backup represents previous successful save, not necessarily latest state. An unreadable active pointer fails closed. Inventory writes and switching check for stale active pointer; writes compare disk inventory to in-memory copy. Single-writer design; no file locking or multi-process guarantees. No automatic recovery of partial creations or manual backup management UI yet.

Normal workshop shows active profile picker and create/switch controls. Developer archivist and catalogue tests do not initialize real profile storage. P1 intentionally exposes no quantity controls; P2/P3 will consume shared count/collection/add/remove/adjust operations.

Test: -- --profile-test creates disposable user://profile-test-* storage; two profiles, independent inventories, namespaced and unknown IDs, bounds, zero removal, reload into a new store, stale-session rejection, backup recovery and refusal to overwrite unreadable data. Actual restart and GUI checks remain manual.
