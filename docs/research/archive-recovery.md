# Archive recovery and reproducibility

All recovery scripts, raw payloads, original manifests, attempt logs, survey checkpoints and temporal objects live in the private vault. The shared repository retains reference indexes, source fingerprints, findings and this procedure. The [legacy archive inventory](evidence/legacy-archive-inventory.json) lists every tracked file in the original archaeology directory at its final remote tip, using Git blob SHA-1 and byte size. Use the [retirement verifier](tools/verify_legacy_archive.py) to check the actual external copy; no Git repository is needed at the vault.

## Coverage and remaining gaps

Original collapsed CDX: 237 rows, 230 historical 200, 7 non-200; 229 recovered responses, 226 distinct digests. Expanded original indexes: 431 rows, 318 distinct successful digests, 92 not covered by original manifest. Final survey: 438 capture rows, 318 successful distinct digests, 317 verified nonempty payloads. Remaining empty favicon digest 3I42H3S6NNFQ2MSVX7XZKYAYSCX5QBYJ inferred from SHA-1 of zero bytes, not fetched. Final Common Crawl: 161 rows, 115 HTTP 200, 81 distinct successful digests, none absent from Wayback, 96 rows match Wayback timestamp/URL/digest. 49/53 collection queries complete; 2022-49, 2024-18, 2024-22, 2026-30 returned errors; not evidence of no captures.

Two exact WARC fallback captures recovered locally:
- 20240725044047 /login, PC23DW7IBHOB6ZD62MPF5YRTM3URBCGS, CC-MAIN-2024-30, offset 400813284, length 18581.
- 20240912162627 /privacy, 3ZAAMKPIAAUSGW7L6SIRZPIR3FDYXKRI, CC-MAIN-2024-38, offset 417798559, length 16046.

Both verified offline from cached ranges after allowing repeated WARC-Protocol headers; 11 recovery tests passed in the recorded local run. Raw WARC bytes, index record, payload digest and SHA-256 retained privately. Gzip-aware comparison final counts: 10 first capture, 90 normalized changed, 20 identical digest, 3 normalized equal. Normalization strips narrowly named transient token/nonce values, attribute ordering and whitespace; not evidence of substantive changes by itself. July/August 2022 privacy versions had same text arranged differently; alternate Oct/Nov 2024 CSS digest is gzip representation, not proof of content change.

85 unindexed internal strings: 33 plausible assets, 23 apparent parser noise, 18 probable atlas frame names, six likely misresolved Android icon paths, three application routes, two debug infrastructure paths. Example missing candidates: achievements-bg.png, achievements-link-bg2.png, marketplace-banner.png, coin-box-full.png, sold-out-banner-blank.png, dance-off-bg.png, CLOSED_SIGN@2x.png, gold-slider-small.png and card-border-rarity-1-rotated.png through 5. These are references, not proof assets exist. External leads: aacdn.nagich.com and access.nagich.com each referenced by 86 digests; purpose unconfirmed, plus PixiJS, CodeAndWeb, Stripe, Zendesk, Hotjar. Do not probe private routes or live services.

## Recovery tools (run from vault root, not project)

The following commands assume the preserved original archaeology directory was copied as the vault root. Python 3.9+; use one process at a time. No recovered scripts executed. Tests are the author's Python recovery tools only.

    cd F:\lanae\valkyrie
    py -3 -m unittest discover -s . -p "test_*.py"
    py -3 temporal.py --index survey/wayback-index.json --compare-only
    py -3 survey.py scan

Only when pursuing new public captures:
    
    py -3 survey.py wayback
    py -3 survey.py commoncrawl
    py -3 temporal.py --index survey/wayback-index.json --plan
    py -3 cc_recover.py --plan

Survey uses checkpointed per-host/per-collection records, Wayback uncollapsed resume keys, sequential requests, rate limits and bounded queries; 429 stops provider loop. Common Crawl defaults 2021–2026; --from-year/--to-year widen; cache collection list can be refreshed without deleting per-collection checkpoints. Temporal reuses original manifest, exact CDX digest objects, alternate captures and quarantines mismatch bytes; absolute cache paths are not portable. CC recovery validates 206 Content-Range, WARC URI/date/payload digest and computed SHA-1, caches compressed ranges with SHA-256; --offline retries only cached data.

Outputs: survey/summary.json, wayback-index.json, commoncrawl-index.json, dependencies.json, scan-errors.json; temporal/captures.json, objects.json, coverage.json, attempts.jsonl, commoncrawl-recovery.json, empty-index-evidence.json, html-timeline-v2.json and html-diffs-v2/. Keep originals immutable. The scanner is heuristic, not an exhaustive JS parser, and does not cover runtime-generated URLs. External domains are leads only.

Reading room generation: keep the existing dossier. If rebuilding a separate copy, run reading_room.py --out NEW_DIRECTORY (never overwrite). This generator verifies source digests, preserves raw gzip bytes, WARC evidence and aliases, generates inert text copies of archived HTML/JS/CSS/SVG, embeds image/video previews, and produces a digital catalogue/CSV/JSON. The full original configuration is available via extract_digital.py --output NEW_FILE. In the moved vault, the reading-room generator's automatic repo-relative research/physical TSV copy may not find the new checkout; copy current shared docs manually if desired. The private room is not the canonical documentation.

References: https://github.com/internetarchive/wayback/blob/master/wayback-cdx-server/README.md ; https://index.commoncrawl.org/ ; https://commoncrawl.org/get-started ; https://commoncrawl.org/cdxj-index ; https://commoncrawl.org/faq .

No new network recovery performed during retirement audit. Preserve the exact original local evidence, do not publish QR codes, private correspondence or third-party payloads.
