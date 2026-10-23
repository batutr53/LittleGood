"""Update the player package without clearing data and verify all existing save slots."""
from pathlib import Path
import subprocess,json,hashlib
root=Path(__file__).resolve().parent.parent
adb=Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe'
pkg='org.littlegod.livinguniverse'
def run(*args,check=True):return subprocess.run([str(adb),'-s','emulator-5554',*args],capture_output=True,check=check,timeout=60).stdout
def saves():return {name:run('exec-out','run-as',pkg,'cat','files/'+name,check=False) for name in ['planet.json','planet.json.bak','planet.json.tmp','settings.cfg']}
run('wait-for-device')
run('shell','am','force-stop',pkg)
before=saves()
apk=root/'builds/android/LittleGod-0.8-debug.apk'
installed=run('install','-r',str(apk)).decode()
after=saves()
report={'package':pkg,'emulator':'emulator-5554','install':installed.strip(),'preserved':{k:before[k]==after[k] for k in before},'apk_bytes':apk.stat().st_size,'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest()}
(root/'builds/phase8/android-install.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
assert all(report['preserved'].values())
