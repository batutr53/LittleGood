"""Export the RPG work-in-progress as a separate package without touching player saves."""
from pathlib import Path
import os,subprocess,hashlib,json
r=Path(__file__).resolve().parents[1]
preset=r/'export_presets.cfg';original=preset.read_bytes();env=os.environ.copy();env['JAVA_HOME']=str(r/'tools/jdk/jdk-17.0.20.1+1')
out=r/'builds/android/LittleGod-RPG-interface-qa-debug.apk'
try:
    preset.write_bytes(original.replace(b'org.littlegod.livinguniverse"',b'org.littlegod.livinguniverse.rpgqa"',1).replace(b'version/code=92',b'version/code=94',1).replace(b'version/name="0.8.5-devE3"',b'version/name="0.8.5-rpg-wip"',1).replace(b'package/name="LittleGod"',b'package/name="LittleGod RPG QA"',1))
    subprocess.run([str(r/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'),'--headless','--path',str(r),'--export-debug','Android',str(out)],env=env,check=True)
finally:preset.write_bytes(original)
report={'apk':str(out),'bytes':out.stat().st_size,'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'package':'org.littlegod.livinguniverse.rpgqa','production_preset_preserved':preset.read_bytes()==original}
(r/'builds/rpg-apk.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print(json.dumps(report,indent=2))
