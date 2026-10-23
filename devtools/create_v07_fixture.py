from pathlib import Path
import subprocess,zipfile,io
root=Path(__file__).resolve().parents[1];target=root/'builds/phase8/compat-07';target.mkdir(parents=True,exist_ok=True)
archive=subprocess.check_output(['git','archive','--format=zip','littlegod-0.7'],cwd=root)
with zipfile.ZipFile(io.BytesIO(archive)) as z:
    for name in z.namelist():
        if name.startswith(('scripts/','assets/')) and not name.endswith('/'):
            path=target/name;assert path.resolve().is_relative_to(target.resolve());path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(z.read(name))
(target/'project.godot').write_text('config_version=5\n[application]\nconfig/name="LittleGod 07 fixture generator"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n',encoding='utf-8')
(target/'fixture.gd').write_text('extends SceneTree\nfunc _initialize():\n var w=WorldGen.generate(42,"Legacy 0.7")\n var rng=RandomNumberGenerator.new()\n rng.state=int(w.rng_state)\n for i in range(120):\n  Ecosystem.tick(w,rng)\n  Civilization.tick(w)\n var ok=Persistence.save_world(w,"D:/LittleGod/tests/fixtures/planet-v07.json")\n print("LEGACY_07_FIXTURE ",ok)\n quit(0 if ok else 1)\n',encoding='utf-8')
godot=root/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
with (root/'builds/phase8/legacy-fixture.log').open('w',encoding='utf-8') as log:
    subprocess.run([str(godot),'--headless','--editor','--path',str(target),'--import','--quit'],stdout=log,stderr=log,check=True)
    subprocess.run([str(godot),'--headless','--path',str(target),'--script','fixture.gd'],stdout=log,stderr=log,check=True)
print('Generated fixture using actual littlegod-0.7 source, not current model code.')
