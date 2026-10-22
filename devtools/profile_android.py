"""Profile only LittleGod on a named ADB device, preserving its existing planet save."""
from pathlib import Path
import subprocess, json, time, hashlib, argparse
root=Path(__file__).resolve().parent.parent
parser=argparse.ArgumentParser()
parser.add_argument('--serial',default='emulator-5554')
parser.add_argument('--control',action='store_true')
parser.add_argument('--economy',action='store_true')
parser.add_argument('--stress',action='store_true')
parser.add_argument('--duration',type=float,default=30)
parser.add_argument('--output-dir',default='builds/phase3')
args=parser.parse_args()
adb=Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe'
base=[str(adb),'-s',args.serial]
pkg='org.littlegod.livinguniverse'
def run(*cmd,check=True):return subprocess.run(base+list(cmd),capture_output=True,check=check).stdout
run('shell','am','force-stop',pkg)
before=run('shell','run-as',pkg,'cat','files/planet.json',check=False)
options={'duration':args.duration,'economy':args.economy,'control':args.control,'stress':args.stress}
output=root/args.output_dir
output.mkdir(parents=True,exist_ok=True)
marker=output/'benchmark-options.json'
marker.write_text(json.dumps(options))
run('push',str(marker),'/data/local/tmp/littlegod-benchmark.json')
run('shell','run-as',pkg,'cp','/data/local/tmp/littlegod-benchmark.json','files/phase2_benchmark.json')
run('shell','run-as',pkg,'rm','-f','files/phase2_profile.json','files/phase2_profile.png')
started=time.monotonic()
run('shell','am','start','-n',pkg+'/com.godot.game.GodotAppLauncher')
report=None
while time.monotonic()-started < args.duration+120:
    result=run('shell','run-as',pkg,'cat','files/phase2_profile.json',check=False)
    try: report=json.loads(result)
    except Exception: time.sleep(1);continue
    break
if report is None:raise RuntimeError('No profile report after 150 seconds')
report['host_launch_to_report_seconds']=round(time.monotonic()-started,3)
after=run('shell','run-as',pkg,'cat','files/planet.json',check=False)
report['player_save_unchanged']=before==after
report['device_serial']=args.serial
kind='control' if args.control else 'economy' if args.economy else 'stress' if args.stress else 'smooth'
dest=output/f'android-{kind}'
dest.with_suffix('.json').write_text(json.dumps(report,indent=2))
for _ in range(10):
    data=run('exec-out','run-as',pkg,'cat','files/phase2_profile.png',check=False)
    if data.startswith(b'\x89PNG'):dest.with_suffix('.png').write_bytes(data);break
    time.sleep(.5)
print(json.dumps(report,indent=2))
if before!=after:raise RuntimeError('Player save changed during benchmark')
