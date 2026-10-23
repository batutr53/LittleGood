"""Archive a verified local Git tag and validate contents; never publishes or uploads."""
import argparse,pathlib,subprocess,zipfile,json,hashlib,re
root=pathlib.Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--version',default='0.7',choices=['0.6','0.7']);args=parser.parse_args()
tag='littlegod-'+args.version
def git(*a):return subprocess.check_output(['git',*a],cwd=root).decode().strip()
commit=git('rev-parse',tag+'^{commit}')
if args.version=='0.7':
    assert not git('status','--porcelain'), 'Commit all reviewed release source before archiving'
    assert commit==git('rev-parse','HEAD'),'Release tag must identify the verified HEAD'
dest=root/f'builds/LittleGod-{args.version}-source.zip';prefix=f'LittleGod-{args.version}/'
subprocess.run(['git','archive','--format=zip','--prefix='+prefix,'-o',str(dest),tag],cwd=root,check=True)
with zipfile.ZipFile(dest) as z:
    assert z.testzip() is None,'Archive CRC failure'
    files=[n[len(prefix):] for n in z.namelist() if not n.endswith('/')]
    for name in files:
        assert not name.startswith(('tools/','.godot/','server/.local/'))
        assert not name.endswith('/.env') and '/bin/' not in name and '/obj/' not in name
        assert not name.startswith('builds/') or name=='builds/.gdignore'
    for name in ['project.godot','scenes/main.tscn','scripts/main.gd','scripts/planet_showcase.gd','docs/STATUS.md','builds/.gdignore']:assert name in files,name
    if args.version=='0.7':
        for name in ['scripts/online_client.gd','server/compose.yaml','server/Dockerfile','server/migrate.sql','server/LittleGod.Api/Program.cs','server/LittleGod.Tests/SnapshotTests.cs','docs/SECURITY_REVIEW.md','docs/screenshots/phase7-visit.png']:assert name in files,name
        assert any(n.startswith('server/LittleGod.Api/Migrations/') for n in files)
    test_summary=json.loads(z.read(prefix+f'docs/benchmarks/phase{args.version[-1]}/tests.json'))
apk=root/f'builds/android/LittleGod-{args.version}-debug.apk'
report={'tag':tag,'commit':commit,'source_archive':str(dest),'archive_bytes':dest.stat().st_size,'archive_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'archive_crc_ok':True,'no_credentials_database_sdk_or_generated_outputs':True,'apk_bytes':apk.stat().st_size,'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'verification':test_summary,'public_deployment':False,'physical_device_verified':False}
target=root/f'builds/phase{args.version[-1]}/release-manifest.json';target.parent.mkdir(parents=True,exist_ok=True);target.write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
