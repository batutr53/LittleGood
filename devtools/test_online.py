"""Real HTTP/PostgreSQL integration, independent temporary accounts; no mocks or secrets in reports."""
import copy,json,secrets,time,urllib.request,urllib.error,pathlib,statistics
ROOT=pathlib.Path(__file__).resolve().parents[1]
BASE='http://127.0.0.1:5087/api/v1'
checks=[]; latency=[]; users=[]
def check(name,condition):
    checks.append({'name':name,'passed':bool(condition)})
    if not condition: raise AssertionError(name)
def request(method,path,body=None,token=''):
    data=json.dumps(body).encode() if body is not None else None
    headers={'Content-Type':'application/json'}
    if token:headers['Authorization']='Bearer '+token
    start=time.perf_counter()
    try:
        with urllib.request.urlopen(urllib.request.Request(BASE+path,data,headers,method=method),timeout=10) as r:code=r.status;raw=r.read()
    except urllib.error.HTTPError as e:code=e.code;raw=e.read()
    latency.append((time.perf_counter()-start)*1000)
    try:result=json.loads(raw) if raw else {}
    except ValueError:result={}
    return code,result
def api(user,method,path,body=None):return request(method,path,body,user['accessToken'])
def create(label):
    account='qa_'+secrets.token_hex(10);password=secrets.token_urlsafe(24)
    check(label+' registration',request('POST','/auth/register',{'account':account,'password':password})[0]==202)
    status,u=request('POST','/auth/login',{'account':account,'password':password});check(label+' login',status==200 and 'refreshToken'in u)
    u.update(account=account,password=password);users.append(u)
    status,p=api(u,'GET','/me');check(label+' private default',status==200 and p['visibility']=='private');u['profile']=p
    return u
snapshot=json.loads((ROOT/'docs/examples/Lumi.lgplanet').read_text(encoding='utf-8'))
try:
    check('unauthenticated denied',request('GET','/me')[0]==401)
    a=create('A');b=create('B');c=create('C')
    check('duplicate registration same response',request('POST','/auth/register',{'account':a['account'],'password':a['password']})[0]==202)
    check('wrong password generic',request('POST','/auth/login',{'account':a['account'],'password':'wrong-password'})[0]==401)
    check('unknown account generic',request('POST','/auth/login',{'account':'unknown_'+secrets.token_hex(8),'password':'wrong-password'})[0]==401)
    for u,name in [(a,'Test guardian A'),(b,'Test guardian B')]:
        check(name+' profile update',api(u,'PUT','/me/profile',{'name':name,'avatar':2,'visibility':'friends'})[0]==200)
    ac=a['profile']['code'];bc=b['profile']['code'];cc=c['profile']['code']
    check('private account not enumerated',api(a,'GET','/players/'+cc)[0]==404)
    check('guest planet explicitly published',api(b,'PUT','/planets/showcase',{'snapshot':snapshot,'visibility':'friends'})[0]==200)
    check('nonfriend showcase denied',api(a,'GET',f'/planets/{bc}/showcase')[0]==404)
    check('request sent',api(a,'POST','/friends/'+bc,{})[0]==204)
    check('duplicate request idempotent',api(a,'POST','/friends/'+bc,{})[0]==204)
    check('sender cannot accept',api(a,'PUT',f'/friends/{bc}/accept',{})[0]==404)
    status,rows=api(b,'GET','/friends');check('recipient sees request',status==200 and len(rows['items'])==1 and rows['items'][0]['incoming'])
    check('friend request notification',any(x['kind']=='friend_request' for x in api(b,'GET','/notifications')[1]['items']))
    check('request accepted',api(b,'PUT',f'/friends/{ac}/accept',{})[0]==204)
    status,remote=api(a,'GET',f'/planets/{bc}/showcase');check('actual snapshot downloaded',status==200 and remote['snapshot']==snapshot)
    check('no internal user IDs',set(api(a,'GET','/players/'+bc)[1])=={'code','name','avatar','visibility'})
    check('real visit accepted',api(a,'POST','/visits/'+bc,{})[0]==204)
    check('reaction delivered',api(a,'PUT','/reactions/'+bc,{'kind':2})[0]==204)
    check('reaction duplicate idempotent',api(a,'PUT','/reactions/'+bc,{'kind':2})[0]==204)
    notifications=api(b,'GET','/notifications')[1]['items'];check('one reaction notification in stable newest-first inbox',sum(x['kind']=='planet_reaction' for x in notifications)==1 and [x['id'] for x in notifications]==sorted([x['id'] for x in notifications],reverse=True))
    check('invalid reaction refused',api(a,'PUT','/reactions/'+bc,{'kind':9})[0]==404)
    check('friends only not public',not api(c,'GET','/discovery')[1]['items'])
    check('public profile opt in',api(b,'PUT','/me/profile',{'name':'Test guardian B','avatar':2,'visibility':'public'})[0]==200)
    check('public planet opt in',api(b,'PUT','/planets/showcase',{'snapshot':snapshot,'visibility':'public'})[0]==200)
    check('real discovery entry',any(x['code']==bc for x in api(c,'GET','/discovery')[1]['items']))
    check('publish idempotent',api(b,'PUT','/planets/showcase',{'snapshot':snapshot,'visibility':'public'})[0]==200 and api(a,'GET',f'/planets/{bc}/showcase')[1]['revision']==2)
    bad=copy.deepcopy(snapshot);bad['script']='res://evil.gd'
    check('extra script field refused',api(b,'PUT','/planets/showcase',{'snapshot':bad,'visibility':'public'})[0]==400)
    bad=copy.deepcopy(snapshot);bad['creatures'][0]['cell']=9999
    check('invalid cell refused',api(b,'PUT','/planets/showcase',{'snapshot':bad,'visibility':'public'})[0]==400)
    bad=copy.deepcopy(snapshot);bad['planet']['name']='https://evil'
    check('resource URL refused',api(b,'PUT','/planets/showcase',{'snapshot':bad,'visibility':'public'})[0]==400)
    check('oversized payload refused',api(b,'PUT','/planets/showcase',{'snapshot':{'data':'x'*550000},'visibility':'public'})[0]==413)
    check('cross owner field refused',api(a,'PUT','/planets/showcase',{'owner':bc,'snapshot':snapshot,'visibility':'public'})[0]==400)
    check('pagination input bounded',api(c,'GET','/discovery?offset=-1')[0]==400)
    check('block succeeds',api(b,'PUT','/blocks/'+ac,{})[0]==204)
    check('block denies alternate snapshot',api(a,'GET',f'/planets/{bc}/showcase')[0]==404)
    check('block denies profile',api(a,'GET','/players/'+bc)[0]==404)
    check('block hides discovery',not any(x['code']==bc for x in api(a,'GET','/discovery')[1]['items']))
    check('block denies invitations',api(a,'POST','/friends/'+bc,{})[0]==404)
    check('block removes friendship',not api(a,'GET','/friends')[1]['items'])
    check('block removes reaction activity',not api(b,'GET','/notifications')[1]['items'])
    check('unblock',api(b,'DELETE','/blocks/'+ac)[0]==204)
    check('new request after unblock',api(a,'POST','/friends/'+bc,{})[0]==204)
    check('reject request',api(b,'DELETE','/friends/'+ac)[0]==204)
    check('request removed',not api(a,'GET','/friends')[1]['items'])
    check('visibility revoked',api(b,'PUT','/me/profile',{'name':'Test guardian B','avatar':2,'visibility':'private'})[0]==200)
    check('private profile denies public snapshot',api(c,'GET',f'/planets/{bc}/showcase')[0]==404)
    check('private profile absent discovery',not api(c,'GET','/discovery')[1]['items'])
    check('unpublish',api(b,'DELETE','/planets/showcase')[0]==204)
    check('owner sees unpublished absent',api(b,'GET',f'/planets/{bc}/showcase')[0]==404)
    status,renewed=request('POST','/auth/refresh',{'refreshToken':a['refreshToken']});check('real session refresh',status==200)
    old=a['accessToken'];refresh=a['refreshToken'];a.update(renewed)
    check('logout server revokes',api(a,'POST','/auth/logout',{})[0]==204)
    check('old access revoked',request('GET','/me',token=old)[0]==401)
    check('old refresh revoked',request('POST','/auth/refresh',{'refreshToken':refresh})[0]==401)
    status,new=request('POST','/auth/login',{'account':a['account'],'password':a['password']});check('relogin',status==200);a.update(new)
    token=c['accessToken'];check('account deletion',api(c,'DELETE','/me')[0]==204);c['deleted']=True
    check('deleted token denied',request('GET','/me',token=token)[0]==401)
finally:
    for u in users:
        if not u.get('deleted'):api(u,'DELETE','/me')
    output={'source':'real_http_postgresql','checks':checks,'passed':sum(x['passed'] for x in checks),'total':len(checks),'latency_median_ms':statistics.median(latency),'latency_p95_ms':sorted(latency)[int(.95*(len(latency)-1))],'snapshot_bytes':len(json.dumps(snapshot).encode()),'temporary_accounts_deleted':True}
    (ROOT/'builds/phase7/backend-integration.json').write_text(json.dumps(output,indent=2),encoding='utf-8')
    print(json.dumps({k:v for k,v in output.items() if k!='checks'},indent=2))
