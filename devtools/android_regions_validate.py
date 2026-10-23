"""Native ADB controls + real process restart. Clears only the isolated QA package."""
from pathlib import Path
import argparse,subprocess,json,time,re,hashlib
r=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--serial',default='emulator-5554');p.add_argument('--fps',type=int,choices=[30,60],default=60);a=p.parse_args()
out=r/f'builds/phase085e2/android-{a.serial}-{a.fps}';out.mkdir(parents=True,exist_ok=True)
adb=Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe';pkg='org.littlegod.livinguniverse.betaqa';player='org.littlegod.livinguniverse'
def run(*args,check=True):return subprocess.run([str(adb),'-s',a.serial,*args],capture_output=True,check=check,timeout=120).stdout
def read(name,package=pkg):
 if subprocess.run([str(adb),'-s',a.serial,'shell','run-as',package,'test','-f','files/'+name],capture_output=True).returncode:return b''
 return run('exec-out','run-as',package,'cat','files/'+name)
def put(name,data):
 f=out/name;f.write_bytes(data.encode());run('push',str(f),'/data/local/tmp/lg-region-qa');run('shell','run-as',pkg,'cp','/data/local/tmp/lg-region-qa','files/'+name)
def stage(name):
 d={}
 end=time.monotonic()+150
 while time.monotonic()<end:
  try:
   d=json.loads(read('phase4_qa_status.json'))
   if d['stage']==name:return d
  except (ValueError,KeyError):pass
  time.sleep(.4)
 raise RuntimeError('Missing '+name+' latest='+str(d))
names=['planet.json','planet.json.bak','planet.json.tmp','settings.cfg'];before={n:read(n,player) for n in names}
run('shell','am','force-stop',pkg);run('install','--no-incremental','-r',str(r/'builds/android/LittleGod-0.8.5-milestone-E2B-qa-debug.apk'))
assert b'Success' in run('shell','pm','clear',pkg);run('shell','run-as',pkg,'mkdir','-p','files')
put('phase4_qa.json',json.dumps({'phase':'regions','fps':a.fps}));run('logcat','-c')
(out/'startup.txt').write_bytes(run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher'))
d=stage('regions_card_touch');w,h=map(int,re.findall(r'(\d+)x(\d+)',run('shell','wm','size').decode())[-1]);sx=w/d['viewport'][0];sy=h/d['viewport'][1]
def tap(point):run('shell','input','tap',str(round(point[0]*sx)),str(round(point[1]*sy)));time.sleep(.35)
def action(stage_name,key,marker):
 d=stage(stage_name);tap(d[key]);put(marker,'continue');print(stage_name,flush=True)
tap(d['card']);put('regions_card','continue')
action('regions_entry_touch','entry','regions_entry')
d=stage('regions_move_touch');x,y=d['stick'];run('shell','input','swipe',str(round(x*sx)),str(round(y*sy)),str(round((x+80)*sx)),str(round(y*sy)),'900');put('regions_move','continue')
action('regions_stone_touch','inspect','regions_stone')
d=stage('regions_combat_touch')
for key in ['resume','attack','dodge','heal']:tap(d[key])
put('regions_combat','continue')
action('regions_ore_touch','inspect','regions_ore');action('regions_mine_touch','inspect','regions_mine')
d=stage('regions_complete');(out/'result.json').write_text(json.dumps(d,indent=2),encoding='utf-8');assert d['all_passed'],d
for name in ['android-regions-map','android-iron-entry','android-iron-warning','android-forgotten-mine-tr']:(out/(name+'.png')).write_bytes(read(name+'.png'))
run('shell','am','force-stop',pkg);put('phase4_qa.json',json.dumps({'phase':'regions_reopen','fps':a.fps}));run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher')
action('regions_home_touch','home','regions_home');d=stage('regions_reopened');(out/'reopen.json').write_text(json.dumps(d,indent=2),encoding='utf-8');assert d['all_passed'],d
(out/'android-iron-restored.png').write_bytes(read('android-iron-restored.png'))
(out/'memory.txt').write_bytes(run('shell','dumpsys','meminfo',pkg));(out/'logcat.txt').write_bytes(run('logcat','-d','-s','godot:V','AndroidRuntime:E'))
run('shell','am','force-stop',pkg)
assert all(read(n,player)==b for n,b in before.items())
proof={'serial':a.serial,'physical_device':not a.serial.startswith('emulator-'),'player_files_unchanged':True,'files':{n:{'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()} for n,b in before.items()}}
(out/'preservation.json').write_text(json.dumps(proof,indent=2));print('PASS',json.dumps(d),flush=True)
