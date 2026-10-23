"""Package the verified C tag without tools, private backend state or build outputs."""
from pathlib import Path
import subprocess,zipfile,hashlib,json
root=Path(__file__).resolve().parents[1]
def git(*args):return subprocess.check_output(['git',*args],cwd=root).decode().strip()
tag='age085-milestone-c';commit=git('rev-parse',tag+'^{commit}')
assert not git('status','--porcelain'),'Commit reviewed source before archiving'
assert commit==git('rev-parse','HEAD')
dest=root/'builds/LittleGod-0.8.5-milestone-C-source.zip';prefix='LittleGod-0.8.5-milestone-C/'
subprocess.run(['git','archive','--format=zip','--prefix='+prefix,'-o',str(dest),tag],cwd=root,check=True)
with zipfile.ZipFile(dest) as z:
 assert z.testzip() is None
 names=[n[len(prefix):] for n in z.namelist() if not n.endswith('/')]
 for n in names:
  assert not n.startswith(('tools/','.godot/','server/.local/')) and not n.endswith('/.env')
  assert '/bin/' not in n and '/obj/' not in n
  assert not n.startswith('builds/') or n=='builds/.gdignore'
 for n in ['scenes/adventure.tscn','scripts/hero.gd','scripts/adventure.gd','assets/adventure/warrior.png','tests/fixtures/planet-v085b.json','docs/STATUS.md','docs/COMBAT_SYSTEM.md']:assert n in names,n
apk=root/'builds/android/LittleGod-0.8.5-milestone-C-debug.apk'
report={'checkpoint':tag,'commit':commit,'current_version':'0.8.5-devC','complete_milestones':['A','B','C'],'full_age_of_kingdoms_finished':False,'started_09':False,'physical_device_verified':False,'public_deployment':False,'source':str(dest),'source_bytes':dest.stat().st_size,'source_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'crc_ok':True,'apk':str(apk),'apk_bytes':apk.stat().st_size,'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'game_checks':539}
(root/'builds/phase085c/checkpoint-manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report,indent=2))
