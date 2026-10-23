"""Retain 689 checks, then verify the E2 prerequisite needed before E3."""
from pathlib import Path
import subprocess,json,re,time,sys
r=Path(__file__).resolve().parents[1];out=r/'builds/phase085e2full';out.mkdir(exist_ok=True)
subprocess.run([sys.executable,'-X','utf8',str(r/'devtools/verify_regions.py')],cwd=r,check=True)
baseline=json.loads((r/'builds/phase085e2/verification.json').read_text());assert baseline['all_passed'] and baseline['game_checks']==689
start=time.monotonic();p=subprocess.run([str(r/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'),'--headless','--path',str(r),'--script','tests/desert.gd'],cwd=r,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180)
text=p.stdout.decode('utf-8',errors='replace');(out/'desert.log').write_text(text,encoding='utf-8')
line=next((s for s in text.splitlines() if s.startswith('DESERT_CHECKS ')),'');checks=re.findall(r'"([^"\n]+)": (true|false)',line)
errors=[s for s in text.splitlines() if 'ERROR:' in s and 'resources still in use at exit' not in s]
report={'retained_checks':689,'new_desert_checks':len(checks),'game_checks':689+len(checks),'all_passed':p.returncode==0 and bool(checks) and not errors and all(v=='true' for k,v in checks),'desert_suite_seconds':round(time.monotonic()-start,3),'legal_1_22_seeds':[7,42,2026]}
(out/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report));assert report['all_passed'],report
