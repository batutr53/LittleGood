"""Native ADB first-day adventure/city QA, preserving both packages' player files."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
import time
import uuid

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--apk', default='LittleGod-Entry-QA-debug.apk')
parser.add_argument('--output', default='entry-android')
parser.add_argument('--endpoint', default='http://127.0.0.1:5087')
args = parser.parse_args()
assert Path(args.apk).name == args.apk and Path(args.output).name == args.output
out = root / 'builds' / args.output
out.mkdir(exist_ok=True)
adb = Path.home() / 'AppData/Local/Android/Sdk/platform-tools/adb.exe'
package = 'org.littlegod.livinguniverse.rpgqa'


def run(*commands):
    return subprocess.check_output([str(adb), '-s', 'emulator-5554', *commands], timeout=120)


def read(name, pkg=package):
    for attempt in range(8):
        try:
            return run('exec-out', 'run-as', pkg, 'cat', 'files/' + name)
        except subprocess.CalledProcessError:
            if attempt == 7:
                raise
            time.sleep(.5)


def player_snapshot():
    result = {}
    for pkg in [package, 'org.littlegod.livinguniverse']:
        for name in ['planet.json', 'planet.json.bak', 'settings.cfg']:
            command = "if [ -f files/" + name + " ]; then printf 'PRESENT\\n'; cat files/" + name + "; else printf 'ABSENT\\n'; fi"
            data = run('exec-out', 'run-as', pkg, 'sh', '-c', command)
            assert data.startswith(b'PRESENT\n') or data == b'ABSENT\n'
            result[pkg + '/' + name] = {'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}
    return result


def put(name, path):
    run('push', str(path), '/data/local/tmp/littlegod-entry-qa')
    run('shell', 'run-as', package, 'cp', '/data/local/tmp/littlegod-entry-qa', 'files/' + name)


def start():
    return run('shell', 'am', 'start', '-W', '-n', package + '/com.godot.game.GodotAppLauncher').decode()


before = player_snapshot()
run('shell', 'am', 'force-stop', package)
run('install', '--no-incremental', '-r', str(root / 'builds/android' / args.apk))
run('shell', 'run-as', package, 'mkdir', '-p', 'files')
put('rpg-fixture.json', root / 'tests/fixtures/planet-v085e2.json')
run_id = uuid.uuid4().hex
config = out / 'config.json'
config.write_text(json.dumps({'phase': 'entry', 'run_id': run_id, 'endpoint':args.endpoint}), encoding='utf8')
put('phase4_qa.json', config)
(out / 'startup.txt').write_text(start(), encoding='utf8')
deadline = time.monotonic() + 180
sent = set()
actions = []
while time.monotonic() < deadline:
    result = json.loads(read('phase4_qa_status.json'))
    if result.get('run_id') != run_id:
        time.sleep(.3)
        continue
    if result['stage'] == 'entry_tap' and result['sequence'] not in sent:
        sent.add(result['sequence'])
        vx, vy = result['viewport']
        for attempt in range(5):
            try:
                width, height = map(int, re.findall(r'(\d+)x(\d+)', run('shell', 'wm', 'size').decode())[-1])
                break
            except (subprocess.CalledProcessError, IndexError):
                if attempt == 4:
                    raise
                time.sleep(1)
        if (width > height) != (vx > vy):
            width, height = height, width
        x, y = result['tap_point']
        x, y = round(x * width / vx), round(y * height / vy)
        for _ in range(result.get('tap_count', 1)):
            run('shell', 'input', 'tap', str(x), str(y))
        actions.append({'sequence': result['sequence'], 'action': result['action'], 'screen_point': [x, y], 'count': result.get('tap_count', 1)})
        (out / 'native-taps.json').write_text(json.dumps(actions, indent=2), encoding='utf8')
    if result['stage'] == 'entry_complete':
        break
    time.sleep(.3)
else:
    (out / 'last-state.json').write_text(json.dumps(result, indent=2), encoding='utf8')
    raise RuntimeError('Entry native QA timed out')
result['external_adb_actions'] = actions
result['physical_device'] = False
result['player_files_preserved'] = player_snapshot() == before
screens = root / 'docs/screenshots' / args.output
screens.mkdir(parents=True, exist_ok=True)
for name in ['login', 'create', 'shared', 'home']:
    (screens / ('entry-android-' + name + '.png')).write_bytes(read('entry-android-' + name + '.png'))
logs = run('logcat', '-d', '--pid=' + str(result['pid']), '-s', 'godot:V', 'AndroidRuntime:E')
(out / 'logcat.txt').write_bytes(logs)
result['script_errors'] = [line for line in logs.decode('utf8', errors='replace').splitlines() if 'SCRIPT ERROR:' in line or 'FATAL EXCEPTION' in line]
(out / 'result.json').write_text(json.dumps(result, indent=2), encoding='utf8')
assert result['all_passed'] and result['player_files_preserved'] and not result['script_errors'], result
saved = read('entry-android-private.json')
expected = hashlib.sha256(saved).hexdigest()
assert result['save_sha256'] == expected
run('shell', 'am', 'force-stop', package)
restore_id = uuid.uuid4().hex
config.write_text(json.dumps({'phase': 'entry', 'run_id': restore_id, 'restore_only': True, 'expected_sha256': expected}), encoding='utf8')
put('phase4_qa.json', config)
(out / 'restore-startup.txt').write_text(start(), encoding='utf8')
deadline = time.monotonic() + 40
while time.monotonic() < deadline:
    restored = json.loads(read('phase4_qa_status.json'))
    if restored.get('run_id') == restore_id and restored.get('stage') == 'entry_restore_complete':
        break
    time.sleep(.5)
else:
    raise RuntimeError('Entry restart timed out')
restored['save_unchanged'] = read('entry-android-private.json') == saved
restored['new_process'] = restored['pid'] != result['pid']
restored['player_files_preserved'] = player_snapshot() == before
(out / 'restore.json').write_text(json.dumps(restored, indent=2), encoding='utf8')
run('shell', 'run-as', package, 'rm', '-f', 'files/phase4_qa.json')
assert restored['all_passed'] and restored['save_unchanged'] and restored['new_process'] and restored['player_files_preserved']
print(json.dumps({'checks': len(result['checks']), 'all_passed': True, 'adb_actions': len(actions), 'restore_checks': len(restored['checks']), 'save_unchanged': True, 'physical_device': False}, indent=2))
