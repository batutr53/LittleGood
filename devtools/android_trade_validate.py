"""E1 actual native taps, live route profiling and external process restart; no player clear."""
from pathlib import Path
import argparse,hashlib,json,re,subprocess,time
r=Path(__file__).resolve().parents[1];parser=argparse.ArgumentParser();parser.add_argument('--fps',type=int,choices=[30,60],default=60);a=parser.parse_args()
out=r/f'builds/phase085e1/android-{a.fps}';out.mkdir(parents=True,exist_ok=True)
adb=Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe';player='org.littlegod.livinguniverse';pkg=player+'.betaqa'
def run(*args,check=True):return subprocess.run([str(adb),'-s','emulator-5554',*args],capture_output=True,check=check,timeout=90).stdout
def read(name,package=pkg):
 if subprocess.run([str(adb),'-s','emulator-5554','shell','run-as',package,'test','-f','files/'+name],capture_output=True).returncode:return b''
 return run('exec-out','run-as',package,'cat','files/'+name)
def put(name,data,package=pkg):
 p=out/name;p.write_bytes(data if isinstance(data,bytes) else data.encode());run('push',str(p),'/data/local/tmp/lg-trade-qa');run('shell','run-as',package,'cp','/data/local/tmp/lg-trade-qa','files/'+name)
def stage(expected):
 end=time.monotonic()+180
 while time.monotonic()<end:
  try:
   d=json.loads(read('phase4_qa_status.json'))
   if d.get('stage')==expected:return d
  except ValueError:pass
  time.sleep(.5)
 raise RuntimeError('Missing stage '+expected)
run('wait-for-device');run('shell','am','force-stop',player)
names=['planet.json','planet.json.bak','planet.json.tmp','settings.cfg'];before={n:read(n,player) for n in names};old_marker=read('phase2_benchmark.json',player)
run('install','--no-incremental','-r',str(r/'builds/android/LittleGod-0.8.5-milestone-E1-debug.apk'))
assert all(read(n,player)==b for n,b in before.items())
put('phase2_benchmark.json',json.dumps({'duration':3600}),player)
(out/'player-startup.txt').write_bytes(run('shell','am','start','-W','-n',player+'/com.godot.game.GodotAppLauncher'))
time.sleep(3);assert run('shell','pidof',player).strip();(out/'player-startup.png').write_bytes(run('exec-out','screencap','-p'));run('shell','am','force-stop',player)
if old_marker:put('phase2_benchmark.json',old_marker,player)
else:run('shell','run-as',player,'rm','-f','files/phase2_benchmark.json')
assert all(read(n,player)==b for n,b in before.items())
run('shell','am','force-stop',pkg);run('install','--no-incremental','-r',str(r/'builds/android/LittleGod-0.8.5-milestone-E1-qa-debug.apk'))
assert b'Success' in run('shell','pm','clear',pkg);run('shell','run-as',pkg,'mkdir','-p','files');run('logcat','-c')
put('phase4_qa.json',json.dumps({'phase':'trade','fps':a.fps}));run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher');ready=stage('trade_draft_touch')
w,h=map(int,re.findall(r'(\d+)x(\d+)',run('shell','wm','size').decode())[-1]);sx=w/ready['viewport'][0];sy=h/ready['viewport'][1]
def tap(p):run('shell','input','tap',str(round(p[0]*sx)),str(round(p[1]*sy)));time.sleep(.5)
tap(ready['plus']);tap(ready['confirm']);put('trade_dispatched','continue');print('NATIVE_CARAVAN_DEPARTED',flush=True)
ready=stage('trade_collect_touch');tap(ready['collect']);put('trade_first_collected','continue');print('NATIVE_DELIVERY_COLLECTED',flush=True)
result=stage('trade_complete');assert result['all_passed'],result
for name in ['android-trade-draft','android-trade-returned','android-trade-complete-tr']:(out/(name+'.png')).write_bytes(read(name+'.png'))
(out/'result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
run('shell','am','force-stop',pkg);put('phase4_qa.json',json.dumps({'phase':'trade_reopen','fps':a.fps}));run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher');ready=stage('trade_reopen_touch')
tap(ready['detour']);put('trade_detour','continue');print('RESTORED_CARAVAN_DETOUR',flush=True)
ready=stage('trade_reopen_collect');tap(ready['collect']);put('trade_collected','continue');reopened=stage('trade_reopened');assert reopened['all_passed'],reopened
(out/'reopen-result.json').write_text(json.dumps(reopened,indent=2),encoding='utf-8');(out/'memory.txt').write_bytes(run('shell','dumpsys','meminfo',pkg));(out/'logcat.txt').write_bytes(run('logcat','-d','-s','godot:V','AndroidRuntime:E'));run('shell','am','force-stop',pkg)
assert all(read(n,player)==b for n,b in before.items())
proof={'serial':'emulator-5554','physical_device':False,'player_files_preserved':{n:{'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),'present':bool(b)} for n,b in before.items()}}
(out/'player-preservation.json').write_text(json.dumps(proof,indent=2),encoding='utf-8');print(json.dumps(result,indent=2));print('ACTUAL_ANDROID_REOPEN',json.dumps(reopened))
