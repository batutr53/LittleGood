"""Run once in a fresh auth window: real Identity lockout and real request throttling."""
import json,secrets,pathlib,urllib.request,urllib.error
root=pathlib.Path(__file__).resolve().parents[1]
base='http://127.0.0.1:5087/api/v1';checks={}
def req(path,body=None,token='',method='POST'):
    headers={'Content-Type':'application/json'}
    if token:headers['Authorization']='Bearer '+token
    try:
        with urllib.request.urlopen(urllib.request.Request(base+path,json.dumps(body).encode() if body is not None else None,headers,method=method),timeout=10) as r:return r.status,json.loads(r.read() or b'{}')
    except urllib.error.HTTPError as e:return e.code,{}
account='security_'+secrets.token_hex(10);password=secrets.token_urlsafe(24)
checks['registered']=req('/auth/register',{'account':account,'password':password})[0]==202
status,data=req('/auth/login',{'account':account,'password':password});checks['initial_login']=status==200
assert checks['initial_login']
try:
    statuses=[req('/auth/login',{'account':account,'password':'wrong-password'})[0] for _ in range(5)]
    checks['five_failures_generic']=statuses==[401]*5
    checks['correct_password_blocked_during_lockout']=req('/auth/login',{'account':account,'password':password})[0]==401
finally:
    checks['temporary_account_deleted']=req('/me',token=data['accessToken'],method='DELETE')[0]==204
statuses=[req('/auth/register',{'account':'!','password':'short'})[0] for _ in range(24)]
checks['auth_rate_limit_real_429']=429 in statuses
report={'source':'real_http_identity_postgresql','checks':checks,'all_passed':all(checks.values()),'auth_limit':20,'window_seconds':60}
(root/'builds/phase7/security-integration.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2));assert report['all_passed']
