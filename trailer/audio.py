import numpy as np, wave, sys
SR=44100
rng=np.random.default_rng(11)

def tt(d): return np.arange(int(d*SR))/SR
def lp(x,a):  # filtro paso bajo de un polo
    y=np.empty_like(x); acc=0.0
    for i,v in enumerate(x):
        acc+=a*(v-acc); y[i]=acc
    return y
def hp(x,a): return x-lp(x,a)

# ---------- sonidos ----------
def noise(d): return rng.standard_normal(int(d*SR))
def shot(kind="rifle"):
    d={"rifle":0.22,"pistol":0.16,"mini":0.08,"cross":0.3}[kind]
    t=tt(d); n=hp(noise(d),0.15)*np.exp(-t*(30 if kind!="mini" else 55))
    thump=np.sin(2*np.pi*(150*np.exp(-t*40)+55)*t)*np.exp(-t*(22 if kind!="mini" else 40))
    s=n*0.7+thump*(0.9 if kind!="pistol" else 0.6)
    if kind=="cross":
        s=np.sin(2*np.pi*(420*np.exp(-t*6)+160)*t)*np.exp(-t*12)*0.7+hp(noise(d),0.3)*np.exp(-t*60)*0.5
    return s*0.8
def flame(d=1.6):
    t=tt(d); n=lp(noise(d),0.12)*3
    am=0.65+0.35*np.sin(2*np.pi*9*t+np.sin(t*3))
    env=np.minimum(1,t*8)*np.minimum(1,(d-t)*5)
    return n*am*env*0.8
def growl(d=0.9,f=62,rough=1.0):
    t=tt(d); vib=np.sin(2*np.pi*5.5*t)*6
    ph=2*np.pi*np.cumsum(f*(1+0.25*np.sin(2*np.pi*1.8*t))+vib)/SR
    saw=(2*((ph/(2*np.pi))%1)-1)
    s=lp(saw,0.08)*1.8+lp(noise(d),0.05)*0.8*rough
    env=np.sin(np.pi*np.clip(t/d,0,1))**0.7
    return s*env*0.7
def roar(d=1.4): return growl(d,48,1.6)*1.1
def whoosh(d=0.45,up=True):
    t=tt(d); n=noise(d); y=np.empty_like(n); acc=0.0
    for i in range(len(n)):
        k=(i/len(n)); a=0.02+0.5*(k if up else 1-k)**2
        acc+=a*(n[i]-acc); y[i]=acc
    env=(t/d)**1.6 if up else (1-t/d)**1.6
    return y*env*2.2
def thump(d=0.45):
    t=tt(d); return np.sin(2*np.pi*(95*np.exp(-t*18)+38)*t)*np.exp(-t*7)*1.0
def impact(d=1.6):
    t=tt(d); return (np.sin(2*np.pi*(60*np.exp(-t*3)+32)*t)*np.exp(-t*2.5)+lp(noise(d),0.2)*np.exp(-t*7)*0.9)*0.9
def pop(f=640,d=0.14):
    t=tt(d); return np.sin(2*np.pi*(f+f*0.6*t/d)*t)*np.exp(-t*24)*0.7
def tick(d=0.05):
    t=tt(d); return np.sin(2*np.pi*1700*t)*np.exp(-t*90)*0.5
def siren(d=2.2):
    t=tt(d); f=620+260*np.sin(2*np.pi*1.6*t)
    ph=2*np.pi*np.cumsum(f)/SR; s=np.sign(np.sin(ph))*0.3+np.sin(ph)*0.5
    return lp(s,0.35)*np.minimum(1,t*6)*np.minimum(1,(d-t)*4)*0.7
def sparkle(d=1.2):
    t=tt(d); s=np.zeros_like(t)
    for k,f in enumerate([1568,2093,2637,3136,4186]):
        s+=np.sin(2*np.pi*f*t)*np.exp(-(t-k*0.05).clip(0)*5)*(t>k*0.05)*0.18
    return s
def riser(d):
    t=tt(d); n=hp(noise(d),0.2); return n*(t/d)**2*0.32
def bell(f=196.0,d=6.0):
    t=tt(d); s=np.zeros_like(t)
    for k,(m,a,dec) in enumerate([(1,1,1.1),(2.0,.7,1.6),(2.76,.55,2.2),(5.4,.35,3.5),(8.9,.2,5)]):
        s+=a*np.sin(2*np.pi*f*m*t+k)*np.exp(-t*dec*0.55)
    s*=np.minimum(1,t*400); return s/np.abs(s).max()*0.6
def kick(d=0.38):
    t=tt(d); f=120*np.exp(-t*22)+42
    return np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-t*9)*0.9
def hat(): 
    t=tt(0.08); return hp(noise(0.08),0.5)*np.exp(-t*60)*0.12
def clap():
    t=tt(0.22); return hp(noise(0.22),0.4)*np.exp(-t*22)*0.5
def bass(f,d):
    t=tt(d); s=np.sign(np.sin(2*np.pi*f*t))*0.5+np.sin(2*np.pi*f*t)
    return s*np.exp(-t*5)*0.5

class Mix:
    def __init__(self,dur):
        self.N=int(SR*dur); self.L=np.zeros(self.N); self.R=np.zeros(self.N); self.dur=dur
    def add(self,sig,t0,gain=1.0,pan=0.0):
        i=int(t0*SR)
        if i<0 or i>=self.N: return
        j=min(self.N,i+len(sig)); s=sig[:j-i]*gain
        self.L[i:j]+=s*(1-max(0,pan)); self.R[i:j]+=s*(1+min(0,pan))
    def save(self,path,fade=1.5):
        t=np.arange(self.N)/SR
        m=max(abs(self.L).max(),abs(self.R).max()); L=self.L/m/1.08; R=self.R/m/1.08
        f=np.clip((self.dur-t)/fade,0,1); L*=f; R*=f
        data=(np.stack([L,R],1)*32767).astype(np.int16)
        w=wave.open(path,"wb"); w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes()); w.close()

BPM=112; B=60/BPM
def music(m,dur,drop,tolls,end,hb_end=None,intro_hits=()):
    t=np.arange(m.N)/SR
    env=np.clip(t/max(drop*0.8,1),0,1)**1.2*np.where(t>end,np.clip((dur-t)/4,0,1),1)
    drone=(np.sin(2*np.pi*55*t)+0.5*np.sin(2*np.pi*82.41*t+np.sin(t*0.4))+0.25*np.sin(2*np.pi*110*t))*0.22*env
    m.L+=drone; m.R+=drone
    for t0,f in tolls: m.add(bell(f),t0,1.0,-0.2)
    k=0; tcur=0.6
    while tcur<drop-0.6:
        m.add(kick(),tcur,0.35*(0.5+tcur/(2*drop))); tcur+=B*2.0
    m.add(riser(min(2.4,drop-0.3)),drop-min(2.4,drop-0.3),1.0)
    m.add(impact(),drop,1.0); m.add(bell(98,6),drop,0.9)
    beats=int((end-drop)/B)
    for k in range(beats):
        t0=drop+k*B
        m.add(kick(),t0,0.95); m.add(hat(),t0+B/2,1.0,0.3)
        if k%2==1: m.add(clap(),t0,0.6,-0.1)
        note=[55,55,65.4,49][(k//4)%4]
        m.add(bass(note,B/2),t0,0.8); m.add(bass(note,B/2),t0+B/2,0.6)
        if k%8==0: m.add(bell(196 if (k//8)%2==0 else 174.6,4),t0,0.45,0.3)
    m.add(impact(),end,0.9); m.add(bell(130.8,6),end,1.0); m.add(bell(196,5),end+0.9,0.5,0.2)

def fr(f): return f/30.0

# ============ LARGO (36 s) ============
def build_long(path):
    m=Mix(36.0)
    music(m,36.0,10.0,[(0.2,196),(3.4,196),(6.6,174.6)],32.0)
    for k,tt_ in enumerate([8.0,8.5,9.0]): m.add(growl(0.9,60+k*8),tt_,0.55,(-0.3,0.3,0)[k])
    cuts=[300,364,428,492,556,620,684,812,960]
    for f in cuts[1:]:
        m.add(whoosh(0.4,True),fr(f-8),0.7); m.add(thump(),fr(f),0.7)
    # B1 golpe (300-364): fusil
    for i in range(7): m.add(shot("rifle"),fr(300)+0.35+i*0.19,0.55,0.15)
    # B2 lanzallamas
    m.add(flame(2.0),fr(366),0.7)
    # B3 arsenal
    for i in range(4): m.add(shot("rifle"),fr(430)+i*0.22,0.5,-0.4)
    for i in range(8): m.add(shot("mini"),fr(430)+0.2+i*0.09,0.45,0.0)
    for i in range(2): m.add(shot("cross"),fr(430)+0.4+i*0.7,0.5,0.4)
    # B4 cifras
    for i in range(4): m.add(pop(520+i*130),fr(492)+(6+i*5)/30,0.9,(-0.4,-0.1,0.1,0.4)[i])
    m.add(tick(),fr(492)+0.5,0.8)
    # B5 combo
    for i in range(10): m.add(shot("mini"),fr(556)+0.1+i*0.095,0.5)
    for i in range(22): m.add(tick(),fr(556)+(4+i*2.3)/30,0.6)
    # B6 jefe
    m.add(siren(2.2),fr(620),0.55); m.add(roar(1.5),fr(620)+0.3,0.9)
    m.add(thump(),fr(620)+0.6,1.0)
    # B7 amigos
    for i in range(5): m.add(pop(480+i*90,0.16),fr(684)+(20+i*8)/30,0.8,(-0.5+i*0.25))
    m.add(whoosh(0.5,True),fr(684)+0.2,0.5)
    # B8 clímax
    for i in range(18): m.add(shot("mini"),fr(812)+0.1+i*0.095,0.45)
    for k in range(4): m.add(growl(0.8,55+k*6),fr(812)+0.3+k*0.7,0.6,(-0.4,0.4,-0.2,0.2)[k])
    m.add(flame(1.5),fr(812)+1.9,0.6)
    # remate
    m.add(sparkle(),fr(960)+0.05,0.8); m.add(pop(900,0.2),fr(960)+50/30,1.0)
    m.save(path)

# ============ CORTO (24 s) ============
def build_short(path):
    m=Mix(24.0)
    music(m,24.0,8.0,[(0.15,196),(2.6,196),(4.4,174.6),(6.3,196)],20.0)
    # gancho (0-2.5 s): 4 golpes
    for i,f in enumerate([0,19,38,57]):
        m.add(thump(),fr(f),0.9); m.add(whoosh(0.3,True),fr(f)-0.2 if f>0 else 0,0.6)
        m.add(shot("rifle") if i%2==0 else shot("mini"),fr(f)+0.05,0.7)
    m.add(growl(1.2,58),0.9,0.6)
    # cuento
    m.add(growl(0.9,62),fr(196),0.5,-0.3); m.add(growl(0.9,70),fr(205),0.5,0.3)
    # montaje 4 bloques de 64 f desde 240
    for f in [304,368,432,496]:
        m.add(whoosh(0.4,True),fr(f-8),0.7); m.add(thump(),fr(f),0.7)
    for i in range(7): m.add(shot("rifle"),fr(240)+0.35+i*0.19,0.55,0.15)
    m.add(flame(2.0),fr(306),0.7)
    for i in range(10): m.add(shot("mini"),fr(368)+0.1+i*0.095,0.5)
    for i in range(22): m.add(tick(),fr(368)+(4+i*2.3)/30,0.6)
    m.add(siren(2.2),fr(432),0.55); m.add(roar(1.5),fr(432)+0.3,0.9)
    for i in range(14): m.add(shot("mini"),fr(496)+0.1+i*0.095,0.45)
    m.add(growl(0.8,55),fr(496)+0.4,0.6)
    m.add(sparkle(),fr(596)+0.05,0.8); m.add(pop(900,0.2),fr(596)+50/30,1.0)
    m.save(path)

if __name__=="__main__":
    out=sys.argv[1]
    build_long(out+"/music.wav"); print("largo ok")
    build_short(out+"/music_short.wav"); print("corto ok")
