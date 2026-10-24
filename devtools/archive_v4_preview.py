"""Archive only a clean V4B slice, never create the full V4 completion tag."""
from pathlib import Path
import subprocess,json,hashlib,zipfile
r=Path(__file__).resolve().parents[1];out=r/'builds/visual-v4';tag='littlegod-visual-rebirth-v4b-preview'
def git(*args):return subprocess.check_output(['git',*args],cwd=r).decode().strip()
def meta(p):return {'path':str(p),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
assert not git('status','--porcelain')
commit=git('rev-parse','HEAD');assert git('rev-parse',tag+'^{commit}')==commit
proof=json.loads((r/'docs/benchmarks/visual-v4/verification.json').read_text(encoding='utf-8'));assert proof['all_verified_slice_checks_passed'] and not proof['full_V4_complete']
apk=r/'builds/android/LittleGod-V4B-preview-qa-debug.apk';assert meta(apk)['sha256']==proof['apk']['sha256']
for fps in [60,30]:
 result=json.loads((out/f'android-{fps}/verification.json').read_text(encoding='utf-8'));assert result['all_passed'] and result['apk_sha256']==proof['apk']['sha256']
dest=r/'builds/LittleGod-V4B-preview-source.zip';prefix='LittleGod-V4B-preview/'
subprocess.run(['git','archive','--format=zip','--prefix='+prefix,'-o',str(dest),tag],cwd=r,check=True)
with zipfile.ZipFile(dest) as z:
 assert z.testzip() is None
 names=[n[len(prefix):] for n in z.namelist() if not n.endswith('/')]
 for n in names:
  assert not n.startswith(('tools/','.godot/','server/.local/')) and not n.endswith('/.env') and '/bin/' not in n and '/obj/' not in n
  assert not n.startswith('builds/') or n=='builds/.gdignore'
 for n in ['scripts/warrior_visual.gd','assets/visual_v4/warrior-walk.svg','assets/visual_v4/warrior-poses.json','docs/VISUAL_REBIRTH_V4_REPORT.md','Launch V4 Warrior Preview.cmd']:assert n in names,n
report={'checkpoint':tag,'commit':commit,'full_V4_complete':False,'verified_slice':'V4A/V4B isolated Warrior preview + input interruption fix','gameplay_baseline':'age085-e3-ancients','preserved_E4_WIP':'8b83003','physical_device_tested':False,'source_crc_ok':True,'source':meta(dest),'preview_apk':meta(apk),'production_E3_preserved':True,'game_checks':822,'new_presentation_checks':proof['new_presentation_checks'],'new_rendered_checks':proof['new_rendered_checks']}
(out/'checkpoint-manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report,indent=2))
