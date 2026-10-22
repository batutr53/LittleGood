# Environment and setup — 22 October 2026

Workspace: `D:\LittleGod`, initially empty. Windows 11 Pro x64 (build 26200). NVIDIA GeForce RTX 4070 Laptop GPU plus Intel UHD Graphics. Godot desktop captures confirmed the NVIDIA OpenGL renderer.

| Tool | Verified state |
|---|---|
| Godot | Official 4.7.2 stable Windows x64 portable editor installed under `tools/godot/`; `--version` verified; archive SHA-512 matches official release manifest |
| Export templates | Official matching 4.7.2 stable distribution installed under `%APPDATA%/Godot/export_templates/4.7.2.stable/` |
| Codex | Desktop session available; CLI 0.149.0 reused from existing npm installation |
| Node / npm | Existing Node 24.16.0 and npm 11.16.0 reused |
| Git | Existing Git 2.54.0.windows.1 reused; repository initialized locally |
| Python | Bundled Python 3.12.14 reused; Pillow used for asset preparation |
| Android SDK | Existing `%LOCALAPPDATA%/Android/Sdk`; platforms 36 and 36.1, build-tools 35/36/36.1, command-line tools, emulator and API-35 x86_64 image available |
| ADB | Existing platform-tools 37.0.0, ADB 1.0.41 verified |
| JDK | Temurin 17.0.20.1 downloaded from official Adoptium API into `tools/jdk/`. A separate pre-existing VibeUpTools JDK 17.0.19 was later found in Godot's editor settings and successfully used by export. No system Java setting was overwritten. |
| Image generation | Built-in imagegen available; one original tree generated and imported; no external paid API used |
| Computer Use | Bundled `@oai/sky` available; editor and running-game windows inspected. Embedded-editor native clicks were unreliable; successful input regression used Godot MCP. |
| Connected tools | GitHub, Figma, Adobe, Canva, Sites and other connectors available; none required for game runtime |

## Godot MCP

Requested npm package `godot-forge-mcp` returned npm E404. The requested GitHub repository was available and identified the same package as version 0.1.0. Source was cloned from `https://github.com/Tann2019/godot-mcp-server`, commit `b0da85fac67dd067c16bfe791227c0e7edb56d7e`, into ignored `tools/godot-forge/`. Dependencies were installed without lifecycle scripts and TypeScript compiled. Audit findings were resolved through compatible SDK updates and a development-only Vitest update; final npm audit reports zero vulnerabilities.

The upstream installer copied the MIT editor add-on, enabled it, and installed its inert runtime autoload. Codex registration used the supported `codex mcp add littlegod -- ...` command, preserving other configuration. The command uses the absolute Node executable, source-built MCP entry point, project path and Godot path.

The running session did not dynamically expose a new native Godot tool namespace. A local standard MCP SDK client nevertheless connected over stdio to the configured server and successfully exercised all requested checks: project info, scene tree, create temporary node, set position to (123,45), read position from editor, delete node, launch game, query game state, inspect runtime errors. Doctor confirmed the live editor bridge. Evidence: `builds/mcp.log`, `builds/mcp-verification.json`, `builds/ui-regression.log`. A later Codex session can load the registered `littlegod` server natively. Development did not wait for restart.

## Sources consulted

- [Official Godot Windows stable downloads](https://godotengine.org/download/windows/)
- [Official Godot release and checksums](https://github.com/godotengine/godot/releases/tag/4.7.2-stable)
- [Requested Godot Forge source and installation documentation](https://github.com/Tann2019/godot-mcp-server)
- [Official Codex MCP configuration](https://developers.openai.com/codex/mcp)
- [Godot OpenGL limits documentation](https://docs.godotengine.org/en/4.6/classes/class_projectsettings.html)

Godot and dependencies were installed portably or reused. No privilege escalation, external account sign-in, paid service, store publication, firewall or antivirus change occurred. A new disposable emulator named `LittleGod_Test` was created; unrelated existing AVDs were not changed.
