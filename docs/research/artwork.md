# Artwork and client-presentation evidence

The recovered January database provides edition-local asset keys for 300 definitions, but the original CDN recovery contains only nine identified individual card artworks at two sizes. [Asset crosswalk](evidence/asset-crosswalk.json) joins the path IDs to digital definitions, retaining original URLs, SHA-256 values and private relative paths. No image binaries in Git.

| ID | Digital name | Asset key |
|---|---|---|
| 1-044 | Cosmic Queen | 1_044_CosmicQueen |
| 1-093 | Hops | 1_093_Hops |
| 1-175 | Dancebot | 1_175_Dancebot |
| 1-195 | Tinz | 1_195_Tinz |
| 1-197 | Captain B.B. | 1_197_CaptainBB |
| 1-337 | STEM Labcoat | 1_337_STEMLabcoat |
| 1-349 | Chilly Snowball | 1_349_ChillySnowball |
| 1-356 | MC Swag's Boom Box | 1_356_MCSwagsBoomBox |
| 1-362 | Princess Crown | 1_362_PrincessCrown |

This covers 5/200 B.B.s, 4/88 Items and 0/12 Places. It does not establish missing image paths exist or are recoverable. The consistent CDN naming convention is a candidate alias pattern only; do not hammer old hosts or claim complete coverage.

Other recovered groups: 5 rarity frames, 22 club particle images, 4 pack-animation assets (JSON, atlas, two PNGs), 2 pink card animation files, 5 marketing phone mockups and 12 gallery videos. Asset groups are provenance-indexed; these are website/portal files, not proof of client engine. The .atlas extension is consistent with common texture-atlas workflows and is not sufficient to identify Spine, Pixi, Unity, or the 3D runtime.

## Reconstruction constraints
Separate card data (name, edition, stats, effect, club), artwork layer, rarity border, icons, typography and animation. Use screenshot anchors in visual-evidence.md and private screen atlas to compare proportions and visibility. Original printed glitter is a physical finish, not the digital five-tier system. Keep rank/stat renderers profile-aware. The recovered nine digital assets can be reference matches, not automatic printed-card substitutions or license to redistribute. Placeholder or newly authored assets should be identified as such.

Next private inspection: validate image dimensions and alpha, compare thumbnail/full pairs, compare border and character art against actual video card faces, inspect atlas metadata without executing JS, and label the twelve gallery videos from visually confirmed titles. The assistant has not reopened the private image binaries in this pass, so all matches are ID/path-level only. No reconstruction of unseen artwork claimed.
