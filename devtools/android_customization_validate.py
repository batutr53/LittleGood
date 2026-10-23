"""Real emulator rendering plus external ADB decoration taps; disposable QA package only."""
from pathlib import Path
import subprocess,json,time,re
root=Path(__file__).resolve().parents[1]
out=root/'builds/phase8/android-customization';out.mkdir(parents=True,exist_ok=True)
adb=Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe'
pkg='org.littlegod.livinguniverse.betaqa'
def run(*args,check=True):return subprocess.run([str(adb),'-s','emulator-5554',*args],capture_output=True,check=check,timeout=60).stdout
def read(name):return run('exec-out','run-as',pkg,'cat','files/'+name,check=False)
def put(name,value):
 p=out/name;p.write_text(value,encoding='utf-8');run('push',str(p),'/data/local/tmp/littlegod-customization-qa');run('shell','run-as',pkg,'cp','/data/local/tmp/littlegod-customization-qa','files/'+name)
def stage(name):
 start=time.monotonic()
 while time.monotonic()-start<150:
  try:
   data=json.loads(read('phase4_qa_status.json'))
   if data.get('stage')==name:return data
  except (ValueError,TypeError):pass
  time.sleep(.5)
 raise RuntimeError('Missing QA stage '+name)
run('wait-for-device');run('shell','am','force-stop',pkg)
run('install','-r',str(root/'builds/android/LittleGod-0.8-qa-debug.apk'))
assert b'Success' in run('shell','pm','clear',pkg)
run('shell','run-as',pkg,'mkdir','-p','files')
put('phase4_qa.json',json.dumps({'phase':'customization'}));started=time.monotonic();run('shell','am','start','-n',pkg+'/com.godot.game.GodotAppLauncher')
ready=stage('customization_touch_ready')
w,h=map(int,re.findall(r'(\d+)x(\d+)',run('shell','wm','size').decode())[-1]);sx=w/ready['viewport'][0];sy=h/ready['viewport'][1]
def tap(pos):run('shell','input','tap',str(round(pos[0]*sx)),str(round(pos[1]*sy)))
tap(ready['tile']);time.sleep(.5);(out/'adb-preview.png').write_bytes(run('exec-out','screencap','-p'));tap(ready['place']);time.sleep(.5);put('phase8_touch_continue','continue')
result=stage('customization_complete');result['source']='real_android_render_and_external_adb_taps';result['serial']='emulator-5554';result['wall_seconds']=round(time.monotonic()-started,2)
(out/'result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
for name in ['theme-enchanted.png','theme-crystal.png','theme-celestial.png','theme-ancient.png','shop.png','item.png','editor.png','creature-wardrobe.png','visit.png','collection-tr.png','customized.lgplanet']:
 data=read(name);assert data and (not name.endswith('.png') or data.startswith(b'\x89PNG')),name;(out/name).write_bytes(data)
(out/'memory.txt').write_bytes(run('shell','dumpsys','meminfo',pkg))
run('shell','am','force-stop',pkg)
print(json.dumps(result,indent=2));assert result['all_passed']
