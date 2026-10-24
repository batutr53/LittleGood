# Sprite animation pipeline — V4B prototype

Run `python devtools/create_v4_warrior.py`, then import with the verified Godot4.7.2 runtime. Original source is SVG geometry plus controlled pose tables; no bitmap editing or external paid service is involved. Image generation is available, but controlled vector authoring was chosen for frame consistency and this isolated study.

Each atlas is1024×512 with128×128 cells. Rows are south/east/north/west. Idle/walk use8 cells per row; attack5, dodge6, hit3, defeat6. The fixed foot pivot is(64,112). The actor presentation scale is1.12. The image origin is offset48 units above the CharacterBody2D origin; shadow stays at the model foot point. Socket JSON records hand locations for the same pose cells.

`warrior_visual.gd` builds one cached SpriteFrames resource with144 AtlasTextures over six shared textures. It assigns frames from the authoritative20Hz clock rather than playing an independent gameplay clock. Idle breathes on clock time; walking advances every9 world units of actual travel. No walk cycle is advanced by a desired velocity against a wall. Rendering cannot call combat resolution. Its state/cache is ephemeral and absent from saves.

Six RGBA atlases have a12MiB uncompressed upper bound before texture compression/mipmaps. There is no per-frame image generation, shader allocation or uncapped particle spawning. Sword/shield are small vector drawings at the saved pose sockets. Cache is initialized only when the preview is enabled. Desktop peak texture memory includes the whole world, not just the Warrior.

Reproduce deterministic checks: `tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/v4_presentation.gd`.
Rendered checks: same runtime with `--path . --script tests/v4_warrior_playtest.gd`.
Enable preview with `Launch V4 Warrior Preview.cmd` or explicit `-- --v4-preview`. Normal launcher remains E3. Android preview uses only its isolated package/feature.
