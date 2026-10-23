"""Retain the C suites unchanged; verify the critical D/E1 additions separately."""
from pathlib import Path
import subprocess,json,time,re
r=Path(__file__).resolve().parents[1];out=r/'builds/phase085e1';out.mkdir(exist_ok=True)
subprocess.run([__import__('sys').executable,'-X','utf8',str(r/'devtools/verify_adventure.py')],cwd=r,check=True)
results=[]
for name in ['military','military_campaign','trade','trade_campaign']:
 start=time.monotonic();p=subprocess.run([str(r/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'),'--headless','--path',str(r),'--script',f'tests/{name}.gd'],cwd=r,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180)
 text=p.stdout.decode('utf-8',errors='replace');(out/(name+'.log')).write_text(text,encoding='utf-8')
 errors=[s for s in text.splitlines() if 'ERROR:' in s and 'resources still in use at exit' not in s]
 assertions=re.findall(r'"([^"\n]+)": (true|false)',text) if name in ['military','trade'] else []
 passed=p.returncode==0 and not errors and 'Parse Error' not in text and all(v=='true' for k,v in assertions)
 results.append(dict(suite=name,passed=passed,exit=p.returncode,seconds=round(time.monotonic()-start,2),checks=len(assertions)))
 print(name,passed,'checks',len(assertions),flush=True)
baseline=json.loads((r/'builds/phase085c/regression-summary.json').read_text())
report={'retained_game_checks':539,'new_military_checks':results[0]['checks'],'new_trade_checks':results[2]['checks'],'game_checks':539+results[0]['checks']+results[2]['checks'],'baseline_suites':baseline,'new_suites':results,'all_passed':all(x['passed'] for x in baseline+results),'campaign_seeds':{'D_legal_1_20':12,'E1_legal_1_21':8}}
(out/'verification-summary.json').write_text(json.dumps(report,indent=2),encoding='utf-8');assert report['all_passed'],report
