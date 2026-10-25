"""Collect actual test/build evidence for the compact mobile UI checkpoint."""
from pathlib import Path
import json,hashlib
r=Path(__file__).resolve().parents[1];out=r/'docs/benchmarks/classic-ui';out.mkdir(exist_ok=True)
def read(path):return json.loads((r/path).read_text(encoding='utf8'))
def line_checks(path,prefix):
    line=next(s for s in (r/path).read_text(encoding='utf8').splitlines() if s.startswith(prefix))
    return json.loads(line[len(prefix):])
layout=read('docs/benchmarks/classic-ui/verification.json');ui=read('builds/ui-rebirth/rendered.json');base=read('builds/phase085e3/verification.json');android=read('builds/classic-android/result.json');apk=read('builds/classic-apk.json');interactions=line_checks('builds/classic-interactions.log','RPG_UI_INTERACTIONS ')
assert layout['all_passed'] and ui['all_passed'] and base['all_passed'] and all(interactions.values()) and android['all_passed'] and android['player_files_preserved']
assert hashlib.sha256(Path(apk['apk']).read_bytes()).hexdigest()==apk['sha256']
result={'date':'2026-10-25','scope':'compact mobile RPG UI; not full prior RPG milestone','retained':base,'layout_check_count':len(layout['checks']),'landscape_check_count':len(ui['checks']),'interactions':interactions,'android':android,'apk':apk,'startup':(r/'builds/classic-android/startup.txt').read_text(encoding='utf8'),'physical_device':False,'performance_target_verified':False,'source':'Actual Godot and emulator renders; native touch results are separate.'}
(out/'delivery.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
print('Classic UI delivery evidence written; all functional checks passed.')
