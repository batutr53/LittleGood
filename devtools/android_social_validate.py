"""Isolated fresh-install QA using real ADB touch input; never clears the player package."""
from pathlib import Path
import subprocess, json, time, re, argparse

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('--serial', default='emulator-5554')
parser.add_argument('--export-dialog', action='store_true')
parser.add_argument('--apk',default='builds/android/LittleGod-0.8-qa-debug.apk')
parser.add_argument('--output-dir',default='builds/phase8/android-social')
args = parser.parse_args()
adb = Path.home() / 'AppData/Local/Android/Sdk/platform-tools/adb.exe'
pkg = 'org.littlegod.livinguniverse.betaqa'
base = [str(adb), '-s', args.serial]
out = root / args.output_dir
out.mkdir(parents=True, exist_ok=True)

def run(*cmd, check=True):
    return subprocess.run(base + list(cmd), capture_output=True, check=check).stdout

def private(name):
    return run('shell', 'run-as', pkg, 'cat', 'files/' + name, check=False)

def put(name, content):
    local = out / name
    local.write_text(content, encoding='utf-8')
    run('push', str(local), '/data/local/tmp/littlegod-qa-transfer')
    run('shell', 'run-as', pkg, 'cp', '/data/local/tmp/littlegod-qa-transfer', 'files/' + name)

def stage(expected):
    deadline = time.monotonic() + 45
    while time.monotonic() < deadline:
        try:
            data = json.loads(private('phase4_qa_status.json'))
            if data.get('stage') == expected:
                return data
        except (ValueError, TypeError):
            pass
        time.sleep(.3)
    raise RuntimeError('QA did not reach ' + expected)

def capture(name):
    (out / name).write_bytes(run('exec-out', 'screencap', '-p'))


import xml.etree.ElementTree as ET, hashlib

def nodes():
    run('shell','uiautomator','dump','/sdcard/littlegod-ui.xml')
    raw=run('shell','cat','/sdcard/littlegod-ui.xml')
    return list(ET.fromstring(raw).iter('node'))

def tap_text(text):
    for n in nodes():
        if n.get('text')==text and n.get('resource-id')!='com.google.android.documentsui:id/search_src_text' and n.get('class')!='android.widget.EditText':
            x1,y1,x2,y2=map(int,re.findall(r'\d+',n.get('bounds')))
            run('shell','input','tap',str((x1+x2)//2),str((y1+y2)//2))
            return True
    return False

run('wait-for-device')
run('shell','am','force-stop',pkg)
run('install','-r',str(root/args.apk))
run('shell','run-as',pkg,'rm','-f','files/phase6_qa_import')
put('phase4_qa.json',json.dumps({'phase':'social_dialogs'}))
run('shell','am','start','-n',pkg+'/com.godot.game.GodotAppLauncher')
ready=stage('json_dialog_ready')
time.sleep(1)
# Navigate using the real Android accessibility tree, not guessed coordinates.
if tap_text('Download'): time.sleep(.5)
capture('native-json-save.png')
assert tap_text('SAVE'), 'Native Save button missing'
time.sleep(2)
file_path='/sdcard/Download/'+ready['filename']
exported=run('shell','cat',file_path,check=False)
public=json.loads(exported)
assert public['format']=='littlegod.showcase' and public['planet']['name']=='PickerQA'
capture('export-complete.png')
put('phase6_qa_import','import')
stage('import_dialog_ready');time.sleep(1)
if tap_text('Download'): time.sleep(.5)
capture('native-json-open.png')
selected=False
for attempt in range(12):
    if tap_text(ready['filename']):selected=True;break
    scrolls=[n for n in nodes() if n.get('scrollable')=='true']
    if not scrolls:break
    x1,y1,x2,y2=map(int,re.findall(r'\d+',scrolls[0].get('bounds')))
    run('shell','input','swipe',str((x1+x2)//2),str(round(y1+(y2-y1)*.75)),str((x1+x2)//2),str(round(y1+(y2-y1)*.25)),'350')
    time.sleep(.4)
assert selected, 'Exported showcase missing from native Open picker'
complete=stage('social_dialogs_complete')
capture('import-profile.png')
report={'source':'simulated_android_qa','serial':args.serial,'package':pkg,
        'checks':{'native_json_export':True,'native_json_import':complete['checks']['native_json_import'],
                  'source_file_unchanged':run('shell','cat',file_path)==exported},
        'exported_bytes':len(exported),'sha256':hashlib.sha256(exported).hexdigest()}
report['all_passed']=all(report['checks'].values())
(out/'result.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
assert report['all_passed']
