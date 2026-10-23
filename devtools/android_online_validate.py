"""Disposable Android package to the real host API; never clears release saves."""
from pathlib import Path
import json,subprocess,time,hashlib,argparse
parser=argparse.ArgumentParser();parser.add_argument('--offline',action='store_true');args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
out=root/'builds/phase7/android-online';out.mkdir(parents=True,exist_ok=True)
adb=Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe'
package='org.littlegod.livinguniverse.betaqa'
def run(*args,check=True):return subprocess.run([str(adb),'-s','emulator-5554',*args],capture_output=True,check=check,timeout=60).stdout
run('wait-for-device')
run('shell','am','force-stop',package)
if not args.offline:
    run('install','-r',str(root/'builds/android/LittleGod-0.7-qa-debug.apk'))
    assert b'Success' in run('shell','pm','clear',package) # Reserved QA identity only.
    run('shell','am','start','-n',package+'/com.godot.game.GodotAppLauncher')
    time.sleep(2)
    run('shell','am','force-stop',package)
run('shell','run-as',package,'rm','-f','files/phase4_qa_status.json')
flag=out/'phase4_qa.json';flag.write_text(json.dumps({'phase':'offline_shutdown' if args.offline else 'online'}),encoding='utf-8')
run('push',str(flag),'/data/local/tmp/littlegod-online-qa')
run('shell','run-as',package,'cp','/data/local/tmp/littlegod-online-qa','files/phase4_qa.json')
run('shell','am','start','-n',package+'/com.godot.game.GodotAppLauncher')
deadline=time.monotonic()+110
while time.monotonic()<deadline:
    raw=run('exec-out','run-as',package,'cat','files/phase4_qa_status.json',check=False)
    try:r=json.loads(raw)
    except ValueError:time.sleep(.4);continue
    if r.get('stage')==('offline_complete' if args.offline else 'online_complete'):break
    time.sleep(.4)
else:
    (out/'failure-logcat.txt').write_bytes(run('logcat','-d','-t','500'))
    raise RuntimeError('Android real online flow did not complete')
r['device']='Android emulator API35 x86_64';r['physical_device']=False
apk=root/'builds/android/LittleGod-0.7-qa-debug.apk';r['qa_apk_sha256']=hashlib.sha256(apk.read_bytes()).hexdigest()
(out/('offline-result.json' if args.offline else 'result.json')).write_text(json.dumps(r,indent=2),encoding='utf-8')
for name in ([] if args.offline else ['friends','profile','visit','creature','inbox','discovery','home-tr']):
    (out/(name+'.png')).write_bytes(run('exec-out','run-as',package,'cat','files/'+name+'.png'))
(out/'memory.txt').write_bytes(run('shell','dumpsys','meminfo',package))
(out/'logcat.txt').write_bytes(run('logcat','-d','-s','godot:I','AndroidRuntime:E'))
print(json.dumps(r,indent=2))
assert all(r['checks'].values()) and (len(r['checks'])>=33 if not args.offline else len(r['checks'])==5)
