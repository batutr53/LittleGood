"""Milestone A: upgrade player package without clearing saves; isolated real Android UI QA."""
from pathlib import Path
import argparse,hashlib,json,re,subprocess,time
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--phase',default='industry',choices=['kingdom','industry']);parser.add_argument('--output-dir',default='builds/phase09/android-industry');args=parser.parse_args()
out=root/args.output_dir;out.mkdir(parents=True,exist_ok=True)
adb=Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe'
player='org.littlegod.livinguniverse';pkg=player+'.betaqa'
def run(*args,check=True):
 return subprocess.run([str(adb),'-s','emulator-5554',*args],capture_output=True,check=check,timeout=90).stdout
def read(name,package=pkg):
 present=subprocess.run([str(adb),'-s','emulator-5554','shell','run-as',package,'test','-f','files/'+name],capture_output=True,timeout=90)
 if present.returncode!=0:return b''
 result=subprocess.run([str(adb),'-s','emulator-5554','exec-out','run-as',package,'cat','files/'+name],capture_output=True,timeout=90)
 return result.stdout if result.returncode==0 else b''
def put(name,value,package=pkg):
 path=out/name;path.write_bytes(value if isinstance(value,bytes) else value.encode('utf-8'))
 run('push',str(path),'/data/local/tmp/littlegod-kingdom-qa')
 run('shell','run-as',package,'cp','/data/local/tmp/littlegod-kingdom-qa','files/'+name)
def stage(expected):
 deadline=time.monotonic()+180
 while time.monotonic()<deadline:
  try:
   data=json.loads(read('phase4_qa_status.json'))
   if data.get('stage')==expected:return data
  except (ValueError,TypeError):pass
  time.sleep(.5)
 raise RuntimeError('Missing kingdom QA stage '+expected)
run('wait-for-device')
run('shell','am','force-stop',player)
names=['planet.json','planet.json.bak','planet.json.tmp','settings.cfg']
before={name:read(name,player) for name in names}
run('install','-r',str(root/'builds/android/LittleGod-0.8.5-milestone-B-debug.apk'))
assert all(read(name,player)==value for name,value in before.items()),'Player save changed during upgrade'
run('shell','am','force-stop',pkg)
run('install','-r',str(root/'builds/android/LittleGod-0.8.5-milestone-B-qa-debug.apk'))
assert b'Success' in run('shell','pm','clear',pkg) # Explicitly disposable package only.
run('shell','run-as',pkg,'mkdir','-p','files')
put('phase4_qa.json',json.dumps({'phase':args.phase}))
run('logcat','-c')
started=time.monotonic();run('shell','am','start','-n',pkg+'/com.godot.game.GodotAppLauncher')
ready=stage(args.phase+'_touch_ready')
w,h=map(int,re.findall(r'(\d+)x(\d+)',run('shell','wm','size').decode())[-1])
sx=w/ready['viewport'][0];sy=h/ready['viewport'][1]
def tap(point):run('shell','input','tap',str(round(point[0]*sx)),str(round(point[1]*sy)))
if args.phase=='kingdom':
 tap(ready['target']);time.sleep(.5)
 (out/'adb-placement.png').write_bytes(run('exec-out','screencap','-p'))
 tap(ready['confirm']);time.sleep(.5);put('phase085_touch_continue','continue')
else:
 (out/'adb-compare.png').write_bytes(run('exec-out','screencap','-p'))
 tap(ready['unequip']);time.sleep(.4);put('industry_unequipped','continue')
 ready=stage('industry_equip_ready');tap(ready['equip']);time.sleep(.4);put('industry_equipped','continue')
result=stage(args.phase+'_complete')
result.update(source='real_android_render_ui_and_external_adb_'+args.phase+'_taps',serial='emulator-5554',physical_device=False,wall_seconds=round(time.monotonic()-started,2),player_upgrade_preserved_files={k:{'bytes':len(v),'sha256':hashlib.sha256(v).hexdigest(),'present_and_nonempty':bool(v)} for k,v in before.items()})
(out/'result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
images=['advisor-intro','quest-01','gather-preview','building-preview','construction','working-camp','workers','first-village','chapter-complete','buildings','kingdom-tr'] if args.phase=='kingdom' else ['iron-village','workshop','craft-queue','inventory','compare-tool','equipped-village','iron-chapter-complete','workshop-tr','inventory-tr']
for name in images:
 data=read(name+'.png');assert data.startswith(b'\x89PNG'),name;(out/(name+'.png')).write_bytes(data)
fixture=read('beta-qa-world.json');assert json.loads(fixture)
put('phase085_profile_world.json',fixture,player)
(out/'memory.txt').write_bytes(run('shell','dumpsys','meminfo',pkg))
(out/'logcat.txt').write_bytes(run('logcat','-d','-s','godot:V','AndroidRuntime:E'))
run('shell','am','force-stop',pkg)
print(json.dumps(result,indent=2));assert result['all_passed']
