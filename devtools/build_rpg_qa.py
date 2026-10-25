"""Export the RPG work-in-progress as a separate package without touching player saves."""
from pathlib import Path
import os,subprocess,hashlib,json,argparse
parser=argparse.ArgumentParser();parser.add_argument('--output',default='LittleGod-RPG-interface-qa-debug.apk');parser.add_argument('--manifest',default='rpg-apk.json');parser.add_argument('--version-code',default='94');args=parser.parse_args()
r=Path(__file__).resolve().parents[1]
preset=r/'export_presets.cfg';original=preset.read_bytes();env=os.environ.copy();env['JAVA_HOME']=str(r/'tools/jdk/jdk-17.0.20.1+1')
assert Path(args.output).name==args.output and Path(args.manifest).name==args.manifest
out=r/'builds/android'/args.output
try:
    preset.write_bytes(original.replace(b'org.littlegod.livinguniverse"',b'org.littlegod.livinguniverse.rpgqa"',1).replace(b'version/code=92',('version/code='+args.version_code).encode(),1).replace(b'version/name="0.8.5-devE3"',b'version/name="0.8.5-rpg-wip"',1).replace(b'package/name="LittleGod"',b'package/name="LittleGod RPG QA"',1))
    subprocess.run([str(r/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'),'--headless','--path',str(r),'--export-debug','Android',str(out)],env=env,check=True)
finally:preset.write_bytes(original)
report={'apk':str(out),'bytes':out.stat().st_size,'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'package':'org.littlegod.livinguniverse.rpgqa','production_preset_preserved':preset.read_bytes()==original}
(r/'builds'/args.manifest).write_text(json.dumps(report,indent=2),encoding='utf8')
print(json.dumps(report,indent=2))
