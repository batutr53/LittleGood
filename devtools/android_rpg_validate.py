"""Actual emulator install/start/render QA. Model navigation is programmatic, not native touch."""
from pathlib import Path
import subprocess,json,time,hashlib,uuid
r=Path(__file__).resolve().parents[1];out=r/'builds/rpg-android';out.mkdir(exist_ok=True)
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
run('shell','am','force-stop',pkg);run('install','--no-incremental','-r',str(r/'builds/android/LittleGod-RPG-interface-qa-debug.apk'));run('shell','run-as',pkg,'mkdir','-p','files')
put('rpg-fixture.json',r/'tests/fixtures/planet-v085e2.json')
run_id=uuid.uuid4().hex
config=out/'phase4_qa.json';config.write_text(json.dumps({'phase':'rpg','run_id':run_id}));put('phase4_qa.json',config)
startup=run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher').decode();(out/'startup.txt').write_text(startup)
deadline=time.monotonic()+100
while time.monotonic()<deadline:
    try:
        result=json.loads(read('phase4_qa_status.json'))
        if result.get('stage')=='rpg_complete' and result.get('run_id')==run_id:break
    except ValueError:pass
    time.sleep(.5)
else:raise RuntimeError('Android RPG QA timed out')
result['physical_device']=False
after={name:read(name,player) for name in names}
result['player_files_preserved']=all(before[name]==after[name] for name in names)
result['player_file_hashes']={name:{'before':hashlib.sha256(before[name]).hexdigest(),'after':hashlib.sha256(after[name]).hexdigest(),'before_bytes':len(before[name]),'after_bytes':len(after[name])} for name in names}
for name in ['rpg-android-home','rpg-android-inventory','rpg-android-mage','rpg-android-adventure']:
    image=read(name+'.png');(r/'docs/screenshots/rpg'/f'{name}.png').write_bytes(image)
(out/'logcat.txt').write_bytes(run('logcat','-d','--pid='+str(result['pid']),'-s','godot:V','AndroidRuntime:E'))
(out/'result.json').write_text(json.dumps(result,indent=2),encoding='utf8');print(json.dumps(result,indent=2));assert result['all_passed'] and result['player_files_preserved']
