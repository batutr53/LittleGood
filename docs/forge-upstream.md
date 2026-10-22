# Godot Forge

**AI game development for Godot 4.** An MCP server plus a Godot editor add-on that let Claude Code, Cursor, Codex, Claude Desktop, VS Code and any other MCP client **build, run, see, playtest and fix** your game — in the live editor, with every change reviewable and reversible.

Think "Aura for Unreal", but for Godot, open source (MIT), and working with the AI assistant you already use.

```
You: add a double jump and make it feel good
AI:  docs.class CharacterBody2D → script.edit player.gd (0 errors) → run.play → input.send jump,jump
     → game.sample velocity → test.scenario "double jump" ✓ saved → particles.create dust → view.game
     "Done: double jump with coyote time + dust burst. Try it with Space twice. Review in the Forge dock."
```

## Why it's different

| | Godot Forge | Typical Godot MCP servers |
|---|---|---|
| **Grounded in your engine version** | Class reference for the *exact* installed Godot (signatures via `--doctool`, descriptions from the matching release), live `ClassDB` introspection, Godot 3→4 migration hints | Model guesses the API (and often writes Godot 3 code) |
| **Closed loop** | Play the game, simulate input, screenshots (annotated), live tree/state, `eval`, wait-for-condition, time series sampling, scripted **playtest scenarios** with assertions saved as regression tests | Edit files, maybe run the project |
| **Safe** | Every edit through the editor's UndoRedo; automatic **changesets** with diff / approve / discard / checkpoints in a **Forge dock** (like Aura's sandbox); atomic `batch` with rollback | Direct file writes |
| **Human collaboration (editor-first)** | The AI builds real nodes, inspector properties, `.tres` resources, saved signal connections, AnimationPlayers and painted TileMaps — the same scenes you'd make by hand, fully editable in the Godot editor. Instructions, the skill and `test.lint` steer it away from building static content in `_ready()` | Scripts that construct the scene at runtime; nothing to see or tweak in the editor |
| **Lean context** | ~30 consolidated tools with `action` parameters, rich descriptions, friendly value coercion, "did you mean" errors | 100–190 tiny tools, or too few to be useful |
| **Knows game dev** | Built-in guides (platformer, top-down, 3D, UI, tilemaps, physics, enemies/AI, game feel, save/load, shaders, audio, …), templates, MCP prompts (`new-game`, `add-feature`, `fix-bug`, `playtest`, `polish`), a Claude Code skill | Raw tools only |
| **Assets** | Instant placeholder art, CC0 libraries (Poly Haven, ambientCG, Poly Pizza) with credits, optional AI generation (OpenAI images, ElevenLabs SFX, Meshy 3D) | — |
| **Measured** | 30-task eval suite that lets an agent build features and grades them by playing the game | — |
| **In-editor agent** | Optional **Forge Agent** panel: chat with Claude inside Godot | — |

## Quick start

1. **Install Godot 4.4+** (4.7 recommended) and make sure `godot` is on your PATH (or set `GODOT_PATH`).
   - Windows: `winget install GodotEngine.GodotEngine` · macOS: `brew install --cask godot` · Linux: your package manager / Flathub.
2. **Add Godot Forge to your project** (Node 20+):
   ```bash
   cd path/to/your/godot/project
   npx -y godot-forge-mcp@latest install          # copies addons/godot_forge, enables it, writes .mcp.json for Claude Code
   ```
   Or start a new game: `npx -y godot-forge-mcp@latest new my-game --name "My Game"` (`--3d`, `--pixel` optional).
3. **Open your AI client in the project folder.** With Claude Code:
   ```bash
   claude                     # picks up .mcp.json; approve the "godot" server
   > /mcp                     # should list "godot" as connected
   ```
   If the editor isn't open, the server launches it for you (disable with `--launch none`).

### Other clients

| Client | Setup |
|---|---|
| Claude Code (global) | `claude mcp add godot -- npx -y godot-forge-mcp@latest` |
| Claude Code plugin | this repo is also a Claude Code plugin (MCP server + skill) |
| Cursor | `npx -y godot-forge-mcp install --client cursor` (writes `.cursor/mcp.json`) |
| VS Code (Copilot) | `npx -y godot-forge-mcp install --client vscode` (writes `.vscode/mcp.json`) |
| Codex | `~/.codex/config.toml`: `[mcp_servers.godot]` `command = "npx"` `args = ["-y", "godot-forge-mcp@latest", "--project", "/path/to/project"]` |
| Claude Desktop / others | stdio command `npx -y godot-forge-mcp@latest --project /path/to/project` |

`npx godot-forge-mcp doctor` checks Godot, the add-on and the editor connection.

### Try the demo

`examples/demo` is a small platformer built entirely through Godot Forge (TileMap level, player and coin scenes, HUD, signals connected in the scene, a saved playtest):

```bash
npx -y godot-forge-mcp@latest install examples/demo   # add-on + .mcp.json
godot --editor --path examples/demo                   # see the Forge dock and the Forge Agent panel
```

## Tools

| Tool | What it covers |
|---|---|
| `project` | info, settings, autoloads, **input map**, layer names, plugins, UIDs, `create_project` |
| `files` | list/search/read/write/**edit** (exact replacements)/move (updates references)/delete (to trash), view images |
| `scene` | create/open/save/tree/list, instance scenes, inherit, pack a branch into its own scene |
| `node` | add (whole subtrees + inline resources), set/get properties, duplicate, move, find, change type, groups, selection |
| `signal` | list, connect (generates handler stubs), disconnect, scene/project signal graph |
| `script` | create from templates, write/edit with **compile diagnostics**, validate project, outline, attach, references |
| `resource` | create/read/edit `.tres` (materials, shapes, custom data), assign, extract |
| `introspect` | live engine API: class members, where a member is declared, node types |
| `docs` | version-exact class reference search, migration notes, built-in guides |
| `run` | play/stop, startup errors, runtime errors with script `file:line`, output |
| `game` | running game: live tree, get/set/call/eval, wait for conditions/signals, sample values over time, time scale/pause/step, perf, raycasts, audio mute / what's playing |
| `input` | press actions/keys/gamepad, click/drag (or click a UI node), type text, record & replay |
| `view` | game screenshots (optionally annotated), **offscreen scene renders from any angle**, editor screenshots, resource previews |
| `test` | playtest **scenarios** (play → input → wait → assert → screenshot), lint, GUT/gdUnit4, screenshot baselines |
| `changes` | changesets: status/diff/checkpoint/restore/approve/discard/history |
| `batch` | many operations as one undoable transaction |
| `exec` | escape hatch: run GDScript in the editor or the game |
| `animation` | AnimationPlayer clips with tracks/keys in one call, SpriteFrames from images/sheets, AnimationTree state machines & blend spaces |
| `tiles` | TileSets from images (auto collision), TileMapLayer paint/fill/terrain, **ASCII level layout** |
| `physics` | bodies with shapes in one call, fit shapes to sprites/meshes, named layers/masks, joints |
| `navigation` | regions, baking, agents, links |
| `world3d` | primitives/CSG, materials, lights, environment presets, cameras, glTF import, GridMap/MeshLibrary, scattering |
| `shader` | templates (dissolve, outline, water, toon, …), validation, uniforms, material params |
| `ui` | build Control trees from a spec, layout presets, themes/styleboxes, fonts, menu builder, layout inspection |
| `audio` | buses & effects, players, loop import, procedural placeholder SFX |
| `particles` | GPU/CPU particles with presets (fire, smoke, sparks, explosion, rain, …) |
| `assets` | placeholders, CC0 search/download with credits, AI image/SFX/3D generation, import presets |
| `export` | presets, template check, headless export builds |

Resources: `godot://project/memory` (your `GODOT_AI.md`), `godot://project/summary`, `godot://scene/{path}`, `godot://docs/{Class}`, `godot://guides/{topic}`.
Prompts: `new-game`, `add-feature`, `fix-bug`, `playtest`, `polish`.

## How it works

```
MCP client ──stdio──> godot-forge-mcp (Node) ──ws://127.0.0.1 (token)──> Godot editor add-on
                                  │                                        │ EngineDebugger channel
                                  └── godot --headless (docs, tests, export)  ▼
                                                                         ForgeRuntime autoload (in the running game)
```

- The **editor add-on** (`addons/godot_forge`) hosts a loopback-only WebSocket with a per-session token and executes requests with the editor's own APIs (UndoRedo, EditorInterface), so the scene you see is the scene the AI edits.
- The **runtime autoload** is inert unless the game was started from the editor with the debugger attached; it talks over Godot's debugger protocol (no extra ports) and ships nothing active in exported builds.
- **Changesets** live in a private git history in `.godot/forge/` (your own git repo is never touched). Needs `git` on PATH.
- The server auto-installs/updates the add-on in the project when it launches the editor.

## The Forge dock and Forge Agent

- **Forge dock** (right side): connection status, files the AI changed since the last approval (**Approve all / Discard all / Revert selected / Diff / Checkpoint**), and a live activity feed of every AI action.
- **Forge Agent** (bottom panel): chat with Claude from inside Godot. It runs [Claude Code](https://claude.com/claude-code) headless with Godot Forge attached, sends your current scene/selection as context, and streams what it does. Configure in Editor Settings → `godot_forge/agent/*`.

## Configuration

| Option | Default | |
|---|---|---|
| `--project <dir>` / `GODOT_PROJECT` | found from the working directory | Godot project to use |
| `--launch gui\|headless\|none` / `GODOT_FORGE_LAUNCH` | `gui` | start the editor when it isn't running |
| `--profile core\|full` / `GODOT_FORGE_PROFILE` | `full` | `core` = 16 essential tools for clients with small tool budgets |
| `--tools a,b,c` | all | explicit tool allowlist |
| `--godot <exe>` / `GODOT_PATH` | auto-detect | Godot 4 executable |
| `OPENAI_API_KEY`, `ELEVENLABS_API_KEY`, `MESHY_API_KEY`, `POLY_PIZZA_API_KEY` | – | optional asset generators/sources |
| Editor Settings `godot_forge/autosave`, `auto_changeset`, `screenshot_max_size`, `mute_game_audio` | on, on, 1280, off | editor-side behaviour. Playtest scenarios and headless/test editors always start the game muted (`run.play {mute}` / `game.audio` to control it) |

## Evals

`npm run eval -- --tasks double_jump,coins_score --model sonnet` copies a template project per task, lets Claude Code build the feature through Godot Forge with no human input, then grades it by **playing the game** (scenarios with input and assertions) and linting the project. See [`evals/`](evals) and the latest results in [`evals/RESULTS.md`](evals/RESULTS.md).

## Development

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md). Short version:

```bash
npm install && npm run build
npm test                 # unit tests
npm run test:e2e         # headless editor end-to-end tests (needs Godot)
bash scripts/check.sh    # parse-check every GDScript file of the add-on
```

## License

MIT. Godot is a trademark of the Godot Foundation; this project is not affiliated with it.

