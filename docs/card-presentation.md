# Card presentation / Operation Glitter

## V1: Artwork identity and fallback

Artwork is presentation data, not a printed card field or profile property. src/cards/card_artwork.gd maps explicit edition-qualified IDs to existing imported Texture2D resource paths. Currently the single binding is tabletop:1-001 -> res://assets/card arts/1-001.jpg. The rare tabletop 1-400 and historical digital 1-001 are not aliases. No research archive assets copied, no new art generated, no assumed match by display name. Existing references and 3D assets remain untouched.

Shared Card/img/Artwork contains an aspect-preserving TextureRect and a neutral text fallback, with separate apertures for existing B.B., Item and Surprise layout. Card.populate binds the texture every time (including draft preview); missing/unmapped art clears old texture and shows labeled fallback. Card.set_face hides artwork while face down. Unmapped differs from missing/unimported resource internally. No Place scene yet; incomplete definitions remain text-only. Current art is displayed as-is, not a claim of official source/authenticity or visual crop quality.

To add another verified asset, import it in Godot and add an explicit edition-qualified mapping; preserve sources separately in the archive. No implicit filename search. Runtime loads use ResourceLoader; when an export preset is introduced, include these dynamically referenced artwork assets (export all resources or explicit selections), and test exported builds. There is no export verification yet.

Run -- --card-artwork-test after editor import. Exercises existing supported typed scenes, known asset, wrong edition, missing path, fallbacks, visibility, face-down behavior and reuse of one card. Expected at the original catalogue: 1 available, 305 placeholders, 5 unsupported Place records. Real rendered composition, image suitability and layout remain for manual inspection. V2 will refine the first B.B. design and typography; V3 extends the design to other types, V4 3D binding, V5 finishes/animation.

### Local acceptance / artwork workflow deferred

At 23055ac the full regression and import passed, including LOL_ARTWORK available=1 placeholders=305 unsupported=5 failures=0. Owner screenshot shows the reference photograph of an entire physical Pop Heart card nested inside the card aperture. This is not a final art asset; owner explicitly deferred art workflow decisions. Retain this as a temporary test binding and use placeholders as needed in further layout work. No assumed extraction/cropping, replacement imagery or source claims. Exported build packaging still untested.

## V2: B.B. composition (core verified)

Keep existing 333 x 442 card footprint and gameplay node paths. New plum frame, high contrast footer with explicit Rank label, pink diamond Style and blue circular Groove badges, two-line name, club, reserved artwork aperture and cream power panel. Existing card back replaced by a shared original simulator design, not an official recreation. Workshop/Archivist flip control uses Card.set_face; front content and artwork hidden explicitly while face down, restored on flip. Item/Surprise inherit frame/footer/back only; layout redesign deferred to V3. Existing reference photo remains a temporary binding, no artwork workflow changes. Long names may elide after two lines; full names remain in workshop details; long power content retained in RichTextLabel and details (actual scroll/readability at small sizes needs review). No printed field or profile changes. -- --bb-presentation-test checks all typed B.B. fields, region bounds, header overlap, flip, long text fixture. Local render, viewport sizing and actual gameplay interactions not tested here.


### V2 local acceptance

At 3dcb612 all ten validation/regression commands exited 0, including LOL_BB_PRESENTATION cards=161 failures=0. Actual Pop Heart front/back screenshots approved by owner. Retain the composition as the baseline for V3. Actual small-window sizing, long-text GUI readability and gameplay interaction still need review; no claim that these are fully verified.

## V3: Card family (pending local acceptance)

Extract approved B.B. cream power panel to reusable power_panel.tscn without changing its portrait placement or field paths. Item and Surprise use the same panel/frame/footer, reserved artwork, mint Item badge and amber Surprise timing badge. Surprise preview shows actual printed phase text (blank explicitly not catalogued), not the legacy enum fallback; rules semantics unchanged. Place shares item name/effect binding and frame components, native 436 x 331 face with artwork left, power right and footer below. Portrait back rotated 90 degrees with Place rather than inventing a distinct identifying back. Workshop fits preview width uniformly, including live Archivist drafts. Legacy board Place spawning remains blocked pending gameplay rules. Artwork workflow unchanged. New --card-family-test covers all typed records and checks fields, orientation, width, overlap, flips and timing; smoke and artwork tests now require Place previews. Expected artwork counts 1 available, 310 placeholders, 0 unsupported at current catalogue. Actual rendering, text fit and small viewport review pending; no gameplay or profile changes.
