"""Build only the isolated, unapproved V4B preview. Preserve production preset bytes."""
from pathlib import Path
import os,subprocess
r=Path(__file__).resolve().parents[1];preset=r/'export_presets.cfg';original=preset.read_bytes();env=os.environ.copy();env['JAVA_HOME']=str(r/'tools/jdk/jdk-17.0.20.1+1')
license_file=r/'addons/godot_forge/LICENSE';license_bytes=license_file.read_bytes()
try:
 data=original.replace(b'custom_features=""',b'custom_features="v4_preview"',1).replace(b'org.littlegod.livinguniverse"',b'org.littlegod.livinguniverse.v4preview"',1).replace(b'version/code=92',b'version/code=93',1).replace(b'version/name="0.8.5-devE3"',b'version/name="0.8.5-v4b-preview"',1).replace(b'package/name="LittleGod"',b'package/name="LittleGod V4B Preview"',1)
 preset.write_bytes(data)
 subprocess.run([str(r/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'),'--headless','--path',str(r),'--export-debug','Android',str(r/'builds/android/LittleGod-V4B-preview-qa-debug.apk')],env=env,check=True)
finally:
 preset.write_bytes(original)
 license_file.write_bytes(license_bytes)
