"""Two real HTTP accounts and WebSocket peers against the local PostgreSQL API."""
import asyncio,json,math,secrets,time,urllib.request,urllib.error,os
from pathlib import Path
import websockets
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'builds/lobby';OUT.mkdir(exist_ok=True)
ORIGIN=os.environ.get('LITTLEGOD_TEST_ORIGIN','http://127.0.0.1:5087').rstrip('/')
BASE=ORIGIN+'/api/v1';WS=ORIGIN.replace('https://','wss://').replace('http://','ws://')+'/play';checks={};users=[]
def check(name,value):
    checks[name]=bool(value)
    if not value:raise AssertionError(name)
def request(method,path,body=None,user=None):
    headers={'Content-Type':'application/json'}
    if user:headers['Authorization']='Bearer '+user['accessToken']
    try:
        with urllib.request.urlopen(urllib.request.Request(BASE+path,json.dumps(body).encode() if body is not None else None,headers,method=method),timeout=10) as r:return r.status,json.load(r) if r.length!=0 else {}
    except urllib.error.HTTPError as e:return e.code,{}
def create(job):
    name='qa_'+secrets.token_hex(9);password=secrets.token_urlsafe(24)
    check(job+'_register',request('POST','/auth/register',{'account':name,'password':password})[0]==202)
    status,u=request('POST','/auth/login',{'account':name,'password':password});check(job+'_login',status==200);users.append(u)
    status,c=request('POST','/realms/hearth/characters',{'name':'QA '+secrets.token_hex(5),'class':job},u);check(job+'_create',status==200 and c['unlocked']==[job]);u['character']=c
    return u
async def run():
    check('requires_account',request('GET','/realms')[0]==401)
    a=create('warrior');b=create('priest')
    check('realm_live',request('GET','/realms',user=a)[1]['items'][0]['status']=='online')
    c=a['character'];cid=c['id'];path='/realms/hearth/characters/'+cid
    check('one_character_per_realm',request('POST','/realms/hearth/characters',{'name':'Another QA','class':'mage'},a)[0]==409)
    check('foreign_character_denied',request('POST',path+'/enter',user=b)[0]==404)
    check('unearned_recruit_denied',request('POST',path+'/recruit',{'class':'mage'},a)[0]==409)
    tickets=[request('POST','/realms/hearth/characters/'+u['character']['id']+'/enter',user=u)[1]['ticket'] for u in [a,b]]
    latest=[None,None]
    async with websockets.connect(WS) as wa,websockets.connect(WS) as wb:
        peers=[wa,wb]
        for ws,t in zip(peers,tickets):await ws.send(json.dumps({'ticket':t}))
        async def receive(i):
            async for raw in peers[i]:latest[i]=json.loads(raw)
        tasks=[asyncio.create_task(receive(i)) for i in range(2)]
        deadline=time.monotonic()+12
        while time.monotonic()<deadline and not all(s and {a['character']['id'],b['character']['id']} <= {p['id'] for p in s['players']} for s in latest):await asyncio.sleep(.1)
        if not all(latest):(OUT/'connection-diagnostic.json').write_text(json.dumps(latest),encoding='utf8')
        check('two_real_peers',all(s and {a['character']['id'],b['character']['id']} <= {p['id'] for p in s['players']} for s in latest))
        check('same_server_tick',abs(latest[0]['tick']-latest[1]['tick'])<=1)
        # A consumed ticket cannot create a second session.
        async with websockets.connect(WS) as duplicate:
            await duplicate.send(json.dumps({'ticket':tickets[0]}))
            try:await asyncio.wait_for(duplicate.recv(),2);rejected=False
            except websockets.exceptions.ConnectionClosed:rejected=True
        check('ticket_one_use',rejected)
        initial=next(p for p in latest[0]['players'] if p['id']==cid);position=(initial['x'],initial['y'])
        await wa.send(json.dumps({'sequence':0,'x':9999,'y':0,'action':'attack','target':1}));await asyncio.sleep(.3)
        me=next(p for p in latest[0]['players'] if p['id']==cid);check('teleport_rejected',(me['x'],me['y'])==position)
        sequence=1
        for n in range(450):
            for i,u in enumerate([a,b]):
                state=latest[i];me=next(p for p in state['players'] if p['id']==u['character']['id']);targets=[e for e in state['enemies'] if e['hp']>0]
                target=min(targets,key=lambda e:math.hypot(e['x']-me['x'],e['y']-me['y'])) if targets else None
                dx=target['x']-me['x'] if target else 0;dy=target['y']-me['y'] if target else 0;length=math.hypot(dx,dy)
                move=length>(75 if i==0 else 150)
                await peers[i].send(json.dumps({'sequence':sequence,'x':dx/length if move and length else 0,'y':dy/length if move and length else 0,'action':'skill' if n%30==0 else 'attack','target':target['id'] if target else 0}))
            sequence+=1;await asyncio.sleep(.1)
            if all(next(p for p in latest[i]['players'] if p['id']==u['character']['id'])['hunts']>=3 for i,u in enumerate([a,b])):break
        for i,u in enumerate([a,b]):
            me=next(p for p in latest[i]['players'] if p['id']==u['character']['id']);check(('warrior' if i==0 else 'priest')+'_server_xp',me['xp']>=60 and me['essence']>=3 and me['hunts']>=3)
        check('shared_enemy_state',latest[0]['enemies']==latest[1]['enemies'])
        for task in tasks:task.cancel()
    await asyncio.sleep(.4)
    status,rows=request('GET','/realms/hearth/characters',user=a);saved=rows['items'][0];check('persistent_rewards',saved['experience']>=60 and saved['essence']>=3)
    status,unlocked=request('POST',path+'/recruit',{'class':'mage'},a);check('earned_class_unlock',status==200 and 'mage'in unlocked['unlocked'] and unlocked['essence']==saved['essence']-3)
    status,again=request('POST',path+'/recruit',{'class':'mage'},a);check('unlock_idempotent',status==200 and again==unlocked)
    check('class_selection_persists',request('POST',path+'/select-class',{'class':'mage'},a)[1]['primaryClass']=='mage')
    ticket=request('POST',path+'/enter',user=a)[1]['ticket']
    async with websockets.connect(WS) as rejoined:
        await rejoined.send(json.dumps({'ticket':ticket}));state=json.loads(await rejoined.recv())
        check('earned_companion_in_world',any(p['owner']==cid and p['job']=='warrior' for p in state['companions']))
        check('active_recruit_denied',request('POST',path+'/recruit',{'class':'priest'},a)[0]==409)
        check('active_class_switch_denied',request('POST',path+'/select-class',{'class':'warrior'},a)[0]==409)
        await rejoined.send(json.dumps({'sequence':'invalid','x':'invalid','y':None}));state=json.loads(await rejoined.recv());check('malformed_intent_does_not_break_session',state['version']==1)
try:
    asyncio.run(run())
finally:
    for user in users:
        try:request('DELETE','/me',user=user)
        except Exception:pass
    result={'checks':checks,'count':len(checks),'all_passed':bool(checks) and all(checks.values()),'origin':ORIGIN,'source':'real HTTP/PostgreSQL with two simultaneous WebSocket peers; QA accounts only; normal TLS validation'}
    (OUT/'server-integration.json').write_text(json.dumps(result,indent=2),encoding='utf8');print(json.dumps(result))
