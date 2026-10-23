from pathlib import Path
import subprocess,zipfile,io
root=Path(__file__).resolve().parents[1];target=root/'builds/phase085/compat-08';target.mkdir(parents=True,exist_ok=True)
archive=subprocess.check_output(['git','archive','--format=zip','littlegod-0.8'],cwd=root)
with zipfile.ZipFile(io.BytesIO(archive)) as z:
    for name in z.namelist():
        if name.startswith(('scripts/','assets/')) and not name.endswith('/'):
            path=target/name;assert path.resolve().is_relative_to(target.resolve());path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(z.read(name))
(target/'project.godot').write_text('config_version=5\n[application]\nconfig/name="LittleGod 08 fixture generator"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n',encoding='utf-8')
(target/'fixture.gd').write_text('extends SceneTree\nfunc _initialize():\n var w=WorldGen.generate(42,"Legacy 0.8")\n var rng=RandomNumberGenerator.new()\n rng.state=int(w.rng_state)\n for i in range(120):\n  Ecosystem.tick(w,rng)\n  Civilization.tick(w)\n var C=load("res://scripts/cosmetics.gd")\n C.ensure(w)\n C.reconcile(w)\n C.buy(w,"comets")\n C.equip(w,"comets")\n for i in range(w.cells.size()):\n  if C.valid_place(w,"flowers",i):\n   C.place(w,"flowers",i)\n   break\n var ok=Persistence.save_world(w,"D:/LittleGod/tests/fixtures/planet-v08.json")\n print("LEGACY_08_FIXTURE ",ok)\n quit(0 if ok else 1)\n',encoding='utf-8')
godot=root/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
with (root/'builds/phase085/legacy-fixture.log').open('w',encoding='utf-8') as log:
    subprocess.run([str(godot),'--headless','--editor','--path',str(target),'--import','--quit'],stdout=log,stderr=log,check=True)
    subprocess.run([str(godot),'--headless','--path',str(target),'--script','fixture.gd'],stdout=log,stderr=log,check=True)
print('Generated fixture using actual littlegod-0.8 source, not current model code.')
