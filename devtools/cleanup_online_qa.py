"""Remove disposable accounts from interrupted runs in the dedicated native local QA database."""
import os,pathlib,subprocess,json
root=pathlib.Path(__file__).resolve().parents[1]
values=dict(line.split('=',1) for line in (root/'server/.env').read_text().splitlines() if '=' in line and not line.startswith('#'))
env=os.environ.copy();env['PGPASSWORD']=values['POSTGRES_PASSWORD']
sql='''WITH removed AS (DELETE FROM "AspNetUsers" WHERE "UserName" ~ '^qa_[ab]_[0-9a-f]{24}$' RETURNING "Id") SELECT count(*) FROM removed;'''
r=subprocess.run([str(root/'tools/postgres/pgsql/bin/psql.exe'),'-h','127.0.0.1','-p','55437','-U',values['POSTGRES_USER'],'-d','littlegod','-tAc',sql],env=env,capture_output=True,check=True)
report={'dedicated_local_database':'127.0.0.1:55437/littlegod','interrupted_generated_qa_accounts_removed':int(r.stdout.strip())}
(root/'builds/phase7/qa-cleanup.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report))
