$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$godotExe = Join-Path $projectRoot 'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
Push-Location $projectRoot
try {
    New-Item -ItemType Directory builds -Force | Out-Null
    if (-not (Test-Path -LiteralPath 'builds/.gdignore')) { New-Item -ItemType File builds/.gdignore | Out-Null }
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
    & $godotExe --headless --path . --script tests/phase4.gd
    if ($LASTEXITCODE -ne 0) { throw 'Phase 4 beta checks failed' }
    & $godotExe --headless --path . --script tests/phase5.gd
    if ($LASTEXITCODE -ne 0) { throw 'Phase 5 checks failed' }
    & $godotExe --headless --path . --script tests/phase6.gd
    if ($LASTEXITCODE -ne 0) { throw 'Phase 6 checks failed' }
    & $godotExe --headless --path . --script tests/phase7.gd
    if ($LASTEXITCODE -ne 0) { throw 'Phase 7 checks failed' }
    & $godotExe --headless --path . --script tests/phase8.gd
    if ($LASTEXITCODE -ne 0) { throw 'Phase 8 checks failed' }
    dotnet test server/LittleGod.Tests -c Release --logger "trx;LogFileName=backend.trx" --results-directory builds/backend-tests
    if ($LASTEXITCODE -ne 0) { throw 'Backend validation checks failed' }
    [xml]$backendResult = Get-Content builds/backend-tests/backend.trx
    if ([int]$backendResult.TestRun.ResultSummary.Counters.passed -lt 42 -or [int]$backendResult.TestRun.ResultSummary.Counters.failed -ne 0) { throw 'Backend tests did not execute successfully' }
    New-Item -ItemType Directory builds/android,builds/windows -Force | Out-Null
    & $godotExe --headless --path . --export-debug Android builds/android/LittleGod-0.8-debug.apk
    if ($LASTEXITCODE -ne 0) { throw 'Android export failed' }
    & $godotExe --headless --path . --export-debug 'Windows Desktop' builds/windows/LittleGod.exe
    if ($LASTEXITCODE -ne 0) { throw 'Windows export failed' }
} finally { Pop-Location }
