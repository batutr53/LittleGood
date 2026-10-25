"""Native emulator taps. Run after android_rpg_validate; inspect captures afterward."""
from pathlib import Path
import subprocess,time,struct,json,hashlib
r=Path(__file__).resolve().parents[1];adb=Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe';out=r/'docs/screenshots/classic-ui'
qa=json.loads((r/'builds/classic-android/result.json').read_text(encoding='utf8'));apk=json.loads((r/'builds/classic-apk.json').read_text(encoding='utf8'))
assert qa['all_passed']
def run(*args):return subprocess.run([str(adb),'-s','emulator-5554',*args],capture_output=True,check=True,timeout=30).stdout
assert int(run('shell','pidof','org.littlegod.livinguniverse.rpgqa').strip())==qa['pid']
shots={}
def shot(name):
    data=run('exec-out','screencap','-p');(out/(name+'.png')).write_bytes(data);shots[name]=hashlib.sha256(data).hexdigest();return struct.unpack('>II',data[16:24])
w,h=shot('native-home');vw,vh=qa['viewport']
def tap(x,y):run('shell','input','tap',str(round(x*w/vw)),str(round(y*h/vh)));time.sleep(1.5)
tap(vw-375.5,vh-18);shot('native-inventory')
tap(vw-266,437);shot('native-item-details')
tap(vw-340,125);shot('native-warrior')
tap(vw-32,90);shot('native-close')
tap(vw-326.5,vh-18);shot('native-skills')
tap(vw-32,90);tap(435,vh-65);shot('native-chat-collapsed')
tap(50,vh-65);shot('native-chat-restored')
evidence={'date':'2026-10-25','device':'emulator-5554','physical_device':False,'apk_sha256':apk['sha256'],'qa_run_id':qa['run_id'],'actual_input':'ADB input tap','captures':shots,'visually_inspected':False,'limitations':'This is not physical-device, multitouch, keyboard or OEM safe-area certification.'}
(r/'docs/benchmarks/classic-ui/native-input.json').write_text(json.dumps(evidence,indent=2),encoding='utf8')
print('Native taps complete. Inspect screenshots before marking the evidence verified.')
