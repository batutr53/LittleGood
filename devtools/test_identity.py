"""Real-account identity/daily checks, including concurrent and foreign claims."""
import concurrent.futures,json,secrets,urllib.request,urllib.error,os
from pathlib import Path
origin=os.environ.get('LITTLEGOD_TEST_ORIGIN','http://127.0.0.1:5087').rstrip('/')
checks={};users=[]
def request(method,path,body=None,user=None):
 h={'Content-Type':'application/json'}
 if user:h['Authorization']='Bearer '+user['accessToken']
 try:
  with urllib.request.urlopen(urllib.request.Request(origin+'/api/v1'+path,json.dumps(body).encode() if body is not None else None,h,method=method),timeout=12) as r:return r.status,json.load(r) if r.status!=204 else {}
 except urllib.error.HTTPError as e:return e.code,{}
def check(k,v):
 checks[k]=bool(v)
 if not v:raise AssertionError(k)
def account():
 a='qa_'+secrets.token_hex(8);p=secrets.token_urlsafe(24);check('register_'+str(len(users)),request('POST','/auth/register',{'account':a,'password':p})[0]==202)
 status,u=request('POST','/auth/login',{'account':a,'password':p});check('login_'+str(len(users)),status==200);users.append(u);return u
try:
 a=account();b=account();stats=dict(strength=0,dexterity=0,intelligence=2,magic=6,vitality=2);base='/realms/hearth/characters'
 for title,changes in [('bad_race',dict(race='other')),('incomplete_stats',dict(stats={'magic':10})),('too_many_points',dict(stats=stats|{'strength':1}))]:
  check(title,request('POST',base,dict(name='QA '+secrets.token_hex(5),**{'class':'mage'},race='stoneborn',stats=stats)|changes,a)[0]==400)
 status,c=request('POST',base,dict(name='QA '+secrets.token_hex(5),**{'class':'mage'},race='stoneborn',stats=stats),a);check('identity_saved',status==200 and c['race']=='stoneborn' and c['startingStats']==stats);path=base+'/'+c['id']+'/daily'
 check('foreign_read_denied',request('GET',path,user=b)[0]==404);check('foreign_claim_denied',request('POST',path,user=b)[0]==404)
 check('first_gift_ready',request('GET',path,user=a)[1]['ready'])
 with concurrent.futures.ThreadPoolExecutor(2) as pool:results=list(pool.map(lambda _:request('POST',path,user=a),range(2)))
 check('concurrent_one_grant',all(s==200 for s,_ in results) and sum(d['granted'] for _,d in results)==1)
 check('exactly_one_essence',all(d['character']['essence']==1 for _,d in results));status,d=request('GET',path,user=a);check('persistent_calendar',status==200 and d['claimed']==1 and not d['ready'])
 status,items=request('GET',base,user=a);check('identity_reload',status==200 and items['items'][0]['startingStats']==stats and items['items'][0]['essence']==1)
finally:
 for u in users:request('DELETE','/me',user=u)
 report=dict(checks=checks,count=len(checks),all_passed=bool(checks) and all(checks.values()),origin=origin,source='real HTTP accounts/PostgreSQL; simultaneous daily claims; normal TLS')
 out=Path('builds/kingdom-ui');out.mkdir(exist_ok=True);(out/'identity-http.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
