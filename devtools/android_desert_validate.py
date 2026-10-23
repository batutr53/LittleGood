"""External native controls, live poison process restart, actual quest22 claim. QA only."""
from pathlib import Path
import json,subprocess,time,re,argparse,hashlib
r=Path(__file__).resolve().parents[1];p=argparse.ArgumentParser();p.add_argument('--fps',type=int,choices=[30,60],default=60);a=p.parse_args()
out=r/f'builds/phase085e2full/android-{a.fps}';out.mkdir(parents=True,exist_ok=True)
adb=Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe';pkg='org.littlegod.livinguniverse.betaqa';player='org.littlegod.livinguniverse'
def run(*args,check=True):return subprocess.run([str(adb),'-s','emulator-5554',*args],capture_output=True,check=check,timeout=120).stdout
def read(name,package=pkg):
 if subprocess.run([str(adb),'-s','emulator-5554','shell','run-as',package,'test','-f','files/'+name],capture_output=True).returncode:return b''
 return run('exec-out','run-as',package,'cat','files/'+name)
def put(name,data):
 f=out/name;f.write_text(data,encoding='utf-8');run('push',str(f),'/data/local/tmp/lg-desert-qa');run('shell','run-as',pkg,'cp','/data/local/tmp/lg-desert-qa','files/'+name)
def stage(name):
 end=time.monotonic()+180;d={}
 while time.monotonic()<end:
  try:
   d=json.loads(read('phase4_qa_status.json'))
   if d['stage']==name:return d
  except (ValueError,KeyError):pass
  time.sleep(.4)
 raise RuntimeError('Missing '+name+' '+str(d))
before={n:read(n,player) for n in ['planet.json','planet.json.bak','planet.json.tmp','settings.cfg']}
run('shell','am','force-stop',pkg);run('install','--no-incremental','-r',str(r/'builds/android/LittleGod-0.8.5-milestone-E2-qa-debug.apk'));assert b'Success' in run('shell','pm','clear',pkg)
run('shell','run-as',pkg,'mkdir','-p','files');put('phase4_qa.json',json.dumps({'phase':'desert','fps':a.fps}));run('logcat','-c')
(out/'startup.txt').write_bytes(run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher'));d=stage('desert_card_touch')
w,h=map(int,re.findall(r'(\d+)x(\d+)',run('shell','wm','size').decode())[-1]);sx=w/d['viewport'][0];sy=h/d['viewport'][1]
def tap(point):run('shell','input','tap',str(round(point[0]*sx)),str(round(point[1]*sy)));time.sleep(.35)
def action(name,key,marker):
 d=stage(name);tap(d[key]);put(marker,'continue');print(name,flush=True)
tap(d['card']);put('desert_card','continue');action('desert_entry_touch','entry','desert_entry')
d=stage('desert_move_touch');x,y=d['stick'];run('shell','input','swipe',str(round(x*sx)),str(round(y*sy)),str(round((x+80)*sx)),str(round(y*sy)),'900');put('desert_move','continue')
action('desert_oasis_touch','inspect','desert_oasis');d=stage('desert_poison_saved');(out/'before-restart.json').write_text(json.dumps(d,indent=2));assert d['all_passed'],d
for name in ['android-desert-map','android-desert-entry','android-oasis-discovery','android-scorpion-warning','android-desert-poison']:(out/(name+'.png')).write_bytes(read(name+'.png'))
run('shell','am','force-stop',pkg);put('phase4_qa.json',json.dumps({'phase':'desert_reopen','fps':a.fps}));run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher')
d=stage('desert_combat_touch')
for key in ['resume','attack','dodge','heal']:tap(d[key])
put('desert_combat','continue');action('desert_crystal_touch','inspect','desert_crystal');action('desert_home_touch','home','desert_home');action('desert_register_touch','register','desert_register');action('desert_claim_touch','claim','desert_claim')
d=stage('desert_complete');(out/'result.json').write_text(json.dumps(d,indent=2),encoding='utf-8');assert d['all_passed'],d
for name in ['android-desert-restored','android-desert-crystal','android-quest22-complete-tr']:(out/(name+'.png')).write_bytes(read(name+'.png'))
(out/'memory.txt').write_bytes(run('shell','dumpsys','meminfo',pkg));(out/'logcat.txt').write_bytes(run('logcat','-d','-s','godot:V','AndroidRuntime:E'));run('shell','am','force-stop',pkg)
assert all(read(n,player)==b for n,b in before.items())
proof={'serial':'emulator-5554','physical_device':False,'player_files_unchanged':True,'files':{n:{'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()} for n,b in before.items()}}
(out/'preservation.json').write_text(json.dumps(proof,indent=2));print('PASS',json.dumps(d))
