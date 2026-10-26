# Original village artwork — 26 October 2026

Two original ImageGen atlases, each 1536×1024 RGBA; three columns and two rows of 512×512. Sprite regions are assigned in `scripts/kingdom_renderer.gd`. No external game's art was extracted or bundled. Existing assets remain available for historical saves and wall/scaffold rendering.

- `village-atlas.png`: cottage, windmill farm, lumbermill, storage barn, townhall, blacksmith. Generated with the built-in ImageGen tool; transparency cleanup also used ImageGen. Source output `exec-d5af25f6-78cb-417a-b479-a0ffef9e9ed9.png`.
- `industry-atlas.png`: quarry, gold mine, furnace, barracks, watchtower, marketplace. Generated with built-in ImageGen. Source output `exec-f22a54b0-a0dd-4f9b-a1a2-b35f18e08b9f.png`.

Art direction supplied to the generator: original premium hand-painted isometric fantasy farming RPG assets, consistent three-quarter view and upper-left sunlight, creamy stone, honey oak, gold trim and blue/teal roofs. Six complete isolated buildings per atlas, transparent alpha, no humans, text or gridlines, ground near 85% of each cell. Materials, flowers, sacks, carts and warm hearths should remain readable at gameplay scale. No external images were supplied for the first generation or the second atlas. Village cleanup referenced only the first original generated atlas.

Original generated sources remain at `C:/Users/batua/.codex/generated_images/01a163ae-d724-7830-80ba-6b39304c80cc/`. Game consumes copied files at the paths above. PNGs were not edited by Python or other raster processing tools. Alpha was inspected read-only with System.Drawing.
