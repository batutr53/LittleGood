"""Prepare original generated sprite sheets into one shared mobile atlas."""
from PIL import Image, ImageDraw
from pathlib import Path
import json, math, wave, struct, random
root=Path(__file__).resolve().parent.parent
source=Path(r'C:\Users\batua\.codex\generated_images\01a163ae-d724-7830-80ba-6b39304c80cc')
out=root/'assets/phase2'
out.mkdir(exist_ok=True)
atlas=Image.new('RGBA',(1024,1024))
manifest={}
sets=[('creature',source/'exec-f8cee9e5-457a-4822-a1e6-57d53d68aede.png',6),('prop',source/'exec-c8f981ab-b5c0-4a4c-88da-79f527f03c0c.png',6)]
for prefix,path,count in sets:
    sheet=Image.open(path).convert('RGBA')
    for n in range(count):
        x,y=n%3,n//3
        crop=sheet.crop((x*sheet.width//3,y*sheet.height//2,(x+1)*sheet.width//3,(y+1)*sheet.height//2))
        # Ignore near-transparent generated fringe when finding the sprite bounds.
        bounds=crop.getchannel('A').point(lambda a:255 if a>24 else 0).getbbox()
        crop=crop.crop(bounds)
        crop.thumbnail((232,232),Image.Resampling.LANCZOS)
        index=n+(0 if prefix=='creature' else 6)
        pos=((index%4)*256+(256-crop.width)//2,(index//4)*256+244-crop.height)
        atlas.alpha_composite(crop,pos)
        manifest[f'{prefix}_{n}']={'frame':index,'size':list(crop.size)}
tree=Image.open(root/'assets/tree.png').convert('RGBA')
tree.thumbnail((224,224),Image.Resampling.LANCZOS)
atlas.alpha_composite(tree,(0*256+(256-tree.width)//2,3*256+244-tree.height))
manifest['tree']={'frame':12}
# Original camp and villager sprites complete the same texture atlas.
d=ImageDraw.Draw(atlas)
def poly(points,fill):d.polygon(points,fill=fill)
ox,oy=256,768
poly([(ox+30,oy+213),(ox+125,oy+77),(ox+225,oy+213)],'#e8c78b')
poly([(ox+125,oy+77),(ox+138,oy+213),(ox+225,oy+213)],'#ae7656')
poly([(ox+75,oy+213),(ox+125,oy+113),(ox+161,oy+213)],'#493e3b')
d.line((ox+125,oy+70,ox+125,oy+218),fill='#846044',width=5)
d.ellipse((ox+205,oy+200,ox+225,oy+217),fill='#c4aa7c')
ox,oy=512,768
d.ellipse((ox+100,oy+173,ox+158,oy+231),fill='#64918a')
d.ellipse((ox+105,oy+135,ox+153,oy+184),fill='#efc49a')
d.ellipse((ox+100,oy+128,ox+157,oy+157),fill='#784e3b')
atlas.save(out/'world-atlas.png',optimize=True)
manifest['camp']={'frame':13}
manifest['villager']={'frame':14}
(out/'atlas.json').write_text(json.dumps(manifest,indent=2))
# Keep synthesis out of GDScript startup. Seamless wind/rain, original local audio.
for name,volume in [('wind',.05),('rain-loop',.08)]:
    rng=random.Random(42); smooth=0
    samples=[]
    for i in range(44100*3):
        smooth=smooth*.94+rng.uniform(-1,1)*.06
        v=(smooth if name=='wind' else rng.uniform(-1,1)*.35+smooth)*volume
        samples.append(struct.pack('<h',int(v*32767)))
    with wave.open(str(out/f'{name}.wav'),'wb') as f:
        f.setparams((1,2,44100,0,'NONE','NONE'));f.writeframes(b''.join(samples))
print('Prepared 1024px shared atlas, original camp/villager, and ambient loops.')
