"""Produce a real v1 campaign save using the tagged milestone-A source."""
from pathlib import Path
import subprocess,zipfile,io
root=Path(__file__).resolve().parents[1];target=root/'builds/phase09/compat-085-model';target.mkdir(parents=True,exist_ok=True)
if (root/'tests/fixtures/planet-v085a.json').exists():
 print('Retaining the existing authentic tagged milestone-A fixture.');raise SystemExit(0)
models=['biomes','world_gen','ecosystem','civilization','living_stories','world_connections','cosmetics','planet_showcase','persistence','kingdom','kingdom_progression_probe']
data=subprocess.check_output(['git','archive','--format=zip','age085-milestone-a'],cwd=root)
with zipfile.ZipFile(io.BytesIO(data)) as archive:
 for name in archive.namelist():
  if name in ['scripts/'+model+'.gd' for model in models] or (name.startswith('assets/') and name.endswith('.json')) or name=='assets/cosmetics/atlas.svg':
   path=target/name;assert path.resolve().is_relative_to(target.resolve());path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(archive.read(name))
(target/'project.godot').write_text('config_version=5\n[application]\nconfig/name="LittleGod A fixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n',encoding='utf-8')
(target/'fixture.gd').write_text('extends SceneTree\nfunc _initialize():\n var driver=load("res://scripts/kingdom_progression_probe.gd").new()\n driver.start(2026)\n var ok=driver.through_first_flame()\n ok=Persistence.save_world(driver.world,"D:/LittleGod/tests/fixtures/planet-v085a.json") and ok\n print("ACTUAL_TAGGED_A_SAVE ",ok)\n quit(0 if ok else 1)\n',encoding='utf-8')
godot=root/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
with (root/'builds/phase09/legacy-fixture.log').open('w',encoding='utf-8') as log:
 for args in [['--headless','--editor','--path',str(target),'--import','--quit'],['--headless','--path',str(target),'--script','fixture.gd']]:subprocess.run([str(godot),*args],stdout=log,stderr=log,check=True)
