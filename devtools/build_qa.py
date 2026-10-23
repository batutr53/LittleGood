"""Export an isolated debug QA package, restoring the exact preset bytes in all cases."""
from pathlib import Path
import os, subprocess
root = Path(__file__).resolve().parent.parent
(root / 'builds/android').mkdir(parents=True, exist_ok=True)
(root / 'builds/.gdignore').touch(exist_ok=True)
preset = root / 'export_presets.cfg'
original = preset.read_bytes()
env = os.environ.copy()
env['JAVA_HOME'] = str(root / 'tools/jdk/jdk-17.0.20.1+1')
try:
    preset.write_bytes(original.replace(b'org.littlegod.livinguniverse"', b'org.littlegod.livinguniverse.betaqa"'))
    subprocess.run([str(root / 'tools/godot/Godot_v4.7.2-stable_win64_console.exe'),
                    '--headless', '--path', str(root), '--export-debug', 'Android',
                    str(root / 'builds/android/LittleGod-0.6-qa-debug.apk')], env=env, check=True)
finally:
    preset.write_bytes(original)
