# Digital platform archaeology and monetization

## Original platform
The September 2021 [partnership announcement](https://licensinginternational.org/news/ioconic-partners-with-mga-entertainment-to-deliver-an-nft-and-digital-collectibles-ecosystem-for-the-25bn-toy-brand-l-o-l-surprise/) named www.playlolsurprise.com. [MGA's launch release](https://www.prnewswire.com/news-releases/mga-entertainment-debuts-all-new-lol-surprise-trading-cards-and-accompanying-nft-301401106.html) describes collecting, trading, purchasing digital characters and playing digital Dance Off there. Earlier browsing found the domain redirecting to the doll storefront. Exact shutdown date unknown.

| Artifact | Status |
|---|---|
| [Original domain](https://playlolsurprise.com/) | Redirect reported in earlier research. |
| [Wayback www](https://web.archive.org/web/*/https://www.playlolsurprise.com/) / [bare](https://web.archive.org/web/*/https://playlolsurprise.com/) | 438 capture rows indexed; 317 nonempty distinct digests verified locally, one empty digest inferred. |
| Android / iOS | Functionality announced for December 2021; native app distribution not established. No verified package ID, store ID or installer recovered. |
| [Elena and Clara sponsored demo](https://www.youtube.com/watch?v=tFEm8XawekI) | December 18, 2021; visual gameplay and economy evidence captured. |
| [Kohdok critique](https://www.youtube.com/watch?v=qV9WZgcS5Eg) | January 1, 2022; contemporary monetization criticism. Full video needs review. |
| Client source / data / backend | Configuration recovered; executable and backend missing. |
| Blockchain artifacts | Polygon association reported; contract addresses/token metadata not identified. |

## Monetization evidence
The physical booster launch price was $2.99 US, starter $9.99. The [starter manual](https://manuals.plus/l-o-l-surprise/578215-dance-off-trading-cards-starter-set-manual) describes card scanning and surprise rewards rather than guaranteeing a one-to-one digital copy of each scanned card (recheck precise wording). The press release describes purchases of platform currency and digital collectibles; the [December CoinDesk report](https://www.coindesk.com/business/2021/12/14/toy-brand-lol-surprise-launches-in-store-nft-collection) documents Polygon-backed NFT release. The earlier promotional search identified BB Bling as a reward/currency name; confirmed as platform currency in footage.

Working model: physical blind purchase -> unique QR redemption -> digital rewards (cards, currency and/or collectibles) -> digital gameplay/collection and marketplace. Specific reward examples, prices and parental purchase UI are now documented below; probabilities, repeatability, custody, actual enforcement and cash-out remain unknown. Ioconic claimed spending safeguards; no evidence yet on actual effectiveness. Child-directed randomized purchasing and currency layering are legitimate consumer-protection concerns, not a demonstrated legal finding of predation. Keep criticism tied to documented mechanics.

Quidd's March 2022 partnership and VeVe's July 2021 partnership are separate events, not proof of replacement or shutdown. See [history](history.md).

## Recovery protocol
1. Query Wayback calendar, CDX indexes (both hosts, http/https, wildcard paths) and alternative public web archives. Save capture timestamps, original URLs, response status and content hashes. A failed request is not evidence of absence.
2. Recover publicly archived HTML, sitemap, robots.txt, app manifests, linked JS/CSS, static JSON, images and CDN URLs. Record original sources and redirects. Look for PWA/service worker clues and data schema; do not assume an archived shell implies working backend.
3. Search app-store history, APK catalogues, reviews and press materials for package/bundle IDs; distinguish mobile web from native distribution. Only use legally accessible copies; inspect untrusted binaries offline and do not run unknown APKs on a personal device.
4. Timecode promotional and critical videos: UI screens, reward flows, QR redemption, pricing, rules, deckbuilding, match footage, currency amounts. Preserve links and original dates, not unauthorized copies.
5. Search public Polygon contract announcements and metadata by publisher/partner; verify contract provenance before attributing assets. Never redeem codes from card scans or expose unused QR codes, tokens, user data or credentials.
6. Ask former developers for public or authorized documentation, not proprietary source, private databases or bypasses. Track permission and licensing before redistributing recovered assets.

Open questions: was matchmaking live, were bots present, did any clients contain complete card data, what actually shipped versus announced, when was service withdrawn, were users notified, and what happened to redeemed collectibles?


## Economy and collection visual evidence

- 02:18–02:20: Starter Pack 10 cards, 500 Bling; Basic Pack 8 cards, 800. 02:21 starter reveal with zero balance. At 03:48 only Basic Pack is visible on shop screen, suggesting starter-only eligibility but not establishing rule.
- 03:00: full six currency bundles displayed with dollar sign (region/currency unconfirmed): 1,000 $2.99; 2,500 $6.99; 5,000 $12.99; 10,000 $20.99; 25,000 $49.99; 50,000 $89.99. Purchase request notice; account-manager permission instruction. Balance 780.
- 03:48–04:12: Basic Pack purchase confirmation, animated wrapper reveal, eight individually flippable cards and Skip. Actual pack contents visually 4 BBs, 3 Items, 1 Place, inferred from artwork; no odds or guaranteed composition established. Collection has greyed missing cards.
- 04:56–05:00: Jelly Jam marketplace listing, price 240 then 255, range 80–400 Bling. UI says unsold cards returned to collection within 2 days. No completed sale observed; no global pricing rule inferred.
- 05:16: art shop: Inside Scoop! 4/5, 50,000 Bling; Double Feature - Makeover Madness 4,999/5,000, 5,000 Bling; Yacht B.B. - B.B. Beach Party 500/500, 9,000 Bling. Counts are displayed availability-style fractions, not edition serials. 
- 05:31–05:38: purchased Double Feature - Makeover Madness explicitly labeled Edition #2; later fraction 4998/5000 displayed alongside Edition #2. Corrects transcript interpretation: #4998 not established as unique token serial. Gallery also displays BB Nation, Queen Bee - Feeling Extra, BB Party. No on-chain verification.


Additional observations: signup 500 Bling; Couch Sisters scanned rewards +20 and +30; starter 10 cards / 500; basic 8 / 800; daily challenge displayed reward 50. Narrated duplicate combination is not a confirmed universal two-for-one rule. One observed challenge cannot establish repeatable income. No on-chain contract established. See [visual evidence](visual-evidence.md).
