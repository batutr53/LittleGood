"""Deterministic original mono PCM cues; no runtime synthesis or licensed samples."""
from pathlib import Path
import math,random,struct,wave
out=Path(__file__).resolve().parents[1]/'assets/adventure/audio';out.mkdir(exist_ok=True)
for name,freq,duration,noise in [('step',130,.065,.75),('switch',640,.12,.12),('door',90,.3,.6),('trap_warning',880,.14,.05),('trap_active',170,.16,.75),('swing',240,.12,.8),('impact',145,.1,.6),('relic',660,.5,.02)]:
 rng=random.Random(230);samples=[];rate=22050
 for i in range(int(duration*rate)):
  t=i/rate;envelope=math.sin(math.pi*min(1,t/duration))**.6*math.exp(-t*4)
  pitch=freq*(1-.35*t/duration) if name in ['swing','door'] else freq
  value=(math.sin(2*math.pi*pitch*t)*(1-noise)+rng.uniform(-1,1)*noise)*envelope*.17
  if name=='relic':value+=math.sin(2*math.pi*freq*1.5*t)*envelope*.08
  samples.append(struct.pack('<h',int(max(-1,min(1,value))*32767)))
 with wave.open(str(out/(name+'.wav')),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(b''.join(samples))
