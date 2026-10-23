"""Same-host 0.7 control, keeping and restoring every player save/settings byte."""
from pathlib import Path
import subprocess,json,hashlib,sys,shutil
root=Path(__file__).resolve().parents[1];out=root/'builds/phase8';old=out/'pre-batching';old.mkdir(exist_ok=True)
for p in (out/'final-android').glob('*'):
 if p.is_file():shutil.copyfile(p,old/p.name)
adb=Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe';base=[str(adb),'-s','emulator-5554'];pkg='org.littlegod.livinguniverse'
def run(*a,check=True):return subprocess.run(base+list(a),capture_output=True,check=check,timeout=90).stdout
run('wait-for-device');run('shell','am','force-stop',pkg);run('shell','am','force-stop',pkg+'.betaqa')
names=['planet.json','planet.json.bak','planet.json.tmp','settings.cfg']
def slots():return {n:run('exec-out','run-as',pkg,'cat','files/'+n,check=False) for n in names}
before=slots()
try:
 run('install','-r','-d',str(root/'builds/android/LittleGod-0.7-debug.apk'));assert before==slots()
 subprocess.run([sys.executable,str(root/'devtools/profile_android.py'),'--duration','20','--output-dir','builds/phase8/matched-07'],cwd=root,check=True)
finally:
 run('shell','am','force-stop',pkg);run('install','-r',str(root/'builds/android/LittleGod-0.8-debug.apk'))
 report={'source':'same_host_preserved_apk_control','old_version':'0.7.0','restored_version':'0.8.0','files_preserved':{n:slots()[n]==before[n] for n in names}}
 (out/'matched-control.json').write_text(json.dumps(report,indent=2));assert all(report['files_preserved'].values())
print('Original 0.7 measured and 0.8 restored without resetting the player package.')
