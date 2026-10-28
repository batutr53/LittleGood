"""Force-stop/relaunch the isolated Reforge QA save; never target production."""
from pathlib import Path
import hashlib
import json
import subprocess
import time
import uuid

root = Path(__file__).resolve().parents[1]
adb = Path.home() / 'AppData/Local/Android/Sdk/platform-tools/adb.exe'
package = 'org.littlegod.livinguniverse.rpgqa'
output = root / 'builds/reforge-lifecycle'
output.mkdir(exist_ok=True)


def run(*args):
    return subprocess.check_output([str(adb), '-s', 'emulator-5554', *args], timeout=30)


def read(name):
    return run('exec-out', 'run-as', package, 'cat', 'files/' + name)


baseline = json.loads(read('phase4_qa_status.json'))
assert baseline['stage'] == 'reforge_complete' and baseline['all_passed']
saved = read('reforge-android-private.json')
expected = hashlib.sha256(saved).hexdigest()
assert expected == baseline['save_sha256']
run('shell', 'am', 'force-stop', package)
config = {'phase': 'reforge', 'restore_only': True, 'expected_sha256': expected, 'run_id': uuid.uuid4().hex}
path = output / 'config.json'
path.write_text(json.dumps(config), encoding='utf8')
run('push', str(path), '/data/local/tmp/littlegod-reforge-lifecycle.json')
run('shell', 'run-as', package, 'cp', '/data/local/tmp/littlegod-reforge-lifecycle.json', 'files/phase4_qa.json')
startup = run('shell', 'am', 'start', '-W', '-n', package + '/com.godot.game.GodotAppLauncher').decode()
(output / 'startup.txt').write_text(startup, encoding='utf8')
deadline = time.monotonic() + 40
while time.monotonic() < deadline:
    result = json.loads(read('phase4_qa_status.json'))
    if result.get('stage') == 'reforge_restore_complete' and result.get('run_id') == config['run_id']:
        break
    time.sleep(.5)
else:
    raise RuntimeError('Restore QA timed out')
result['saved_bytes_unchanged'] = read('reforge-android-private.json') == saved
result['new_process'] = result['pid'] != baseline['pid']
result['physical_device'] = False
(output / 'result.json').write_text(json.dumps(result, indent=2), encoding='utf8')
run('shell', 'run-as', package, 'rm', '-f', 'files/phase4_qa.json')
print(json.dumps(result, indent=2))
assert result['all_passed'] and result['saved_bytes_unchanged'] and result['new_process']
