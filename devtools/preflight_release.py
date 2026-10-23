"""Check staged source and exported APK for local secret/packaging mistakes without printing secrets."""
import json,pathlib,subprocess,zipfile
root=pathlib.Path(__file__).resolve().parents[1]
files=subprocess.check_output(['git','diff','--cached','--name-only','-z'],cwd=root).decode().split('\0')
secret=next(x.split('=',1)[1] for x in (root/'server/.env').read_text().splitlines() if x.startswith('POSTGRES_PASSWORD='))
for name in filter(None,files):
    assert not name.startswith(('server/.local/','tools/','.godot/')) and not name.endswith('/.env'),name
    data=subprocess.check_output(['git','show',':'+name],cwd=root)
    assert secret.encode() not in data,'Secret appears in staged source'
    if pathlib.Path(name).suffix in ['.gd','.py','.cs','.ps1','.md','.json','.sql','.cfg','.cmd','.txt','.yaml']:
        assert all(c>=32 or c in [9,10,13] for c in data),'Control character in '+name
    if name.endswith('.json'):json.loads(data.decode('utf-8-sig'))
apk=root/'builds/android/LittleGod-0.7-debug.apk'
with zipfile.ZipFile(apk) as z:
    assert z.testzip() is None
    for name in z.namelist():
        assert 'server/.env' not in name and 'server/.local' not in name
        if name.endswith('.pck'):
            data=z.read(name)
            assert b'server/.env' not in data and b'server/LittleGod.Api/' not in data and secret.encode() not in data,'Backend secret/source included in client pack'
print('Preflight passed: staged text/JSON, local-secret exclusion and APK pack checks.')
