@echo off
cd /d "%~dp0"
if exist "builds\windows\LittleGod.exe" (
  start "LittleGod" "builds\windows\LittleGod.exe"
) else (
  start "LittleGod" "tools\godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
)
