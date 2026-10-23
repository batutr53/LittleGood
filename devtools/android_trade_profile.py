"""Compare hidden/visible planet rendering on the same emulator and shipped QA build."""
from pathlib import Path
import subprocess,json,time
r=Path(__file__).resolve().parents[1];out=r/'builds/phase085e1/profile-control';out.mkdir(parents=True,exist_ok=True)
adb=Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe';pkg='org.littlegod.livinguniverse.betaqa'
def run(*a):return subprocess.run([str(adb),'-s','emulator-5554',*a],capture_output=True,check=True,timeout=90).stdout
results=[]
for name,visible in [('hidden_A',False),('visible_control',True),('hidden_B',False)]:
 run('shell','am','force-stop',pkg);assert b'Success' in run('shell','pm','clear',pkg);run('shell','run-as',pkg,'mkdir','-p','files')
 flag=out/(name+'.json');flag.write_text(json.dumps({'phase':'trade_profile','render_planet':visible}),encoding='utf-8')
 run('push',str(flag),'/data/local/tmp/lg-profile');run('shell','run-as',pkg,'cp','/data/local/tmp/lg-profile','files/phase4_qa.json');run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher')
 end=time.monotonic()+90
 while time.monotonic()<end:
  try:
   d=json.loads(run('exec-out','run-as',pkg,'cat','files/phase4_qa_status.json'))
   if d.get('stage')=='trade_profile_complete':break
  except ValueError:pass
  time.sleep(.5)
 else:raise RuntimeError(name+' did not finish')
 assert d['valid'];d.update(sample=name,physical_device=False,serial='emulator-5554');results.append(d);print(name,d['fps'],d['draw_calls'],flush=True)
run('shell','am','force-stop',pkg);(out/'results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
