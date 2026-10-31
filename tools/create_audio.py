"""A quiet original looping music-box bed; no external sound recordings."""
import math, wave, struct
from pathlib import Path
rate=22050
duration=24
chords=[(261.626,329.628,391.995),(220,261.626,329.628),(174.614,220,261.626),(195.998,246.942,293.665)]
data=bytearray()
for i in range(rate*duration):
    t=i/rate
    chord=chords[int(t//6)]
    phase=t%6
    env=math.sin(math.pi*phase/6)**2
    value=sum(math.sin(2*math.pi*f*t)*0.13 for f in chord)*env
    # Six evenly spaced soft bell notes in each chord.
    nt=t%1.5
    note=chord[int(phase/1.5)%3]*2
    bell=(math.sin(2*math.pi*note*t)+0.15*math.sin(2*math.pi*note*2*t))*math.exp(-nt*4)*min(nt*65,1)*0.16
    value+=bell
    value*=min(t*3,1,(duration-t)*3)
    data.extend(struct.pack('<h',int(value*24000)))
p=Path(__file__).resolve().parents[1]/'assets'/'roomtone.wav'
with wave.open(str(p),'wb') as f:
    f.setnchannels(1); f.setsampwidth(2); f.setframerate(rate); f.writeframes(data)
