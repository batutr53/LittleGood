"""Archive an explicitly verified partial checkpoint, never mint a final E tag."""
from pathlib import Path
import argparse,subprocess,zipfile,hashlib,json
r=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('slice',choices=['D-critical','E1']);a=p.parse_args()
def git(*args):return subprocess.check_output(['git',*args],cwd=r).decode().strip()
tag={'D-critical':'age085-d-critical','E1':'age085-e1-trade'}[a.slice]
assert not git('status','--porcelain');commit=git('rev-parse',tag+'^{commit}');assert commit==git('rev-parse','HEAD')
dest=r/f'builds/LittleGod-0.8.5-milestone-{a.slice}-source.zip';prefix=f'LittleGod-0.8.5-{a.slice}/'
subprocess.run(['git','archive','--format=zip','--prefix='+prefix,'-o',str(dest),tag],cwd=r,check=True)
with zipfile.ZipFile(dest) as z:
 assert z.testzip() is None
 for name in z.namelist():
  n=name[len(prefix):];assert not n.startswith(('tools/','.godot/','server/.local/')) and not n.endswith('/.env')
  assert '/bin/' not in n and '/obj/' not in n
  assert not n.startswith('builds/') or n=='builds/.gdignore'
apk=r/f'builds/android/LittleGod-0.8.5-milestone-{a.slice}-debug.apk'
report={'checkpoint':tag,'commit':commit,'final_E_complete':False,'physical_device_verified':False,'source':str(dest),'source_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'source_bytes':dest.stat().st_size,'crc_ok':True,'apk':str(apk),'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'apk_bytes':apk.stat().st_size}
out=r/('builds/phase085d' if a.slice=='D-critical' else 'builds/phase085e1');out.mkdir(exist_ok=True)
(out/'checkpoint-manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report,indent=2))
