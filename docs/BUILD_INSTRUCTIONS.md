# Build and launch

The tools and local outputs already exist on this computer. No manual scene setup or drawing is needed.

## Local paths

- Editor: `D:\LittleGod\tools\godot\Godot_v4.7.2-stable_win64.exe`
- Console editor: same directory, `Godot_v4.7.2-stable_win64_console.exe`
- Project: `D:\LittleGod\project.godot`
- Desktop build: `D:\LittleGod\builds\windows\LittleGod.exe`
- Android debug APK: `D:\LittleGod\builds\android\LittleGod-debug.apk`

`Launch LittleGod.cmd` starts the project with the verified official Godot runtime. Windows App Control blocked the exported console launcher during testing, so standalone Windows-package execution is not verified on this machine. The project itself runs successfully through Godot. No policy or security control was bypassed.

## Reproduce checks and exports

Run `devtools/build.ps1` with PowerShell. It validates the Godot project, runs the suite, and exports Android and Windows debug artifacts using the installed templates. SDK and JDK are configured in Godot Editor Settings; paths are recorded in ENVIRONMENT.md. The Android build uses the normal debug signing key and is unsuitable as a store release. Its package ID is `org.littlegod.livinguniverse`, version 0.1.0, minimum Android API 24, target 36, ARM64 and x86_64. Internet permission is disabled.

For direct unit testing: `tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/suite.gd`. For a real rendered capture: launch the same executable with `--path . -- --capture`; it writes `builds/gameplay.png`, prints frame statistics and exits. Headless mode cannot produce that GPU screenshot.

MCP diagnostic: `node tools/godot-forge/dist/index.js doctor --project . --godot D:/LittleGod/tools/godot/Godot_v4.7.2-stable_win64.exe`. The versioned `devtools/mcp_action.mjs` accepts a JSON list of standard MCP tool calls; `devtools/ui-regression.json` is the recorded desktop input scenario. Run it against a playing editor session after creating a planet.

## Android validation environment

The dedicated `LittleGod_Test` AVD uses the already-installed API-35 Google APIs x86_64 system image. An emulator is not a substitute for physical-device performance or touch/cutout validation. APK signature verification uses SDK build-tools `apksigner`. The exported launcher is `com.godot.game.GodotAppLauncher`; the internal `GodotApp` activity is intentionally not exported.

## iOS preparation

`export_presets.cfg` contains an iOS preparation preset and bundle ID. Producing an installable binary requires macOS, a supported Xcode/iOS SDK, an Apple development team, signing/provisioning, and real-device validation. No iOS binary was built on Windows and no account sign-in was attempted.
