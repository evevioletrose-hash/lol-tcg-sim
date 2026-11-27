# Digital client hunt / implementation handoff

2026-11-27. Compared original main fed5c51 and active restoration 23ae46c with research f0d0c31. Restoration owns current development. This clean documentation-only branch may be integrated into main and restoration without bringing the old research branch's payload history. This is an evidence handoff, not a specification change.

## Immediate actionable findings

Primary source: January 4 2022 game data (private archive: `recovered/payloads/game.playlolsurprise.com/production/json/json__20220104043838.js`; see [source inventory](evidence/original-objects.json)), digest RM43E7CVBGHRIQHDKCHTS67Y5ZOYKXJY. Parsed JSON_DATA without executing JavaScript. English keys below locate original evidence.

| Roadmap | Evidence | Recommendation |
| --- | --- | --- |
| D1–D4 deck builder | DECK_TUTORIAL_1–11 and DECK_BUILDER_*: drag or plus/minus, club/type filters, minimum 10, maximum 30, at least one BB, half BB advisory, one of each BB/Place, three identical Items, owned copies check, save prompts | Use shared deck storage and pluggable validation. Preserve printed Championship 24–30 and rank difference <=2 separately. Digital 10–30 is a historical rules preset candidate, not a change to tabletop. No digital rank-difference rule established. |
| P3/B2 | TITLE_GUEST_DECK, TITLE_PLAY_CHALLENGE, CHALLENGE_COMPLETE_REWARD, CHALLENGE_TOMORROWS_CHALLENGER indicate guest deck and daily challenge/reward UI vocabulary | Local loaner deck and seedable challenges are possible design experiments. No confirmed rotation, rewards or AI rules. Keep rewards separate from definition and ownership. |
| V1/V4 | 9 distinct character/item art identities at two sizes in archive; five phone mockups; digital card rarity frames 1–5; particle emitters active_player, audience_groove_spinning, audience_groove_result, phase_bbs, round_win, game_win | Use as reference for card inspection, board feedback and optional spectacle; only explicit reviewed artwork mappings, no bare ID matching. Do not copy third-party assets into public game branch. |
| B3 | animations/pack-opening/LOL_web_platform_card_purchase.atlas, .json, .png and second texture | Inspect the animation as a visual reference for opening packs; not evidence of pack contents or odds. |
| G1–G4 | GAME_ONBOARDING_1–36, 54; HOWTOPLAY_1–14; GAMEPLAY_NO_BB_CARD_1/2 | Alternate placement and dress-up, both-pass transition, click/tap card inspect, choose slot/attacker/defender, audience spinner, strict Groove + Audience > Style, winning BB rests, losing BB removed, challenged side begins next round, three trophies. Refill to five is digital, not tabletop draw-five. No-BB prompts suggest replacement draw but exact procedure unknown. |
| G5 | Structured boost/condition/target fields; only draw_card and discard_from_hand immediate digital BB effect IDs. Richer dormant ANNOUNCE_EFFECT_* and EFFECT_PROMPT_* strings | Use vocabulary to inform independent primitives and typed rules events, not a direct tabletop import. Conditions and selectors need interpreted semantics. |
| A3 | 64 incomplete tabletop slots have digital counterparts; 155 same-type numeric physical BB pairs match tier-1 digital stats; 1-400 type collision | Generate review candidates only. Never auto-fill printed rank/effect/phase from digital source. Art and names need explicit confirmation. |

Additional configuration evidence: tutorial establishes >=10; separate deck-builder validation strings establish <=30 and at least one BB. Daily challenge menu and a completed challenge are now visible in the footage; guest deck functionality remains unverified. All 12 Place effects remain disabled in the dated data. No Surprise array. UI strings alone do not establish runtime behavior.

## Client hunt

Verified config keys api-url (playlolsurprise.com) and back-button-url (/dashboard). The February 26 2022 /login HTML explicitly loads game.playlolsurprise.com/production/json/json.js from a script tag. This explains how the game database could be archived without a game executable. Static checks of the three recovered app.js versions and original homepage did not expose a game host or /production/ launch reference. The root game host capture is a placeholder; no client bundle or native package identifier has been found.

Highest-priority next sources:
1. Public historical scan records, not live scans: URLScan domain search https://urlscan.io/search/#domain:playlolsurprise.com and https://urlscan.io/search/#domain:game.playlolsurprise.com . Look for recorded page requests, original launch URL, JS bundles, asset manifests. No positive hit established.
2. Archived developer site ioconic.io, public project portfolios, and former project staff. Ask about title of game, studio/contractor, client engine, public build or footage, original asset pipeline, and permission to preserve. No contact sent.
3. Video leads: https://www.youtube.com/watch?v=hQArOflJhUo (Couch Sisters, Jan 19 2022, description explicitly mentions combining duplicates); https://www.youtube.com/watch?v=sufUwxPl9u8 (Fidgets & Toys Jan 4 2022); https://www.youtube.com/watch?v=zN6G_erFaHA (Ri Happy/Copag Jan 15 2022). Prior lead Elena and Clara https://www.youtube.com/watch?v=tFEm8XawekI . All four sources have since been inspected; Elena and Clara shows actual digital gameplay. See [visual evidence](visual-evidence.md).
4. Ioconic/MGA launch notice https://licensinginternational.org/news/ioconic-partners-with-mga-entertainment-to-deliver-an-nft-and-digital-collectibles-ecosystem-for-the-25bn-toy-brand-l-o-l-surprise/ says iOS/Android functionality planned for Dec 2021, not native apps confirmed. Search app-store histories once package/bundle identity is known. No random APK installation.
5. Revisit the 33 plausible missing asset references only when a concrete archived path or alias is available. Existing Wayback/CC domain inventories nearly exhausted. Do not probe private endpoints, log in, or execute unknown archive scripts.

External secondary sources: https://www.prnewswire.com/news-releases/mga-entertainment-debuts-all-new-lol-surprise-trading-cards-and-accompanying-nft-301401106.html (physical product counts, public digital platform claims); https://www.toywiz.com/lol-surprise-dance-off-trading-card-game/ (retailer rarity counts not pack odds; marketing wording ambiguous). Original card scans, rulebooks and player evidence outrank retail marketing for tabletop rules.

No game code changes in this reference. No new client binaries recovered. Next implementation-facing checkpoint: D1–D4 when ready, then B1–B3 and G1–G5. Keep original and interpreted rule profiles separate.
