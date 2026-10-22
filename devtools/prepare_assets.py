from PIL import Image
from pathlib import Path
import wave, math, struct
root=Path(__file__).resolve().parent.parent
source=Path(r'C:\Users\batua\.codex\generated_images\01a163ae-d724-7830-80ba-6b39304c80cc\exec-97940bd4-6bba-47f9-b06a-13fc247560c0.png')
if source.exists():
    im=Image.open(source).convert('RGBA')
    im=im.crop(im.getbbox())
    im.thumbnail((256,256),Image.Resampling.LANCZOS)
    im.save(root/'assets/tree.png')
for name,freq in [('discovery',660),('water',330),('forest',400),('mountain',220),('wildlife',550),('rain',440),('bless',770),('button',880)]:
    with wave.open(str(root/f'assets/{name}.wav'),'wb') as f:
        f.setparams((1,2,22050,0,'NONE','not compressed'))
        f.writeframes(b''.join(struct.pack('<h',int(5000*(math.sin(t*math.tau*freq)+.3*math.sin(t*math.tau*freq*1.5))*math.exp(-t*7))) for t in (i/22050 for i in range(13230))))
print('Prepared original tree sprite and eight synthesized sound assets.')
