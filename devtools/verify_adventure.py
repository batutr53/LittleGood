"""Run original regression suites unchanged and milestone-C model suites; retain exact logs."""
from pathlib import Path
import subprocess,json,time
root=Path(__file__).resolve().parents[1];out=root/'builds/phase085c';out.mkdir(exist_ok=True)
names=['suite','runtime','phase2','phase3','phase4','phase5','phase6','phase7','phase8','phase085','industry','hero','exploration','combat','combat_crafting','boss','adventure_invariants','boss_patterns']
results=[]
for name in names:
 started=time.monotonic()
 p=subprocess.run([str(root/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'),'--headless','--path',str(root),'--script',f'tests/{name}.gd'],cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180)
 text=p.stdout.decode('utf-8',errors='replace');(out/f'final-{name}.log').write_text(text,encoding='utf-8')
 # Existing suites explicitly quit with live nodes; retain their known shutdown diagnostics.
 errors=[line for line in text.splitlines() if 'ERROR:' in line and 'resources still in use at exit' not in line]
 passed=p.returncode==0 and not errors and 'Parse Error' not in text
 results.append(dict(suite=name,passed=passed,exit=p.returncode,seconds=round(time.monotonic()-started,2)))
 print(name,passed,flush=True)
(out/'regression-summary.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
assert all(x['passed'] for x in results),results
