from pathlib import Path
import subprocess,io,zipfile
root=Path(__file__).resolve().parents[1];target=root/'builds/phase085c/compat-b';target.mkdir(parents=True,exist_ok=True)
models=['biomes','world_gen','ecosystem','civilization','living_stories','world_connections','cosmetics','planet_showcase','persistence','kingdom','kingdom_progression_probe','industry','industry_progression_probe']
with zipfile.ZipFile(io.BytesIO(subprocess.check_output(['git','archive','--format=zip','age085-milestone-b'],cwd=root))) as z:
 for name in z.namelist():
  if name in ['scripts/'+m+'.gd' for m in models] or (name.startswith('assets/') and name.endswith('.json')) or name=='assets/cosmetics/atlas.svg':
   p=target/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(z.read(name))
(target/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Historical B model"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n',encoding='utf-8')
(target/'fixture.gd').write_text('extends SceneTree\nfunc _initialize():\n var p=load("res://scripts/industry_progression_probe.gd").new()\n var ok=p.through_iron_age()\n var f=p.world.kingdom.buildings.filter(func(b):return b.kind=="forge")[0]\n load("res://scripts/industry.gd").queue(p.world,"field_sickle",int(f.id))\n ok=Persistence.save_world(p.world,"D:/LittleGod/tests/fixtures/planet-v085b.json") and ok\n print("ACTUAL_B ",ok)\n quit(0 if ok else 1)\n',encoding='utf-8')
godot=root/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
with (root/'builds/phase085c/legacy-b.log').open('w',encoding='utf-8') as log:
 for args in [['--headless','--editor','--path',str(target),'--import','--quit'],['--headless','--path',str(target),'--script','fixture.gd']]:subprocess.run([str(godot),*args],stdout=log,stderr=log,check=True)
