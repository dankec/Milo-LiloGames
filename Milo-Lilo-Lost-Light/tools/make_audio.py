"""Generate original chiptune-style music and SFX using only Python stdlib."""
from pathlib import Path
import math, wave, struct
OUT=Path(__file__).resolve().parents[1]/'assets'/'audio'; OUT.mkdir(parents=True,exist_ok=True)
RATE=22050

def write(name,samples):
    with wave.open(str(OUT/name),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE)
        f.writeframes(struct.pack('<'+'h'*len(samples),*(max(-32767,min(32767,int(s*13000))) for s in samples)))
def note(t,f,soft=True):
    if f<=0: return 0
    return math.sin(2*math.pi*f*t)*.75 + math.sin(2*math.pi*f*2*t)*(.13 if soft else .25)
for name,melody in {
    'meadow':[392,494,587,659,587,494,440,392,349,440,523,587,523,440,392,0],
    'forest':[330,392,440,494,440,392,330,294,330,392,523,494,440,392,349,0],
    'cave':[220,0,261.6,293.7,0,261.6,220,196,220,261.6,329.6,293.7,261.6,220,196,0],
    'night':[293.7,349.2,392,440,392,349.2,293.7,261.6,293.7,392,440,523,440,392,349.2,0],
    'lighthouse':[392,523,659,784,659,587,523,392,440,523,659,880,784,659,523,392],
}.items():
    # 16 * 0.45 = 7.2 seconds; repeat as seamless melody.
    samples=[]; duration=0.45
    for freq in melody:
        for n in range(int(duration*RATE)):
            t=n/RATE; env=min(1,t/.06)*min(1,(duration-t)/.09)
            samples.append(note(t,freq)*env*.16 + note(t,freq/2)*env*.04)
    write(name+'.wav',samples)
for name,frequencies in {'coin':[660,880,1174],'jump':[440,630],'hurt':[240,190],'win':[523,659,784,1047],'switch':[460,660],'hit':[170,120],'chest':[392,523,659,880]}.items():
    samples=[];duration=.105
    for freq in frequencies:
        for n in range(int(duration*RATE)):
            t=n/RATE;env=max(0,1-t/duration)**1.1
            samples.append(note(t,freq,False)*env*.34)
    write('sfx_'+name+'.wav',samples)
print('Generated original music and SFX')
