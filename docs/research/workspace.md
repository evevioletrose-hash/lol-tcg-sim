# Private evidence workspace

The clean branch has only docs/research changes relative to the original main. It excludes the entire old recovery tree and its ancestry. No change to game sources, Godot settings, existing catalogue or root ignore rules. The old research branch remains a staging/safety copy; **do not merge that old branch into main**.

Suggested external vault: F:/lanae/valkyrie. Copy the entire old archaeology directory into it, including the nested violet directory as it exists; preserve all local directory names during staging. Copy any separately located youtube-videos folder too. Keep original archive, temporal objects, survey, original videos, reading room/dossier, contact sheets and recovery scripts. Exact screenshot index path is relative to the dossier, not to the repo. No need to rebuild the reading room. Keep a second backup if possible.

Run the [private vault verifier](tools/verify_vault.py) against the external copy. It discovers the nested reading room rather than assuming a fixed violet layout, verifies 317 nonempty digests against the capture inventory, confirms all indexed screenshot files exist, hashes all 41 atlas anchors, and compares the four source video SHA-256 values. It only reads files; no deletion or edits. Optional --compare-source checks every source file against its copied location (source archaeology corresponds to vault root). This last check also protects nonindexed files. A passing audit is a minimum known evidence check, not proof of all original game materials.

Before retiring the old branch, also run `py -3 docs/research/tools/verify_legacy_archive.py F:/lanae/valkyrie` to compare every original tracked archive file against the external vault. A mismatch is a blocker until reconciled or preserved separately. See [archive recovery](archive-recovery.md) for the retained procedure and exact recovery details.

The original archaeology tools remain in the vault for future recovery. They are not part of the game or needed to read the reference. Some caches contain old absolute paths; the verifier deliberately ignores those and resolves original manifest paths relative to recovered/ and temporal objects by digest. Run old temporal.py --compare-only with explicit private paths if regenerating its cache; do not overwrite the existing reading room.

Share only docs/research and factual research exports. Do not commit the vault, source videos, third-party artwork, archived scripts or original account/redemption data. Git history already published on the old branch is not purged by using this new branch. No force push or history deletion performed.

After both vault checks pass, retire the old research branch; continue research on research-clean until ready to integrate into main. Later bring those docs into restoration by ordinary merge. Source code stays untouched. Keep one living shared reference here; the private dossier is evidence, not a parallel specification.
