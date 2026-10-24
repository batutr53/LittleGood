"""V4B isolated emulator QA. Native ADB input, force-stop restore, bounded metrics."""
from pathlib import Path
import subprocess,time,json,re,argparse,hashlib
r=Path(__file__).resolve().parents[1];parser=argparse.ArgumentParser();parser.add_argument('--fps',type=int,choices=[30,60],default=60);a=parser.parse_args();out=r/f'builds/visual-v4/android-{a.fps}';out.mkdir(parents=True,exist_ok=True)
adb=Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe';pkg='org.littlegod.livinguniverse.v4preview';player='org.littlegod.livinguniverse'
def run(*args,check=True):return subprocess.run([str(adb),'-s','emulator-5554',*args],capture_output=True,check=check,timeout=120).stdout
def read(name,package=pkg):
 if subprocess.run([str(adb),'-s','emulator-5554','shell','run-as',package,'test','-f','files/'+name],capture_output=True).returncode:return b''
 return run('exec-out','run-as',package,'cat','files/'+name)
def put(name,value):
 p=out/name;p.write_text(value,encoding='utf-8');run('push',str(p),'/data/local/tmp/lg-v4-qa');run('shell','run-as',pkg,'cp','/data/local/tmp/lg-v4-qa','files/'+name)
def stage(name):
 end=time.monotonic()+120;data={}
 while time.monotonic()<end:
  try:
   data=json.loads(read('phase4_qa_status.json'))
   if data['stage']==name:return data
  except (ValueError,KeyError):pass
  time.sleep(.25)
 raise RuntimeError('Missing '+name+' '+str(data))
end=time.monotonic()+120
while time.monotonic()<end:
 if run('shell','getprop','sys.boot_completed',check=False).strip()==b'1':break
 time.sleep(1)
assert run('shell','getprop','sys.boot_completed').strip()==b'1'
before={n:read(n,player) for n in ['planet.json','planet.json.bak','planet.json.tmp','settings.cfg']}
apk=r/'builds/android/LittleGod-V4B-preview-qa-debug.apk';assert b'Success' in run('install','--no-incremental','-r',str(apk));run('shell','am','force-stop',pkg);assert b'Success' in run('shell','pm','clear',pkg);run('shell','run-as',pkg,'mkdir','-p','files');put('phase4_qa.json',json.dumps({'phase':'warrior_v4','fps':a.fps}));run('logcat','-c')
(out/'startup.txt').write_bytes(run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher'))
d=stage('v4_move');w,h=map(int,re.findall(r'(\d+)x(\d+)',run('shell','wm','size').decode())[-1]);sx=w/d['viewport'][0];sy=h/d['viewport'][1];x,y=d['stick'];run('shell','input','swipe',str(round(x*sx)),str(round(y*sy)),str(round((x+80)*sx)),str(round(y*sy)),'3000');put('v4_move','continue')
for name in ['v4_attack','v4_dodge','v4_pause','v4_resume']:
 d=stage(name);x,y=d['touch'];run('shell','input','tap',str(round(x*sx)),str(round(y*sy)));time.sleep(.12);put(name,'continue');print(name,flush=True)
d=stage('v4_saved');(out/'result.json').write_text(json.dumps(d,indent=2),encoding='utf-8');assert d['all_passed'],d
for name in ['v4-combat.png','v4-walk.png']:(out/name).write_bytes(read(name))
run('shell','am','force-stop',pkg);put('phase4_qa.json',json.dumps({'phase':'warrior_v4_reopen','fps':a.fps}));run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher');restored=stage('v4_reopened');assert restored['all_passed'],restored
(out/'restored.json').write_text(json.dumps(restored,indent=2),encoding='utf-8');(out/'v4-restored.png').write_bytes(read('v4-restored.png'));(out/'memory.txt').write_bytes(run('shell','dumpsys','meminfo',pkg));logs=run('logcat','-d','-s','godot:V','AndroidRuntime:E');(out/'logcat.txt').write_bytes(logs)
errors=[line for line in logs.decode(errors='replace').splitlines() if ('SCRIPT ERROR' in line or 'FATAL EXCEPTION' in line or 'Parse Error' in line)];assert not errors,errors
run('shell','am','force-stop',pkg);assert all(read(n,player)==b for n,b in before.items())
report={'all_passed':True,'physical_device':False,'serial':'emulator-5554','fps_cap':a.fps,'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'native_checks':len(d['checks']),'restart_checks':len(restored['checks']),'player_files_unchanged':True,'metrics':d['metrics'],'player_before':{n:{'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()} for n,b in before.items()}}
(out/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report))
