# Digital edition: first static analysis

Observations are from recovered payloads, not from executing the game. Original archive stays immutable. Keep physical and digital IDs scoped to edition; no automatic import to tabletop catalogue. A separate local extraction tool is extract_digital.py (private archive tool `extract_digital.py`); writes a new JSON output with capture provenance and SHA-256, refuses overwrite. The clean research reference includes a [300-card factual projection](evidence/digital-card-facts.json).

## Sources

- Game data, 2022-01-04 (private archive: `recovered/payloads/game.playlolsurprise.com/production/json/json__20220104043838.js`; see [source inventory](evidence/original-objects.json)): JSON_DATA parsed as JSON, no JS execution. Data, particles, en/de/it strings and app configuration.
- Website app, Jan 2022 (private archive: `recovered/payloads/playlolsurprise.com/js/app__20220104042201.js`; see [source inventory](evidence/original-objects.json)) and Dec 2022 (private archive: `recovered/payloads/playlolsurprise.com/js/app__q-2622a5709194__20221207095332.js`; see [source inventory](evidence/original-objects.json)): static UI strings, not game engine.
- Terms, May 2022 (private archive: `recovered/payloads/playlolsurprise.com/terms__20220519190722.html`; see [source inventory](evidence/original-objects.json)): sections 4, 6, 7; contractual claims, not verification of implementation.
- [Physical TSV](../../cardlist.txt): owner's transcription, not authoritative complete set.
- Recovery manifest (private archive: `recovered/manifest.json`; see [source inventory](evidence/original-objects.json)): 237 entries, 229 recovered, 7 historical non-200, 1 failed (favicon).

## Card inventory and edition comparison

200 B.B.s, 88 Items, 12 Places, no Surprise array. 300 distinct IDs. All B.B.s have five stat tiers. 22 clubs including 24k Gold and Elektro (#InstaGold and EDMB.B. respectively). All 12 Place special objects are disabled in this capture; text and references remain.

Comparison keyed by ID against original 400-row TSV: 236 typed physical records overlap digital; 235 same type; 227 of those have matching names after lowercasing and removing non-ASCII-alphanumeric characters. Eight name mismatches (mostly plausible spelling/transcription differences; verify against cards): 1-020, 1-074, 1-184, 1-351, 1-363, 1-367, 1-372, 1-383. One type mismatch: 1-400 physical rare Pop Heart vs digital Sports Stadium. 64 of the 89 incomplete slots have digital counterparts, but not necessarily identical printed values.

Of 160 same-type B.B. pairs, 155 have numeric physical Style and Groove. All 155 match digital rank 1 in both stats; 91 match digital tier indexed by printed physical Rank. Strong evidence the printed base stats were retained while rank became a different axis. No proof of upgrade mechanism from stat tiers alone. Website strings refer to combining duplicate cards into legendary cards, including draft-sounding wording; mechanism and cost still unconfirmed.

Mean Style/Groove over 200 digital B.B.s by tier:
1 8.100 / 2.565
2 9.100 / 2.800
3 10.160 / 3.470
4 11.155 / 3.645
5 12.395 / 4.185

Examples of semantic differences (physical transcription vs digital description, paraphrased):
- Pop Heart 1-001: reveal hidden B.B. -> grant Art allies Style.
- Shapes 1-002: copy starting stats -> fixed stats, adjacency Groove bonus.
- Hoops MVP 1-004: gain Groove for each Athletic ally -> grant Groove to other Athletic teammates.
- Snow Bunny 1-118: draw when phase skipped -> draw a card.
- King Bee 1-137: recruit Queen Bee from several zones -> Style bonus conditional on Queen Bee's Boutique.
- Bon Bon 1-174: discard and all-club membership -> discard only.
- Tinz 1-195: discard and conditional trophy -> discard only.

## Tutorial and gameplay reconstruction

English tutorial steps 1–36 and how-to-play strings support alternating B.B. placement until both pass, alternating item assignment, attacker and defender choice, Audience Groove spinner stopped by user, strict attack Groove plus audience > defense Style, loser removed and winner rests next round, three trophies to win, refill hand to five at start of round, challenged side starts next round. Deck tutorial requires at least ten cards and permits one of each B.B./Place and up to three identical Items. Separate DECK_BUILDER_MORE_THAN_30 and DECK_BUILDER_NO_BB_CARD strings indicate a maximum of 30 and at least one B.B.; half B.B.s is advisory. See [development reference](development.md). No relative rank cap, spinner distribution, tie resolution, fatigue edge cases, actual multiplayer/AI behavior established by these strings. Compare to physical manual before interpreting differences.

548 English strings, including many announcements and prompts for mechanics not found in active definitions (trophy theft, face-down play, phase skipping, recursion, Place overrides). This is tantalizing evidence of a wider intended vocabulary, not proof of working implementations or removed features. 30 B.B.s have Place-conditioned boosts despite disabled Places. Investigate whether older/newer game data or gameplay footage exists.

## Structured effect vocabulary

B.B. special shapes partition 200 records: 137 boost-only, 54 effect-only, 4 condition+groove, 5 condition+style. The 54 immediate effect records use only two IDs: discard_from_hand (30), draw_card (24). 78 Items have boosts; 34 have special.club_id. Targets observed across boost entries: clubs (51), exclude (80), position (29). Conditions observed across boosts and top-level special: dancefloor_bb 22, dancefloor_place 30, dancefloor_club 20, bb 16, club 23 (counts are occurrences, not necessarily cards). Club selector [0] exists; do not assign a meaning without runtime evidence. Conditions and target scope need verification from engine or footage. Do not assume original effect engine recovered. Useful vocabulary for independently implementing tabletop rules, which require substantially richer timing and actions.

## Platform and economy

Web manifest declares standalone display; service worker implements cache lookup with network fallback, no observed precache list. This supports installable-web-app interpretation, not proof of absence of native apps. Game-host index captured Feb 2023 is a no-direct-access placeholder, not the full client.

January website app strings reference match rewards in B.B. Bling, purchases of packs/cards/art, bundle labels of 1,000/2,500/5,000/10,000, marketplace listing deposits returned when cards are removed or unsold, child purchase requests and reminder nudges to managed adult profiles. Duplicate combination text suggests card fusion but exact mechanics not verified. UI copy is evidence of intended interfaces, not actual prices, enforcement or availability.

May terms distinguish nontransferable/nonrefundable virtual money purchased with real money or redeemed codes from digital assets under separate terms, naming Forte Labs and Provenance Technologies Inc. (PTI). Under-18 agreement with parent/guardian described. Asset payments generally final subject to law, restrictions on transfer and exchange, no guaranteed value. No specific pack odds, actual cash prices, verified blockchain contracts or functioning payment flow recovered. Avoid conflating virtual money with token ownership or asserting legal conclusions.

## Next investigations

1. Inspect the recovered instruction PDFs locally and compare editions/revisions with printed manual.
2. Extract source-referenced structured digital records locally (not a tabletop import), and compare same IDs field by field without treating digital data as printed evidence.
3. Index UI strings for progression, shop, marketplace, parent permissions and redemption; compare January/February/December bundles for changes.
4. Find actual game client bundles beyond the JSON, identify launch URL from captured pages/scripts and timecode footage. Do not call old live APIs, execute archived JS or use recovered credentials.
5. Keep raw third-party payloads private and permission-aware; do not redistribute without authorization. No gameplay or economic simulation results yet.


---

## Actual game client

- 05:47 (347s): beta Dance Off loading screen with progress bar in tablet browser. Address bar visibly shows playlolsurprise.com, no path readable. Confirms browser-hosted experience, not exact client URL or whether native versions existed.
- 05:50: game menu Build Deck, Play Game, Play Daily Challenge. Daily Challenger Pharaoh Babe, Today's Reward 50. Home, sound and help buttons. Venue with checkerboard stage, upright cards and spectators in background.
- 05:53–06:08: deck-builder header Your Deck: 25 / 30 Slots Filled (min 10), then 26, 27, 28, 30. Selected deck horizontally scrolls across top; type tabs left (BB, Items, Place icon); club strip horizontally scrolls above available collection. Available card has plus, selected card greyed with minus. Five vertically stacked rank dots on card faces, bottom yellow on observed tier-one cards. No Surprise tab visible. This establishes the limits and interface actually displayed, supplementing configuration strings.
- 06:09: loading transition.
- 06:10–06:13: edit cuts into Dance Off phase, with two visible BBs per side, hand cards along bottom, trophy counters (0–0), active player glow, selected cards pink outlined, Confirm button, instruction to select one BB each side. Spice detail popup: 9 Style, 3 Groove, +2 Groove if Sugar on Dance Floor. No complete Call/Dress Up sequences visible.
- 06:14–06:15: cards fly/rotate upright over stage; viewpoint shifts from overhead to low front view. Spectator rows, stage speakers, coloured spotlights; geometry/perspective strongly suggest a 3D or 2.5D presentation, engine unverified.
- 06:16–06:17: Cadet (0 Groove, 11 printed Style on card) vs Spice (9 Style); animated Audience Groove number reel with Stop button. At 06:16.6–.8 it settles at 5; You Lost, opponent gains first trophy. Exact fixture: 0 + 5 < 9.
- 06:20–06:23: edit skips intervening play; later 2–2 trophy state, Splatters vs Spice. Do not infer how Spice returned to eligible state or intermediate turns from edited sequence.
- 06:24–06:26: Splatters 3 Groove, Spice 9 Style. Spinner shows 8 while still spinning and Stop visible, then settles at 7, Groove display changes to 10, player third trophy. Exact fixture: 3 + 7 > 9. No tie shown.
- 06:29: trophy celebration popup; 06:32: match victory with three player trophies and two opponent trophies. 06:38: daily challenge menu again with Pharaoh Babe and 50 reward indicated. Transcript narrates receiving 50; no separate credited balance observed in this gameplay sequence. Daily challenge identity now corroborated, but repeatability, payout conditions, RNG and opponent implementation remain unknown.

## Presentation and simulator implications

- D1–D4: 10–30 digital deck confirmed onscreen. Printed championship remains separate. Top deck strip, type/club filters, plus/minus, dim unavailable cards are practical UI reference.
- V4/G7: existing portable Godot card object is a natural fit for the original's rotating upright cards. Keep authoritative board state independent of cinematic camera, stage, spectators, spotlights and score overlays. A single arena can serve overhead board and challenge presentation. Card tier indicator belongs to historical digital presentation, not printed Rank.
- G4: implement these two observed numeric fixtures in the eventual historical digital rules profile, alongside printed manual fixtures. Distinguish sampled spinner outcomes from distribution, button timing, or skill dependence. Observed 2, 5, 6, 7, 8 while spinning does not establish minimum/maximum.
- P3/B: confirmed daily challenger menu and 50 displayed reward. Do not clone monetization. No evidence for full daily opponent roster, timer, repeat rewards or AI.


See [visual evidence](visual-evidence.md) for screen anchors and [economy](economy.md) for commercial features. The Spice discrepancy is unresolved: video 9 Style / 3 Groove versus January tier-one 9 / 2. Digital defender victory visibly awards a trophy; printed defender victory does not under the challenger-only award rule. See [rules fixtures](evidence/rules-fixtures.json).
