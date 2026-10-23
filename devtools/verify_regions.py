"""Run the retained 639 checks unchanged, then the new E2B suites."""
from pathlib import Path
import subprocess,json,time,re,sys
r=Path(__file__).resolve().parents[1];out=r/'builds/phase085e2';out.mkdir(exist_ok=True)
subprocess.run([sys.executable,'-X','utf8',str(r/'devtools/verify_trade.py')],cwd=r,check=True)
retained=json.loads((r/'builds/phase085e1/verification-summary.json').read_text())
assert retained['game_checks']==639 and retained['all_passed']
suites=[]
for name in ['regions','regional_combat']:
 started=time.monotonic();p=subprocess.run([str(r/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'),'--headless','--path',str(r),'--script',f'tests/{name}.gd'],cwd=r,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180)
 text=p.stdout.decode('utf-8',errors='replace');(out/(name+'.log')).write_text(text,encoding='utf-8')
 line=next((s for s in text.splitlines() if s.startswith('E2B_CHECKS ' if name=='regions' else 'E2B_COMBAT ')),'')
 assertions=re.findall(r'"([^"\n]+)": (true|false)',line)
 errors=[s for s in text.splitlines() if 'ERROR:' in s and 'resources still in use at exit' not in s]
 ok=p.returncode==0 and not errors and bool(assertions) and all(v=='true' for k,v in assertions)
 suites.append(dict(suite=name,passed=ok,checks=len(assertions),seconds=round(time.monotonic()-started,3)))
 print(name,ok,len(assertions),flush=True)
report={'retained_checks':639,'new_checks':sum(s['checks'] for s in suites),'game_checks':639+sum(s['checks'] for s in suites),'new_suites':suites,'all_passed':all(s['passed'] for s in suites),'legal_campaigns':'6 seeds, real levels 1–21 then Iron Hills; no level22 claim'}
(out/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8');assert report['all_passed'],report
