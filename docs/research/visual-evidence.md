# Game dossier: screen atlas and implementation evidence

2026-11-27. Private local dossier contains 41 screen states, 19 native-resolution panel crops, 12 edition comparisons, 19 observed/edited screen transitions, five fixture records, and nine unresolved topics. The original 888 screenshot files remain intact; the overlay links relative paths to them. No media is published here.

## Evidence boundary

Source video: Elena and Clara, https://www.youtube.com/watch?v=tFEm8XawekI, 720p supplied copy, SHA-256 4c4dbedb54171b5a558ae53bdb0cae303487ca046362ca61ee00ad97be74421f. January configuration: game.playlolsurprise.com/production/json/json.js, CDX digest RM43E7CVBGHRIQHDKCHTS67Y5ZOYKXJY, captured 20220104043838. Printed evidence: user-supplied 578215 starter set manual (Manuals+ reproduction, PDF p.9–10, sections 10–12). Screenshots are dated video evidence, not proof of exact build identity. Asset filenames below are functional candidates from recovered manifest, not pixel-verified client matches.

## Critical new discrepancies

- Digital defender trophy: 06:16.6 reel settles at 5; player Cadet 0 Groove vs Spice 9 Style. At 06:17 You Lost modal and first opponent trophy are visible. Printed manual §10 awards a trophy to a successful challenger; its losing-challenger case describes discard/rest but no trophy. Keep separate policies. Printed tie discards both and attachments without trophy; digital tie unknown.
- Spice (digital:1-142) at 06:11 card display visibly reads 9 Style / 3 Groove, with bottom rank dot lit and conditional Sugar effect. January JSON tier 1 is 9 Style / 2 Groove, tier 2 is 10/2, tier 3 11/3. Preserve both observations; modifier, build difference or another explanation remains unresolved. Do not import video numbers into the canonical catalogue.
- Printed round cleanup draws five additional cards (manual §11). Digital tutorial refill to five (GAME_ONBOARDING_35, HOWTOPLAY_5).
- Printed Championship deck 24–30 and relative total Rank difference <=2; original digital deck display 10–30. Printed Surprise and Place timing separate; digital data lacks Surprise array and disables all 12 Place specials. Do not silently equate printed Rank to digital tiers.

## Atlas: anchor map

Times in original video; private full screenshots use screenshots/01-elena-clara/MM-SS-mmm_fNNNNNN.jpg (25 fps). The overlay indexes exact frame numbers and SHA-256.

| Screen group | Anchors | Relevant recovered evidence | Restoration |
| --- | --- | --- | --- |
| Portal | 00:36, 00:44, 02:50, 02:46 | dashboard/background, play and collection icons, coin art | P/B |
| Shop/reveal | 02:18, 02:22, 03:46–04:14 | pack-opening JSON/atlas/PNG and second texture, card-back.png, pink card animation | B1–B3 |
| Collection/listing | 04:24, 04:36, 04:56–04:58 | card-collection-banner.png, club particles, marketplace-bg-tile.png | A/P, marketplace deferred |
| Art shop/gallery | 05:16, 05:30–05:34 | art-shop-banner.png, art-gallery-bg-squares.png, twelve recovered NFT videos | Reference, no ownership claim |
| Launch/menu | 05:47–05:48, 06:38 | lol-beta-logo.png; TITLE_PLAY_GAME, TITLE_PLAY_CHALLENGE, CHALLENGE_DAILY_CHALLENGER | Later challenge menu |
| Deck builder | 05:53, 05:54, 05:56, 06:08 | card-border-rarity-1..5, club particles; DECK_TUTORIAL_*, DECK_BUILDER_* | D1–D4 |
| Board selection | 06:10, 06:11, 06:13 | ACTION_CONFIRM_DANCEOFF_SELECTION, GAME_ONBOARDING_24–31; promo board images | G1–G4, G7 |
| Arena and reel | 06:14, 06:16, 06:16.6, 06:22, 06:25–26 | TITLE_AUDIENCE_GROOVE, ACTION_STOP_AUDIENCE_GROOVE; emitters active_player, audience_groove_spinning, audience_groove_result | V4/G7, G4 |
| Results | 06:17, 06:29, 06:34 | TITLE_ROUND_LOST, TITLE_ROUND_WON, TITLE_WIN; round_win/game_win emitters | G4/G7 |

## Proposed application boundaries, not recovered architecture

Independent catalogue, profiles/inventories, deck validator by rule profile, product/acquisition service, authoritative match reducer, presentation/camera controller, optional themed challenge scheduler. Rules produce typed domain events; scene animation consumes them. Inject an audience-result provider so test outcomes do not depend on graphics timing. Use explicit historical digital versus printed edition/ruleset identities. Keep any local reward system free, no paid economy. Existing restoration roadmap D1–D4, B1–B3, G1–G5, V4/G7 remains applicable; no implementation edits.

## Acceptance and unresolved questions

[Fixtures](evidence/rules-fixtures.json) are evidence records, not tests executed in Godot. Still missing: original client bundle/engine/launch path; complete Call/Dress Up footage; exact board capacity and attachment limits for digital; digital ties, exhaustion and opponent implementation; spinner distribution and timing; Spice discrepancy; upgrade rules/pack odds/reward repeatability; media-to-title matches; four unresolved CC collections and 33 asset leads. Asset matching needs actual local visual comparisons, not filename inference. No outreach sent. Private media remains outside Git. 


---

# Visual evidence: four contemporary videos

Inspected user-provided local copies on 2026-11-27 using timestamped video frames (2-second interval for the short, 8 seconds for longer videos, additional selected frames). No audio transcription or continuous playback. Timestamps refer to supplied files. No raw video or QR codes stored in Git.

## Couch Sisters: Come Play LOL Surprise Dance-Off with us!!!
https://www.youtube.com/watch?v=hQArOflJhUo
60.06s, 1080x1920. Sponsored short. Actual beta web portal screen recording, rather than a digital match.

| Time | Observed |
| --- | --- |
| 00:17–18 | QR-code onboarding popup, START or login. |
| 00:19–20 | Generated username, password and confirmation form. |
| 00:21–22 | Scanned card grants 20 B.B. Bling; balance 520. |
| 00:23–24 | Another scanned card grants 30; balance 550. |
| 00:25 | Signup reward screen explicitly states 500 B.B. Bling. |
| 00:26 | Dashboard: Play Game, My Card Collection, My Art Gallery, Card Shop, B.B. Bling Shop, Art Shop, Marketplace. |
| 00:27–30 | Guided onboarding directs player to Card Shop and Starter Pack. Starter Pack 10 cards for 500; Basic Pack 8 cards for 800. |
| 00:31 | Balance 50, Your Cards screen, ten card art thumbnails, tap a card to reveal. |
| 00:32 | Returns to dashboard, balance 50. |

This is observational evidence for historical new-account and product prices, not verified odds, fixed starter composition, actual cash exchange rate, or replay of the game client. The clip cuts around the purchase; no direct launch URL, game runtime, fusion operation or actual match observed. The 10-card product size matches the digital minimum deck size; the 500 signup grant covers its price.

Implementation: B1–B3 should model one-time starter eligibility separately from ordinary boosters if desired (one-time restriction not established here); currency values and product counts can be a historical reference preset, not a reason to reproduce paid economy. Preserve pack reveal and acquisition separation. The ten thumbnails lack enough printed metadata to determine authoritative card IDs or rank; do not infer pull odds. Dashboard navigation is a useful UI reference.

## Fidgets & Toys: LOL Surprise Dance Off Trading cards game
https://www.youtube.com/watch?v=sufUwxPl9u8
578.04s, 640x360. Physical unboxing, two starter boxes shown at outset. 00:16 packaging states 24 trading cards and 9 tokens. 00:48–01:28 instruction/checklist and mat. 01:36–07:44 multiple card reveals, foil patterns and token sheets; 07:52–08:08 checklist closeups; then sorting/display. Useful physical product/presentation/transcription leads, but 360p and foil glare limit card text/number recovery. No digital interface observed in sampled frames. No statistically valid pack odds from this sample.

## Ri Happy / Copag: Lots of dancing and fun with L.O.L Surprise Dance Off from Copag HappyTube
https://www.youtube.com/watch?v=zN6G_erFaHA
630.96s, 640x360. Portuguese subtitles, product unboxing and actual tabletop demonstration.

- 00:24–01:36 booster opening; 01:52 starter contents laid out (mat and five packs visible).
- 02:08–04:40 further pack reveals; different localized print and physical foil treatments.
- 04:48–05:12 physical mat and trophy/Groove token setup.
- 05:21–05:37 deck rank calculation discussion (subtitle at 05:37 refers to one deck rank total of 32).
- 05:53–06:56 Phase 1 Call Your B.B.s; 06:21 subtitle indicates drawing another until a B.B. is obtained.
- 07:01–08:30 Phase 2 Dress Up; attached item placement and a Surprise card phase restriction discussed at 08:30.
- 08:40–10:10 Phase 3 Dance Off; Hops chosen at 08:54, Groove values discussed at 09:20; 09:28 on-screen instruction adds B.B. Groove, Item and audience score. 09:38 loser discard and winner rest described, 09:49 trophy token awarded; 10:00 subtitle refers to opponent having no B.B.s left able to battle. Treat the latter as a lead requiring full context and printed rules comparison, not an authoritative new win rule. 10:10 repeating phases.
- No digital game screen observed in sampled frames.

Implementation: G1–G4 visual reference for board layout, attachments, round procedure and token handling; G5 for phase-specific Surprise timing. Compare localized tutorial with US championship rules before encoding any differences.

## Elena and Clara: I won an L.O.L Surprise! NFT's!

**Update:** the 720p video was subsequently obtained and inspected. See [digital game](digital-game.md) and [economy](economy.md) for exact gameplay fixtures, full currency menu, marketplace limits and correction to the NFT edition-number interpretation. The following remains the earlier transcript-only evidence.
https://www.youtube.com/watch?v=tFEm8XawekI
User-supplied timestamped automatic transcript, approximately seven minutes; video unavailable for visual inspection. Explicitly sponsored by MGA. Evidence of narrated actions, not verified screen contents or independently tested behavior.

| Time | Reported observation |
| --- | --- |
| 00:36–00:44 | Parental permission, account creation, 500 B.B. Bling initial grant. |
| 00:52 | Physical pack contains eight cards and three tokens. |
| 01:08 | Merbaby reportedly numbered one of 130 worldwide. Exact card ID/serial evidence needs images. |
| 02:12 | Starter pack costs 500. |
| 02:20–02:38 | Product QR leads to platform; individual card QR yields card/place/item/currency or NFT. |
| 02:46 | Post-scanning balance 780. Narration says insufficient for another starter pack; later buys Basic Pack at 800. Do not infer starter repeat eligibility or altered price. |
| 02:54–03:03 | 1,000 Bling for $2.99; 2,500 for $6.99. Currency and regional pricing unconfirmed. |
| 03:43 | Basic Pack 800 Bling. |
| 03:52–04:17 | Two duplicates can reportedly make a rarer card; no observed fusion or confirmed consumption, rank caps or result identity. |
| 04:32–04:39 | Snow Bunny rarity 1, popular; 2 rare; 3 ultra rare. |
| 04:49–04:57 | Duplicate Jelly Jam listed for sale with seller-selected price. No price or completed transaction established. |
| 05:07–05:32 | Art shop, Makeover Madness purchase/add to gallery; serial 4998 of 5000 reported. One artwork edition size, not total NFT supply or token/contract proof. |
| 05:40–06:10 | Actual digital game session narrated, deck construction first. No confirmed deck composition or opponent type. |
| 06:10–06:27 | B.B. selection, stop prompt, loss then last-round win and challenge victory. Consistent with recovered spinner and challenge strings; no confirmed exact scores or mode. |
| 06:36 | 50 Bling awarded for challenge victory. |

Cross-source findings: signup grant 500, starter price 500, basic price 800 agree with Couch Sisters screen evidence. Recovered game strings independently support challenge reward UI, deck selection and spinner. Transcript adds first narrated digital gameplay and actual reported challenge payout. It does not establish a universal reward schedule, proof of a daily challenge specifically, AI vs human, or client launch URL. The starter and basic prices imply 16 wins at this observed payout for one basic pack if repeatable; this is arithmetic, not evidence repeat farming was available. No real-money implementation recommended.

Restoration implications: seedable starter/booster product definitions, separate currency and acquisition ledger, explicit challenge reward events, duplicate management, all optional historical-inspired features rather than changes to printed rules. Keep any simulated economy local and free. Marketplace can remain deferred.

## Evidence limits
All four source videos were inspected visually via selected frames, not audio or exhaustive frame-by-frame viewing. The earlier transcript-only account is retained above as a distinct evidence layer. No client launch URL or executable identified. User reports URLScan historical access is paywalled beyond one year; no need to pay at present. The subsequent 720p inspection confirms actual digital gameplay; see digital-game.md. Exact launch path remains unknown. Keep evidence local; do not commit third-party footage.
