from pathlib import Path
import subprocess,json,time
r=Path(__file__).resolve().parents[1];out=r/'builds/visual-v4';adb=Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe';pkg='org.littlegod.livinguniverse.v4preview'
def run(*args):return subprocess.check_output([str(adb),'-s','emulator-5554',*args],timeout=120)
run('shell','am','force-stop',pkg);run('install','--no-incremental','-r',str(r/'builds/android/LittleGod-V4B-preview-qa-debug.apk'))
results=[]
for preview in [False,True]:
 run('shell','am','force-stop',pkg);run('shell','pm','clear',pkg);run('shell','run-as',pkg,'mkdir','-p','files');p=out/'profile-options.json';p.write_text(json.dumps({'phase':'warrior_v4_profile','fps':60,'preview':preview}));run('push',str(p),'/data/local/tmp/lg-v4-profile');run('shell','run-as',pkg,'cp','/data/local/tmp/lg-v4-profile','files/phase4_qa.json');run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher');end=time.monotonic()+120
 while time.monotonic()<end:
  data=subprocess.run([str(adb),'-s','emulator-5554','exec-out','run-as',pkg,'cat','files/phase4_qa_status.json'],capture_output=True,timeout=30).stdout
  try:
   result=json.loads(data)
   if result['stage']=='v4_profile':results.append(result);print(json.dumps(result),flush=True);break
  except (ValueError,KeyError):pass
  time.sleep(.4)
 else:raise RuntimeError('Profile timeout')
run('shell','am','force-stop',pkg);(out/'android-comparison.json').write_text(json.dumps(results,indent=2))
