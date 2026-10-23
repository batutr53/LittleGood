"""Package the reviewed partial E2B tag, retaining old releases and excluding private state."""
from pathlib import Path
import subprocess,zipfile,json,hashlib
r=Path(__file__).resolve().parents[1]
def git(*args):return subprocess.check_output(['git',*args],cwd=r).decode().strip()
tag='age085-e2b-iron-hills';commit=git('rev-parse',tag+'^{commit}')
assert not git('status','--porcelain') and commit==git('rev-parse','HEAD')
dest=r/'builds/LittleGod-0.8.5-milestone-E2B-source.zip';prefix='LittleGod-0.8.5-milestone-E2B/'
subprocess.run(['git','archive','--format=zip','--prefix='+prefix,'-o',str(dest),tag],cwd=r,check=True)
with zipfile.ZipFile(dest) as z:
 assert z.testzip() is None
 names=[n[len(prefix):] for n in z.namelist() if not n.endswith('/')]
 for n in names:
  assert not n.startswith(('tools/','.godot/','server/.local/')) and not n.endswith('/.env')
  assert '/bin/' not in n and '/obj/' not in n
  assert not n.startswith('builds/') or n=='builds/.gdignore'
 for n in ['scripts/regions.gd','scripts/iron_hills_map.gd','assets/adventure/stone_crawler.svg','tests/fixtures/planet-v085e1.json','docs/STATUS.md','docs/AGE085_E2_REPORT.md']:assert n in names
def metadata(p):return {'path':str(p),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
verification=json.loads((r/'builds/phase085e2/verification.json').read_text())
report={'checkpoint':tag,'commit':commit,'version':'0.8.5-devE2B','android_code':90,'partial_e2_slices':['E2A','E2B'],'full_E2_complete':False,'quest22_implemented':False,'realm_campaign_cap':21,'physical_device_verified':False,'source':metadata(dest),'player_apk':metadata(r/'builds/android/LittleGod-0.8.5-milestone-E2B-debug.apk'),'qa_apk':metadata(r/'builds/android/LittleGod-0.8.5-milestone-E2B-qa-debug.apk'),'source_crc_ok':True,'game_checks':verification['game_checks'],'public_deployment':False}
(r/'builds/phase085e2/checkpoint-manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report,indent=2))
