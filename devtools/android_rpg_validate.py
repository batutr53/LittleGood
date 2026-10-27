"""Actual emulator install/start/render QA. Model navigation is programmatic, not native touch."""
from pathlib import Path
import subprocess,json,time,hashlib,uuid,argparse,re
parser=argparse.ArgumentParser();parser.add_argument('--apk',default='LittleGod-RPG-interface-qa-debug.apk');parser.add_argument('--output',default='rpg-android');parser.add_argument('--screenshots',default='rpg');parser.add_argument('--phase',choices=['rpg','estate','armory','playbook','targeting','battle','colony'],default='rpg');args=parser.parse_args()
assert all(Path(v).name==v for v in [args.apk,args.output,args.screenshots])
r=Path(__file__).resolve().parents[1];out=r/'builds'/args.output;out.mkdir(exist_ok=True)
(r/'docs/screenshots'/args.screenshots).mkdir(parents=True,exist_ok=True)
adb=Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe';pkg='org.littlegod.livinguniverse.rpgqa';player='org.littlegod.livinguniverse'
def run(*args,check=True):return subprocess.run([str(adb),'-s','emulator-5554',*args],capture_output=True,check=check,timeout=120).stdout
def read(name,package=pkg):
    # A failed ADB probe is not evidence of an absent save. Read atomically and
    # require two identical observations before comparing player data.
    assert name.replace('.','').replace('-','').replace('_','').isalnum()
    command="if [ -f files/"+name+" ]; then printf 'PRESENT\\n'; cat files/"+name+"; else printf 'ABSENT\\n'; fi"
    previous=None
    for attempt in range(6):
        probe=subprocess.run([str(adb),'-s','emulator-5554','exec-out','run-as',package,'sh','-c',command],capture_output=True,timeout=20)
        data=probe.stdout
        if probe.returncode==0 and (data.startswith(b'PRESENT\n') or data==b'ABSENT\n'):
            if data==previous:return data[8:] if data.startswith(b'PRESENT\n') else b''
            previous=data
        else:previous=None
        time.sleep(.15)
    raise RuntimeError('Could not obtain a stable file snapshot: '+package+'/'+name)
def put(name,source):
    run('push',str(source),'/data/local/tmp/littlegod-rpg-qa');run('shell','run-as',pkg,'cp','/data/local/tmp/littlegod-rpg-qa','files/'+name)
names=['planet.json','planet.json.bak','settings.cfg'];before={name:read(name,player) for name in names}
run('shell','am','force-stop',pkg);run('install','--no-incremental','-r',str(r/'builds/android'/args.apk));run('shell','run-as',pkg,'mkdir','-p','files')
put('rpg-fixture.json',r/'tests/fixtures/planet-v085e2.json')
run_id=uuid.uuid4().hex
config=out/'phase4_qa.json';config.write_text(json.dumps({'phase':args.phase,'run_id':run_id}));put('phase4_qa.json',config)
startup=run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher').decode();(out/'startup.txt').write_text(startup)
deadline=time.monotonic()+100
close_sent=False
while time.monotonic()<deadline:
    try:
        result=json.loads(read('phase4_qa_status.json'))
        if args.phase=='colony' and result.get('stage')=='colony_close_ready' and result.get('run_id')==run_id and not close_sent:
            dimensions=re.findall(r'(\d+)x(\d+)',run('shell','wm','size').decode())[-1]
            width,height=map(int,dimensions);vx,vy=result['viewport'];x,y=result['close_point']
            # wm reports the device's natural portrait size even after landscape rotation.
            if (width>height)!=(vx>vy):width,height=height,width
            run('shell','input','tap',str(round(x*width/vx)),str(round(y*height/vy)));close_sent=True
        if result.get('stage')==args.phase+'_complete' and result.get('run_id')==run_id:break
    except ValueError:pass
    time.sleep(.5)
else:raise RuntimeError('Android RPG QA timed out')
result['physical_device']=False
after={name:read(name,player) for name in names}
result['player_files_preserved']=all(before[name]==after[name] for name in names)
result['player_file_hashes']={name:{'before':hashlib.sha256(before[name]).hexdigest(),'after':hashlib.sha256(after[name]).hexdigest(),'before_bytes':len(before[name]),'after_bytes':len(after[name])} for name in names}
images=['rpg-android-home','rpg-android-inventory','rpg-android-mage','rpg-android-adventure'] if args.phase=='rpg' else ['estate-android-village','estate-android-harvest','estate-android-panel','estate-android-world']
if args.phase=='armory':images=['armory-android-inventory','armory-android-anvil','armory-android-bestiary','armory-android-contracts','armory-android-spell','armory-android-sets']
if args.phase=='playbook':images=['playbook-android-'+name for name in ['quest','guide','workers','construction','army','map','menu','army_roster','placement']]
if args.phase=='targeting':images=['targeting-android-'+name for name in ['building','item','enemy','warning']]
if args.phase=='battle':images=['battle-android-'+name for name in ['counterattack','kill','pickup','healing','hunts']]
if args.phase=='colony':images=['colony-android-'+name for name in ['colony','workers','resources','defense','cargo','world']]
for name in images:
    image=read(name+'.png');(r/'docs/screenshots'/args.screenshots/f'{name}.png').write_bytes(image)
logs=run('logcat','-d','--pid='+str(result['pid']),'-s','godot:V','AndroidRuntime:E')
(out/'logcat.txt').write_bytes(logs)
result['script_errors']=[line for line in logs.decode('utf8',errors='replace').splitlines() if 'SCRIPT ERROR:' in line or 'FATAL EXCEPTION' in line]
(out/'result.json').write_text(json.dumps(result,indent=2),encoding='utf8');print(json.dumps(result,indent=2));assert result['all_passed'] and result['player_files_preserved'] and not result['script_errors']
run('shell','run-as',pkg,'rm','-f','files/phase4_qa.json')
