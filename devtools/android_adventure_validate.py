"""Isolated Android adventure UI/profile run; never clear the player package."""
from pathlib import Path
import hashlib,json,re,subprocess,time,os
root=Path(__file__).resolve().parents[1];out=root/'builds/phase085c/android';out.mkdir(parents=True,exist_ok=True)
adb=Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe';player='org.littlegod.livinguniverse';pkg=player+'.betaqa'
def run(*args,check=True):return subprocess.run([str(adb),'-s','emulator-5554',*args],capture_output=True,check=check,timeout=90).stdout
def read(name,package=pkg):
 if subprocess.run([str(adb),'-s','emulator-5554','shell','run-as',package,'test','-f','files/'+name],capture_output=True).returncode:return b''
 return run('exec-out','run-as',package,'cat','files/'+name)
def put(name,data,package=pkg):
 path=out/name;path.write_bytes(data if isinstance(data,bytes) else data.encode());run('push',str(path),'/data/local/tmp/littlegod-adventure-qa');run('shell','run-as',package,'cp','/data/local/tmp/littlegod-adventure-qa','files/'+name)
def stage(expected):
 end=time.monotonic()+240
 while time.monotonic()<end:
  try:
   d=json.loads(read('phase4_qa_status.json'))
   if d.get('stage')==expected:return d
  except (ValueError,TypeError):pass
  time.sleep(.5)
 raise RuntimeError('Missing stage '+expected)
run('wait-for-device');run('shell','am','force-stop',player)
names=['planet.json','planet.json.bak','planet.json.tmp','settings.cfg'];before={n:read(n,player) for n in names}
run('install','--no-incremental','-r',str(root/'builds/android/LittleGod-0.8.5-milestone-C-debug.apk'))
assert all(read(n,player)==b for n,b in before.items())
put('phase2_benchmark.json',json.dumps({'duration':3600}),player)
startup=run('shell','am','start','-W','-n',player+'/com.godot.game.GodotAppLauncher').decode();(out/'player-startup.txt').write_text(startup)
time.sleep(3);assert run('shell','pidof',player).strip();(out/'player-startup.png').write_bytes(run('exec-out','screencap','-p'));run('shell','am','force-stop',player)
assert all(read(n,player)==b for n,b in before.items()),'Player save/settings changed'
run('shell','am','force-stop',pkg)
run('install','--no-incremental','-r',str(root/'builds/android/LittleGod-0.8.5-milestone-C-qa-debug.apk'))
assert b'Success' in run('shell','pm','clear',pkg)
run('shell','run-as',pkg,'mkdir','-p','files');put('phase4_qa.json',json.dumps({'phase':'adventure'}));run('logcat','-c');started=time.monotonic()
run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher');ready=stage('adventure_move_ready')
w,h=map(int,re.findall(r'(\d+)x(\d+)',run('shell','wm','size').decode())[-1]);sx=w/ready['viewport'][0];sy=h/ready['viewport'][1]
def xy(p):return [str(round(p[0]*sx)),str(round(p[1]*sy))]
def tap(p):run('shell','input','tap',*xy(p));time.sleep(.2)
p=ready['stick'];time.sleep(1)
for _ in range(3):run('shell','input','swipe',*xy(p),*xy([p[0]+65,p[1]]),'1400');time.sleep(.7)
put('adventure_moved','continue');print('Android joystick sent',flush=True)
ready=stage('adventure_combat_ready');(out/'adb-before-combat.png').write_bytes(run('exec-out','screencap','-p'))
for key in ['resume','attack','skill','dodge','heal','interact']:tap(ready[key])
(out/'adb-attacks.png').write_bytes(run('exec-out','screencap','-p'));put('adventure_attacked','continue');print('Android combat taps sent',flush=True)
result=stage('adventure_complete');result.update(serial='emulator-5554',physical_device=False,wall_seconds=round(time.monotonic()-started,2),player_files_preserved={n:{'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),'present':bool(b)} for n,b in before.items()})
for name in ['android-thornheart-ready','android-thornheart-warning','android-thornheart-phase2','android-thornheart-victory','android-hero-profile','android-chapter3-tr']:
 data=read(name+'.png');assert data.startswith(b'\x89PNG'),name;(out/(name+'.png')).write_bytes(data)
(out/'result.json').write_text(json.dumps(result,indent=2),encoding='utf-8');(out/'logcat.txt').write_bytes(run('logcat','-d','-s','godot:V','AndroidRuntime:E'));(out/'memory.txt').write_bytes(run('shell','dumpsys','meminfo',pkg));(out/'qa-save.json').write_bytes(read('beta-qa-world.json'))
assert all(read(n,player)==b for n,b in before.items());run('shell','am','force-stop',pkg);assert result['all_passed'],result
fixture=Path(os.environ['APPDATA'])/'Godot/app_userdata/LittleGod — Your Living Universe/exploration.json'
assert json.loads(fixture.read_text(encoding='utf-8'))
put('beta-qa-world.json',fixture.read_bytes());put('phase4_qa.json',json.dumps({'phase':'adventure_reopen'}));run('shell','run-as',pkg,'rm','-f','files/phase4_qa_status.json')
run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher');resumed=stage('adventure_reopened');(out/'resume-result.json').write_text(json.dumps(resumed,indent=2),encoding='utf-8');(out/'android-adventure-resumed.png').write_bytes(read('android-adventure-resumed.png'))
run('shell','am','force-stop',pkg);assert resumed['all_passed'],resumed;print(json.dumps(result,indent=2));print('REAL_ANDROID_REOPEN',json.dumps(resumed))
