"""Archive the clean verified A checkpoint locally, without creating a final-release tag."""
from pathlib import Path
import hashlib,json,subprocess,zipfile
root=Path(__file__).resolve().parents[1]
def git(*args):return subprocess.check_output(['git',*args],cwd=root).decode().strip()
tag='age085-milestone-a';commit=git('rev-parse',tag+'^{commit}')
assert not git('status','--porcelain'),'Checkpoint source must be reviewed and clean'
assert commit==git('rev-parse','HEAD'),'Milestone tag must identify verified HEAD'
dest=root/'builds/LittleGod-0.8.5-milestone-A-source.zip';prefix='LittleGod-0.8.5-milestone-A/'
subprocess.run(['git','archive','--format=zip','--prefix='+prefix,'-o',str(dest),tag],cwd=root,check=True)
with zipfile.ZipFile(dest) as archive:
 assert archive.testzip() is None
 names=[name[len(prefix):] for name in archive.namelist() if not name.endswith('/')]
 for name in names:
  assert not name.startswith(('tools/','.godot/','server/.local/')) and not name.endswith('/.env')
  assert '/bin/' not in name and '/obj/' not in name
  assert not name.startswith('builds/') or name=='builds/.gdignore'
 for name in ['scripts/kingdom.gd','assets/kingdom/quests.json','assets/kingdom/arin.png','tests/phase085.gd','tests/fixtures/planet-v08.json','docs/PHASE085_REPORT.md','docs/STATUS.md','scripts/cosmetics.gd','server/LittleGod.Api/Program.cs']:
  assert name in names,name
 tests=json.loads(archive.read(prefix+'docs/benchmarks/phase085/tests.json'))
apk=root/'builds/android/LittleGod-0.8.5-milestone-A-debug.apk'
manifest={'checkpoint':tag,'commit':commit,'completed_milestone':'A','pending_milestones':['B','C','D','E','F','G','H'],'finished_expansion':False,'version':'0.8.5-devA','source_archive':str(dest),'source_bytes':dest.stat().st_size,'source_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'archive_crc_ok':True,'sdk_credentials_database_generated_outputs_excluded':True,'apk':str(apk),'apk_bytes':apk.stat().st_size,'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'campaign_tests':tests,'retained_game_checks':356,'physical_device_verified':False,'public_deployment':False}
(root/'builds/phase085/checkpoint-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(json.dumps(manifest,indent=2))
