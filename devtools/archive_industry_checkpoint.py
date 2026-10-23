"""Archive the verified prerequisite-B checkpoint; never create a completed0.9 release tag."""
from pathlib import Path
import hashlib,json,subprocess,zipfile
root=Path(__file__).resolve().parents[1]
def git(*args):return subprocess.check_output(['git',*args],cwd=root).decode().strip()
tag='age085-milestone-b';commit=git('rev-parse',tag+'^{commit}')
assert not git('status','--porcelain'),'Commit reviewed source before archiving'
assert commit==git('rev-parse','HEAD'),'Checkpoint tag must identify verified HEAD'
dest=root/'builds/LittleGod-0.8.5-milestone-B-source.zip';prefix='LittleGod-0.8.5-milestone-B/'
subprocess.run(['git','archive','--format=zip','--prefix='+prefix,'-o',str(dest),tag],cwd=root,check=True)
with zipfile.ZipFile(dest) as archive:
 assert archive.testzip() is None
 names=[name[len(prefix):] for name in archive.namelist() if not name.endswith('/')]
 for name in names:
  assert not name.startswith(('tools/','.godot/','server/.local/')) and not name.endswith('/.env')
  assert '/bin/' not in name and '/obj/' not in name
  assert not name.startswith('builds/') or name=='builds/.gdignore'
 for name in ['scripts/industry.gd','scripts/kingdom.gd','assets/kingdom/recipes.json','assets/kingdom/arin.png','tests/fixtures/planet-v085a.json','docs/PHASE09_REPORT.md','docs/STATUS.md','scripts/cosmetics.gd','server/LittleGod.Api/Program.cs']:
  assert name in names,name
 tests=json.loads(archive.read(prefix+'docs/benchmarks/phase09/industry-tests.json'))
apk=root/'builds/android/LittleGod-0.8.5-milestone-B-debug.apk'
report={'checkpoint':tag,'commit':commit,'target_version':'0.9','current_version':'0.8.5-devB','completed_prerequisites':['0.8.5 A','0.8.5 B'],'finished_09':False,'finished_085':False,'next':'0.8.5 C: real Wildwood adventure, levels11-15, hero/combat/loot','source':str(dest),'source_bytes':dest.stat().st_size,'source_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'archive_crc_ok':True,'credentials_sdk_database_build_outputs_excluded':True,'apk':str(apk),'apk_bytes':apk.stat().st_size,'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'retained_checks':406,'new_checks':tests['passed'],'failed':tests['failed'],'physical_device_verified':False,'public_deployment':False}
(root/'builds/phase09/checkpoint-manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report,indent=2))
