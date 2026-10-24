"""Publish evidence for V4B only; refuses stale APK validation or failed checks."""
from pathlib import Path
import json,hashlib,shutil
r=Path(__file__).resolve().parents[1];out=r/'builds/visual-v4';dest=r/'docs/benchmarks/visual-v4';dest.mkdir(parents=True,exist_ok=True)
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def copy(p,name=None):
 target=dest/(name or p.name);target.parent.mkdir(parents=True,exist_ok=True)
 if p.suffix in [".txt",".log"]:target.write_text("\n".join(line.rstrip() for line in p.read_text(encoding="utf-8",errors="replace").splitlines()).rstrip()+"\n",encoding="utf-8")
 else:shutil.copyfile(p,target)
def meta(p):return {'path':str(p),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
assert 'FIXED SNAPSHOT VERIFIED' in (out/'final-validation.log').read_text(encoding='utf-8')
reg=read(r/'builds/phase085e3/verification.json');render=read(out/'rendered.json');model=read(out/'presentation.json');apk=meta(r/'builds/android/LittleGod-V4B-preview-qa-debug.apk')
assert reg['all_passed'] and reg['game_checks']==822 and render['all_passed'] and model['all_passed']
android=[]
for fps in [60,30]:
 data=read(out/f'android-{fps}/verification.json');assert data['all_passed'] and data['player_files_unchanged'] and data['apk_sha256']==apk['sha256'];android.append(data)
 for name in ['verification.json','result.json','restored.json','memory.txt','startup.txt','logcat.txt']:copy(out/f'android-{fps}/{name}',f'android-{fps}/{name}')
 shutil.copyfile(out/f'android-{fps}/v4-walk.png',r/f'docs/screenshots/visual-v4/android-{fps}-walk.png')
 shutil.copyfile(out/f'android-{fps}/v4-restored.png',r/f'docs/screenshots/visual-v4/android-{fps}-restored.png')
for name in ['rendered.json','rendered.log','presentation.json','presentation.log','regression.log','mcp.log','android-comparison.json','source-fingerprints.json','final-validation.log']:copy(out/name)
copy(r/'builds/v4-baseline.log','initial-baseline-failure.log')
for name in ['android-initial-failure','android-restart-harness-failure']:
 for item in (out/name).iterdir():
  if item.suffix in ['.json','.log','.txt']:copy(item,name+'/'+item.name)
copy(r/'builds/phase085e3/verification.json','retained-verification.json')
shutil.copyfile(out/'mcp-warrior.png',r/'docs/screenshots/visual-v4/mcp-warrior.png')
old=read(r/'builds/phase085e3/checkpoint-manifest.json')
for name in ['player_apk','qa_apk','source']:
 assert meta(Path(old[name]['path']))['sha256']==old[name]['sha256'],name+' changed'
metrics=render['desktop'];lines=['# Android / desktop animation measurements — V4B preview','', 'Measured with verified Godot4.7.2. Emulator: `emulator-5554`, x86_64, host NVIDIA RTX4070 laptop GPU translation. No physical Android device was connected. These are Warrior idle/walk/native-input samples, not a completed boss/VFX stress certification.','', '| Sample | FPS | p95 ms | Draw calls | Static bytes | Texture bytes |','|---|---:|---:|---:|---:|---:|']
for label,m in [('Desktop rendered',metrics)]+[(f"Emulator cap{d['fps_cap']}",d['metrics']) for d in android]:
 lines.append(f"| {label} | {m['fps']:.2f} | {m['p95_ms']:.2f} | {m['draw_calls']:.0f} | {int(m['static_memory_bytes'])} | {int(m['texture_memory_bytes'])} |")
lines+=['','The paired comparison on an earlier V4B candidate before the input-clear fix (its APK hash was not recorded for that comparison) measured original actor60.03FPS/p9518.74ms vs preview60.06FPS/p9518.76ms. Texture memory increased16MiB including mipmaps; measured presentation CPU changed137→151µs/frame and model CPU142→147µs/tick. This isolates the actor cost in a steady scene, not every possible encounter.','', 'The first fresh-emulator attempt was5.72FPS/p95566.47ms and failed native movement. It is retained under `android-initial-failure`. After emulator initialization, warm-up and a longer native drag, control checks passed. No device-wide driver or security setting was changed. Low initial samples are not erased or represented as physical-phone results. Cold-start hitches remain a limitation.','', 'AM Activity launch timings are stored separately in startup.txt; they are not a measurement of first interactive gameplay. Android dumpsys PSS is in memory.txt; Godot static allocation and GPU texture indicators are distinct counters, not total process RSS.','', 'Each final Android run passes12 native/session checks and5 restart checks. Native ADB input tests movement, multiple walk frames, attack, dodge, pause/resume and no touch-through. A debug fixture positions the real hero near the wolf for the hit test; this is not a native campaign-completion claim. Force-stop reload compares two separately saved worlds through the real Persistence loader. An earlier harness compared normalized integers to unnormalized JSON numeric strings and failed despite equal numeric data; that failed run is retained.','', f"Final APK SHA256: `{apk['sha256']}`. Package `org.littlegod.livinguniverse.v4preview`, code93. Existing player saves and E3 APK/source hashes are unchanged."]
(r/'docs/ANDROID_ANIMATION_PERFORMANCE.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
summary={'scope':'V4A/V4B isolated prototype; full V4 incomplete','all_verified_slice_checks_passed':True,'retained_game_checks':822,'new_presentation_checks':len(model['checks']),'new_rendered_checks':len(render['checks']),'android':android,'apk':apk,'full_V4_complete':False,'physical_device_tested':False,'E3_artifacts_unchanged':True}
(dest/'verification.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
status=r/'docs/STATUS.md';s=status.read_text(encoding='utf-8');heading='# LittleGod — E3: Secrets of the Ancients';addition='''# LittleGod — V4B isolated animation preview / E3 gameplay baseline

**Full Visual Rebirth V4 is incomplete.** A reversible V4A/V4B Warrior style and movement prototype is implemented and rendered in Godot; the default game still uses E3 art. Expansion development is frozen. Unverified E4 work is preserved on `work/e5-sovereign` at8b83003, outside this preview branch. E5/E6/throne and V2/V3 approval are not claimed.

The preview has144 original vector pose cells, four cardinal views, distance-driven walking, stable equipment sockets, idle/dodge/hurt/kneeling poses and contact/follow-through compatible with the existing instantaneous damage model. Pause, touch cancellation, focus loss and suspension now clear movement/held attack/joystick state. It does not yet implement real attack anticipation, three enemy remakes, boss animation, combat sound/VFX overhaul or final V4 art approval.

Retained checks: **822 passed again**. New presentation checks: **27**; rendered checks: **35**. Android60/30 native input and exact force-stop restore pass in the isolated preview package; no physical-device testing. Actual metrics, initial failures and limits are in `ANDROID_ANIMATION_PERFORMANCE.md` and `docs/benchmarks/visual-v4/`.

- Preview launcher: `D:/LittleGod/Launch V4 Warrior Preview.cmd`.
- Normal launcher: `D:/LittleGod/Launch LittleGod.cmd`.
- Preview QA APK: `D:/LittleGod/builds/android/LittleGod-V4B-preview-qa-debug.apk`.
- Preview source archive: `D:/LittleGod/builds/LittleGod-V4B-preview-source.zip`.
- Slice tag: `littlegod-visual-rebirth-v4b-preview`; full V4 completion tag is deliberately absent.
- Report: `docs/VISUAL_REBIRTH_V4_REPORT.md`; source/pivots: `SPRITE_ANIMATION_PIPELINE.md`.

![Actual animated preview in the emulator](screenshots/visual-v4/android-60-walk.png)

## Preserved E3 release
'''
if heading in s:s=s.replace(heading,addition,1)
s=s.replace('E4/E5/E6/throne and Visual Rebirth V4 remain unimplemented.', 'The full E4/E5/E6/throne and Visual Rebirth V4 milestones remain incomplete; see the isolated V4B prototype above.')
status.write_text(s,encoding='utf-8')
p=r/'docs/KNOWN_ISSUES.md';s=p.read_text(encoding='utf-8');s=s.replace('# Known issues —0.8.5-devE3','# Known issues — E3 baseline / V4B prototype',1);s=s.replace('- E3 core is implemented; E4/E5/E6/throne/Visual Rebirth V4 are not.', '- E3 core is implemented. Full E4/E5/E6/throne/V4 milestones are incomplete. V4B is an isolated, unapproved vector character study, not the finished premium art or combat overhaul. It supports four cardinal poses, generic equipment silhouettes and a kneeling defeat; dedicated heavy attacks, armor variations, blade-contact alignment and enemy/boss animation remain. The new input-clear fix handles pause/cancel/focus loss/suspension.');s+='\n- V4B Android evidence includes a severe first cold-emulator slowdown and later successful steady samples; do not claim universal stable60FPS or physical-phone performance. See ANDROID_ANIMATION_PERFORMANCE.md.\n';p.write_text(s,encoding='utf-8')
print(json.dumps({'retained':822,'presentation':len(model['checks']),'rendered':len(render['checks']),'apk':apk,'verified':True}))
