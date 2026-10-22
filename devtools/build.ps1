$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$godotExe = Join-Path $projectRoot 'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
Push-Location $projectRoot
try {
    & $godotExe --headless --editor --path . --import --quit
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
    & $godotExe --headless --path . --script tests/suite.gd
    if ($LASTEXITCODE -ne 0) { throw 'Tests failed' }
    & $godotExe --headless --path . --script tests/runtime.gd
    if ($LASTEXITCODE -ne 0) { throw 'Runtime integration test failed' }
    & $godotExe --headless --path . --script tests/phase2.gd
    if ($LASTEXITCODE -ne 0) { throw 'Phase 2 regression checks failed' }
    & $godotExe --headless --path . --script tests/phase3.gd
    if ($LASTEXITCODE -ne 0) { throw 'Phase 3 gameplay checks failed' }
    New-Item -ItemType Directory builds/android,builds/windows -Force | Out-Null
    & $godotExe --headless --path . --export-debug Android builds/android/LittleGod-0.3-debug.apk
    if ($LASTEXITCODE -ne 0) { throw 'Android export failed' }
    & $godotExe --headless --path . --export-debug 'Windows Desktop' builds/windows/LittleGod.exe
    if ($LASTEXITCODE -ne 0) { throw 'Windows export failed' }
} finally { Pop-Location }
