"""Isolated fresh-install QA using real ADB touch input; never clears the player package."""
from pathlib import Path
import subprocess, json, time, re, argparse

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('--serial', default='emulator-5554')
parser.add_argument('--export-dialog', action='store_true')
args = parser.parse_args()
adb = Path.home() / 'AppData/Local/Android/Sdk/platform-tools/adb.exe'
pkg = 'org.littlegod.livinguniverse.betaqa'
base = [str(adb), '-s', args.serial]
out = root / 'builds/phase8/android-qa'
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

# This ID is reserved for this QA harness and has no player release data.
run('uninstall', pkg, check=False)
run('install', str(root / 'builds/android/LittleGod-0.8-qa-debug.apk'))
# Android may restore app data after reinstall. Clear only the disposable QA ID
# so this scenario is truly blank; never issue pm clear for the player package.
if b'Success' not in run('shell', 'pm', 'clear', pkg):
    raise RuntimeError('Could not reset isolated QA storage')
run('shell', 'am', 'start', '-n', pkg + '/com.godot.game.GodotAppLauncher')
time.sleep(2)
run('shell', 'am', 'force-stop', pkg)
put('phase4_qa.json', json.dumps({'phase': 'new'}))
run('shell', 'am', 'start', '-n', pkg + '/com.godot.game.GodotAppLauncher')
ready = stage('touch_ready')
size = run('shell', 'wm', 'size').decode()
width, height = map(int, re.findall(r'(\d+)x(\d+)', size)[-1])
sx, sy = width / ready['viewport'][0], height / ready['viewport'][1]

def xy(p): return str(round(p[0] * sx)), str(round(p[1] * sy))
run('shell', 'input', 'tap', *xy(ready['plus']))
time.sleep(.5)
run('shell', 'input', 'swipe', *xy(ready['drag'][0]), *xy(ready['drag'][1]), '400')
run('shell', 'input', 'tap', *xy(ready['rain']))
run('shell', 'input', 'tap', *xy(ready['world']))
time.sleep(1)
capture('new-world.png')
put('phase4_qa_continue', 'continue')
first = stage('ready_to_restart')
run('shell', 'input', 'keyevent', 'KEYCODE_HOME')
run('shell', 'am', 'force-stop', pkg)
put('phase4_qa.json', json.dumps({'phase': 'reopen', 'export': args.export_dialog}))
run('shell', 'am', 'start', '-n', pkg + '/com.godot.game.GodotAppLauncher')
second = stage('complete')
capture('reopened.png')
run('shell', 'input', 'keyevent', 'KEYCODE_BACK')
time.sleep(.4)
put('phase5_qa_back', 'back')
third = stage('back_complete')
capture('postcard.png')
if args.export_dialog:
    put('phase5_qa_export', 'export')
    time.sleep(2)
    capture('native-save-dialog.png')
checks = first['checks'] | third['checks']
report = {'source': 'simulated_android_qa', 'serial': args.serial, 'package': pkg,
          'fresh_install': True, 'handler_to_frame_ms': first.get('handler_to_frame_ms'), 'checks': checks, 'all_passed': all(checks.values())}
(out / 'result.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
if not report['all_passed']:
    raise RuntimeError('Android QA check failed')
