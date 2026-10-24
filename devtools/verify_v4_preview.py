"""Validate a fixed gameplay source snapshot, then build/test its isolated APK."""
from pathlib import Path
import subprocess,sys,hashlib,json
r=Path(__file__).resolve().parents[1];out=r/'builds/visual-v4';godot=str(r/'tools/godot/Godot_v4.7.2-stable_win64_console.exe')
def fingerprint():
 files=[r/'project.godot']+[p for base in ['scripts','scenes','assets','tests'] for p in (r/base).rglob('*') if p.is_file() and p.suffix not in ['.import','.uid']]
 return {str(p.relative_to(r)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
def run(args,name):
 with (out/name).open('wb') as f:subprocess.run(args,cwd=r,stdout=f,stderr=subprocess.STDOUT,check=True,timeout=420)
 text=(out/name).read_text(encoding='utf-8',errors='replace')
 errors=[s for s in text.splitlines() if ('SCRIPT ERROR' in s or 'Parse Error' in s or ('ERROR:' in s and 'resources still in use at exit' not in s))]
 assert not errors,errors
 print('PASS '+name,flush=True)
run([godot,'--headless','--editor','--path',str(r),'--import','--quit'],'import.log');source=fingerprint()
run([sys.executable,'-X','utf8','devtools/verify_sanctuary.py'],'regression.log')
run([godot,'--headless','--path',str(r),'--script','tests/v4_presentation.gd'],'presentation.log')
run([godot,'--path',str(r),'--script','tests/v4_warrior_playtest.gd'],'rendered.log')
for name in ['presentation','rendered']:assert json.loads((out/(name+'.json')).read_text())['all_passed']
run([sys.executable,'devtools/build_v4_preview.py'],'export.log')
for fps in [60,30]:run([sys.executable,'devtools/android_v4_validate.py','--fps',str(fps)],f'android-{fps}.log')
assert fingerprint()==source,'Game source changed during validation'
(out/'source-fingerprints.json').write_text(json.dumps(source,indent=2),encoding='utf-8')
print('FIXED SNAPSHOT VERIFIED',flush=True)
