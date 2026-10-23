"""Validate the player APK signature/update/startup without writing the player's world."""
from pathlib import Path
import subprocess,json,os,time,hashlib,argparse
p=argparse.ArgumentParser();p.add_argument('--milestone',choices=['E2B','E2'],default='E2B');a=p.parse_args()
r=Path(__file__).resolve().parents[1];out=r/('builds/phase085e2full/player-install' if a.milestone=='E2' else 'builds/phase085e2/player-install');out.mkdir(parents=True,exist_ok=True)
adb=Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe';pkg='org.littlegod.livinguniverse'
def run(*args,check=True):return subprocess.run([str(adb),'-s','emulator-5554',*args],capture_output=True,check=check,timeout=120).stdout
def read(name):
 if subprocess.run([str(adb),'-s','emulator-5554','shell','run-as',pkg,'test','-f','files/'+name],capture_output=True).returncode:return b''
 return run('exec-out','run-as',pkg,'cat','files/'+name)
def put(name,data):
 f=out/name;f.write_bytes(data);run('push',str(f),'/data/local/tmp/lg-player-check');run('shell','run-as',pkg,'cp','/data/local/tmp/lg-player-check','files/'+name)
apk=r/('builds/android/LittleGod-0.8.5-milestone-'+a.milestone+'-debug.apk');version='0.8.5-dev'+a.milestone
env=os.environ.copy();env['JAVA_HOME']=str(r/'tools/jdk/jdk-17.0.20.1+1')
signer=Path.home()/'AppData/Local/Android/Sdk/build-tools/36.0.0/apksigner.bat'
v=subprocess.run([str(signer),'verify','--verbose',str(apk)],capture_output=True,env=env,timeout=60);(out/'signature.txt').write_bytes(v.stdout+v.stderr);assert v.returncode==0
run('shell','am','force-stop',pkg)
names=['planet.json','planet.json.bak','planet.json.tmp','settings.cfg'];before={n:read(n) for n in names};marker=read('phase2_benchmark.json')
(out/'install.txt').write_bytes(run('install','--no-incremental','-r',str(apk)));assert all(read(n)==b for n,b in before.items())
run('shell','run-as',pkg,'mkdir','-p','files');put('phase2_benchmark.json',b'{"duration":3600}')
try:
 (out/'startup.txt').write_bytes(run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher'))
 time.sleep(3);pid=run('shell','pidof',pkg).decode().strip();assert pid
 (out/'startup.png').write_bytes(run('exec-out','screencap','-p'))
 (out/'logcat.txt').write_bytes(run('logcat','-d','--pid',pid,'-s','godot:V','AndroidRuntime:E'))
 (out/'package.txt').write_bytes(run('shell','dumpsys','package',pkg))
 assert ('versionName='+version).encode() in (out/'package.txt').read_bytes()
finally:
 run('shell','am','force-stop',pkg)
 if marker:put('phase2_benchmark.json',marker)
 else:run('shell','run-as',pkg,'rm','-f','files/phase2_benchmark.json')
assert all(read(n)==b for n,b in before.items())
report={'serial':'emulator-5554','physical_device':False,'signature_verified':True,'installed':True,'started_private_benchmark':True,'version':version,'player_files_preserved':{n:{'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()} for n,b in before.items()}}
(out/'result.json').write_text(json.dumps(report,indent=2));print('PLAYER_UPDATE_STARTUP_PRESERVED',json.dumps(report))
