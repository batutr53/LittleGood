# Art direction

## Phase 2 identity

The current world uses a connected, softly textured surface with jade/mint terrain, sandy banks and layered floating cliffs. A shared atlas holds original painted creatures, snowy stone peaks, pines, palms, mossy flowers, cottages and a guildhall, along with the existing jade tree. Water glints and a falling outlet, vertex foliage sway, warm sky glow, rain and gift colors animate the world. Nunito UI text and Lora titles are paired with eleven original SVG icons and a compact six-gift dock. The illustrated discovery journal uses the actual species sprites. Both fonts retain their SIL Open Font License files. See PHASE2_REPORT.md and ASSET_INVENTORY.md for current assets and rendered screenshots; the following paragraphs describe the original phase-one foundation.

LittleGod is a cozy miniature diorama: jade forest, soft mint meadow, turquoise water, warm sandstone, slate mountains, pale snow, and smoky teal wetlands. The sky is deep blue with soft atmospheric glow. Cream typography and sage buttons keep the living island central.

Terrain uses a 2:1 isometric projection with layered earthen sides. Trees use a transparent original image-generated sprite prepared at 256 px; deterministic procedural alternatives remain available. Rocks, cacti, reeds, flowers, mountain caps, houses, six species, clouds, rain, and gift particles use reusable Godot vector drawing. Creature silhouettes differ through ears, horns, wings, tails, colors, and idle motion. They are independently animated and respond to saved simulation positions.

The tree was generated using the built-in imagegen tool, without an external paid API or API key. Its prompt specified an isolated jade tree, rounded gouache/clay foliage, warm trunk, clean alpha, and no scene backdrop. The source image remains in the Codex generated-images directory; the production-sized PNG is copied into `assets/` and used by the renderer. Asset preparation and synthesized WAV generation are reproducible through `devtools/prepare_assets.py` when the original source image is present. The committed tree PNG is sufficient to run and export the game.

Animations: tree foliage changes with a four-Hz cached sway; water ripples with the same terrain cache; creatures bob and interpolate movement each frame; houses emit drifting smoke; sky shader moves slowly; clouds, rain, gift rings and sparks animate separately. Day/night adds a gentle lighting tint. Particle counts and sprite resolution are bounded.

This milestone has a cohesive small-island identity, but procedural tile edges remain visible. More shoreline variants, terrain blending, richer creature sprites, custom vector icons, and hand-authored UI details remain polish tasks. No full-screen illustration substitutes for gameplay.
