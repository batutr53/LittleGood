"""Retain all E2 checks; reject script errors even if an in-game check report passes."""
from pathlib import Path
import json,re,subprocess,sys,time
r=Path(__file__).resolve().parents[1];out=r/'builds/phase085e3';out.mkdir(exist_ok=True)
subprocess.run([sys.executable,'-X','utf8','devtools/verify_desert.py'],cwd=r,check=True)
baseline=json.loads((r/'builds/phase085e2full/verification.json').read_text());assert baseline['all_passed'] and baseline['game_checks']==745
start=time.monotonic()
p=subprocess.run([str(r/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'),'--headless','--path',str(r),'--script','tests/sanctuary.gd'],cwd=r,capture_output=True,timeout=180)
log=(p.stdout+p.stderr).decode('utf-8',errors='replace');(out/'sanctuary.log').write_text(log,encoding='utf-8')
line=next((s for s in log.splitlines() if s.startswith('SANCTUARY_CHECKS ')),'');checks=re.findall(r'"([^"\n]+)": (true|false)',line)
errors=[s for s in log.splitlines() if 'ERROR:' in s and 'resources still in use at exit' not in s]
report={'retained_checks':745,'sanctuary_checks':len(checks),'game_checks':745+len(checks),'all_passed':p.returncode==0 and bool(checks) and not errors and all(v=='true' for _,v in checks),'suite_seconds':round(time.monotonic()-start,3),'legal_1_23_seeds':[7,42,2026]}
(out/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report));assert report['all_passed'],report
