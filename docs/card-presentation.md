# Card presentation / Operation Glitter

## V1: Artwork identity and fallback

Artwork is presentation data, not a printed card field or profile property. src/cards/card_artwork.gd maps explicit edition-qualified IDs to existing imported Texture2D resource paths. Currently the single binding is tabletop:1-001 -> res://assets/card arts/1-001.jpg. The rare tabletop 1-400 and historical digital 1-001 are not aliases. No research archive assets copied, no new art generated, no assumed match by display name. Existing references and 3D assets remain untouched.

Shared Card/img/Artwork contains an aspect-preserving TextureRect and a neutral text fallback, with separate apertures for existing B.B., Item and Surprise layout. Card.populate binds the texture every time (including draft preview); missing/unmapped art clears old texture and shows labeled fallback. Card.set_face hides artwork while face down. Unmapped differs from missing/unimported resource internally. No Place scene yet; incomplete definitions remain text-only. Current art is displayed as-is, not a claim of official source/authenticity or visual crop quality.

To add another verified asset, import it in Godot and add an explicit edition-qualified mapping; preserve sources separately in the archive. No implicit filename search. Runtime loads use ResourceLoader; when an export preset is introduced, include these dynamically referenced artwork assets (export all resources or explicit selections), and test exported builds. There is no export verification yet.

Run -- --card-artwork-test after editor import. Exercises existing supported typed scenes, known asset, wrong edition, missing path, fallbacks, visibility, face-down behavior and reuse of one card. Expected at the original catalogue: 1 available, 305 placeholders, 5 unsupported Place records. Real rendered composition, image suitability and layout remain for manual inspection. V2 will refine the first B.B. design and typography; V3 extends the design to other types, V4 3D binding, V5 finishes/animation.

### Local acceptance / artwork workflow deferred

At 23055ac the full regression and import passed, including LOL_ARTWORK available=1 placeholders=305 unsupported=5 failures=0. Owner screenshot shows the reference photograph of an entire physical Pop Heart card nested inside the card aperture. This is not a final art asset; owner explicitly deferred art workflow decisions. Retain this as a temporary test binding and use placeholders as needed in further layout work. No assumed extraction/cropping, replacement imagery or source claims. Exported build packaging still untested.
