# Rules, effects and simulation research

## Primary references
- [Starter set 578215 rulebook PDF](https://manuals.plus/l-o-l-surprise/578215-dance-off-trading-cards-starter-set-manual.pdf), [HTML transcription](https://manuals.plus/l-o-l-surprise/578215-dance-off-trading-cards-starter-set-manual), [alternate mirror](https://device.report/manual/6273477). Preserve a local copy where authorized; no PDF binary is added by this fold. The restoration branch includes a rulebook PDF; the three recovered original website editions remain private.
- [Owner collection transcription](../../cardlist.txt): approximately complete physical collection, remaining unopened packs. Entries cover numbers 1-001 to 1-400 with blanks and partial/uncertain values. Preserve verbatim transcription separately from normalized data and interpreted effects. Compare to [TCDB checklist](https://www.tcdb.com/Checklist.cfm/sid/375915/2021-LOL-Surprise-Dance-Off).
- [Initial game source](../../src/game.gd), [state](../../src/game_state.gd), [zones](../../src/zones/zone.gd), [selection](../../src/selection_prompt_ui.gd), [first effect](../../src/cards/play_effects/1-001.gd). Architecture review only; no runtime testing.

## Rules observations to formalize
The rulebook covers a 24–30-card deck, rank-based balancing relative to opponents rather than a single universal budget, Call Your B.B.s / Dress Up / Dance Off phases, challenge selection, Audience Groove randomness, trophies and alternative play formats. The attacker compares total Groove to defender total Style. Prior discussion identified resting surviving dancers and trophy awards favoring successful challenges. Check exact timing, tie outcomes, replenishment, phase transitions, initiative, hand size, deck restrictions, target choice, multi-player differences, and rest/discard rules against the manual before implementing. Do not mistake chat summaries for normative rules.

## Candidate archetypes (not tested)

| Archetype | Specific collection evidence and proposed interactions |
|---|---|
| Glitterati tribal | 1-137 King Bee recruits 1-133 Queen Bee from hand/deck/discard; Queen Bee scales with other Glitterati on the entire floor; 1-135 Piano King buffs other Glitterati; 1-136 Purple Queen draws based on allies; 1-323 Loose Glitter scales with team; 1-183 The Queen boosts draws. Mirror-match effects may scale off opponents. |
| Chill Out control | 1-118 Snow Bunny draws on skipped phases; 1-020 Brr B.B. skips Dance Off; 1-021 Posh ends Call phase; 1-023 Babe in the Woods skips Dress Up; 1-223 Coffee Break, 1-226 Jukebox Frenzie, 1-242 Freeze!, 1-255 B.B.s Day Off. Verify whether ending a phase counts as skipping, and whether skipped phases trigger separately. |
| Cosplay toolbox | 1-024 Fanime adds a club, 1-120 Fan Boy adds two, 1-174 Bon Bon counts as all clubs. Items 1-301/302/308 etc. grant club membership. 1-172 Black Belt scales removal with Athletic allies; 1-295 Private Party removes nonmembers of chosen club. Club Break Time cards (1-201 onward) and 1-250 Club Ban create counterplay. |
| Swim hidden information | 1-198 Scuba Babe, 1-260 Pool Party, 1-162 Sailor Q.T., 1-163 Treasure, 1-164 Precious, 1-197 Captain B.B., 1-372 Swimmin' Floaty. Reveal counterplay: 1-001 Pop Heart, 1-110 Drip Drop, 1-236 Lifeguard on Duty, 1-375 Surf Board. 1-238 Peekaboo and 1-275 X-Ray Machine probe other hidden information. Verify face-down targeting and whether effects function while hidden. |
| Glam equipment | 1-124 Her Majesty capacity scales with team; 1-127 Cadet grants adjacent extra slot; 1-038 Miss Punk draws on equip; 1-128 Tough Guy recovers items when discarded; 1-179 Flower Child holds five items and resists Surprises; 1-387 Flower Crown retrieves items; 1-334 Sparkly Style grants capacity. 1-285 Spring Cleaning and 1-306 Bunny Slippers punish investments. |
| Venue control | 1-397 Concert Stage swaps Style/Groove; 1-389 Diva's Beauty Salon changes comparison; 1-167 Pharaoh Babe locks Places. Consider asymmetric deck composition and locking a favorable Place. 1-394 Snowy Ski Resort restricts dancing to equipped B.B.s. |
| Positional support | 1-007 Touchdown, 1-112 Sk8er Grrrl rearranges a floor, 1-152 Valley B.B., 1-154 Rhymes, 1-338 DJ's Stereo, 1-356 MC Swag's Boom Box, 1-358 Pharaoh Babe's Dress. Consider whether to preserve support B.B.s instead of challenging with them. |
| Trophy manipulation and recursion | 1-161 Troublemaker temporarily steals trophy; 1-165 Pranksta removes one; 1-166 Unicorn helps when behind; 1-195 Tinz gains one when behind; 1-196 Bhaddie resets all; 1-193 Countess resurrects up to three B.B.s; 1-385 Witchay Babay's Hat recovers discarded Surprises. Explore loops, resets and alternate paths to victory. |

Other notable effects: 1-002 Shapes copies base stats; 1-132 Infinity Queen copies opponent's starting stats during a dance; 1-215 Spoilsport counters a Surprise except another Spoilsport; 1-181 Harlequin Girl blanks other B.B. Special Moves; 1-289 Silent Disco disables Items and Special Moves; 1-241 Flipped replaces combat with token flip; 1-280 New Friend recruits an opposing dancer for combat; 1-282 Pair Up challenges two; 1-283 Record Scratch forces no winner; 1-299 The Drop forces mass dance-offs. Need explicit timing and precedence.

These are readings of collection transcriptions, not verified official rulings, guaranteed legal combos or claims of balance. Card numbers and names should be checked against scans (e.g. transcription spellings, incomplete data, card 1-400 Pop Heart variant).

## Bot research proposal
1. Build an authoritative deterministic rules state independent of scene nodes, with seeded chance events, legal action enumeration, immutable or efficiently cloneable snapshots, action/decision logs, and observation views that conceal private information. Let human UI and bots consume the same legal actions.
2. Baseline **B.B.**: uniformly or explicitly weighted random legal decisions. Define action sampling and avoid infinite pass/skip cycles.
3. **Diva**: heuristic strategy with card advantage, trophy progress, expected combat outcomes, positioning, support value, equipment investment and response timing.
4. **Queen**: search/simulation with sampled hidden information; no access to actual opponent hand or deck ordering unless rules permit. Compare information-set search and simpler rollouts; avoid assuming full-information minimax is fair.
5. Start with a verified small card pool, grow archetype packages, and test each effect and interaction. Build deck candidates at legal relative rank budgets and compare across matchups. Keep original rules distinct from optional adjudications/variants.
6. Measure win rates with confidence intervals, seed reproducibility, seat/initiative advantage, turn counts, stall/lock frequencies, trophy changes, card usage, matchup matrix, decision time and effect interactions. Mirror matches and side swaps control first-player effects. Compare heuristic and search agents against random baseline, and do ablations for synergy/positioning/hidden info.

The question is whether deliberate decisions reliably outperform chance, what metagame emerges, and which strategies are oppressive or broken. Preserve the original before changing anything. No simulations or results yet.


## Edition boundary
Use the printed manual as primary rules evidence. Printed Championship deck 24–30, relative Rank difference at most 2, draw five additional cards per round, challenger-only trophy award, and tie discards both combatants and their attachments without trophy. Historical digital 10–30, refill to five, defender trophy observed; digital ties unknown. See [digital game](digital-game.md) and [fixtures](evidence/rules-fixtures.json).