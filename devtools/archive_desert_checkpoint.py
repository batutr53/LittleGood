"""Archive verified E2 prerequisites, explicitly keeping E3 incomplete."""
from pathlib import Path
import json,subprocess,zipfile,hashlib
r=Path(__file__).resolve().parents[1];out=r/'builds/phase085e2full'
def git(*args):return subprocess.check_output(['git',*args],cwd=r).decode().strip()
def read(p):return json.loads(p.read_text())
tag='age085-e2-regions';commit=git('rev-parse',tag+'^{commit}')
assert not git('status','--porcelain') and commit==git('rev-parse','HEAD')
assert read(out/'verification.json')['all_passed'] and read(out/'rendered.json')['all_passed']
for fps in [60,30]:
 assert read(out/f'android-{fps}/before-restart.json')['all_passed'] and read(out/f'android-{fps}/result.json')['all_passed']
assert read(out/'android-iron-60/reopen.json')['all_passed'] and read(out/'player-install/result.json')['signature_verified']
dest=r/'builds/LittleGod-0.8.5-milestone-E2-source.zip';prefix='LittleGod-0.8.5-milestone-E2/'
subprocess.run(['git','archive','--format=zip','--prefix='+prefix,'-o',str(dest),tag],cwd=r,check=True)
with zipfile.ZipFile(dest) as z:
 assert z.testzip() is None
 names=[n[len(prefix):] for n in z.namelist() if not n.endswith('/')]
 for n in names:
  assert not n.startswith(('tools/','.godot/','server/.local/')) and not n.endswith('/.env') and '/bin/' not in n and '/obj/' not in n
  assert not n.startswith('builds/') or n=='builds/.gdignore'
 for n in ['scripts/ashen_desert.gd','assets/adventure/ashen-desert-ground.svg','tests/fixtures/planet-v085e2b.json','docs/AGE085_E3_REPORT.md']:assert n in names
def meta(p):return {'path':str(p),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
report={'checkpoint':tag,'commit':commit,'version':'0.8.5-devE2','android_code':91,'realm_campaign_cap':22,'E2_core_verified':True,'E3_started':False,'E3_complete':False,'quest23_implemented':False,'physical_device_verified':False,'game_checks':read(out/'verification.json')['game_checks'],'source':meta(dest),'player_apk':meta(r/'builds/android/LittleGod-0.8.5-milestone-E2-debug.apk'),'qa_apk':meta(r/'builds/android/LittleGod-0.8.5-milestone-E2-qa-debug.apk'),'source_crc_ok':True,'public_deployment':False}
(out/'checkpoint-manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report,indent=2))
