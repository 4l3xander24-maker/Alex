"""Mezcla final del tráiler: música sintetizada (audio.py) + efectos reales de Mixkit (trailer/sfx_raw).
Mixkit Sound Effects Free License: uso comercial libre, sin atribución; no se redistribuyen los archivos sueltos."""
import subprocess, sys, numpy as np
sys.path.insert(0, ".")
from audio import Mix, music, SR, fr

RAW = "sfx_raw/"
_cache = {}
def load(name):
    if name not in _cache:
        raw = subprocess.run(["ffmpeg","-v","error","-i",RAW+name+".mp3","-f","f32le","-ac","2","-ar",str(SR),"-"],
                             capture_output=True, check=True).stdout
        a = np.frombuffer(raw, dtype=np.float32).reshape(-1, 2).T.copy()
        _cache[name] = a.mean(0)
    return _cache[name]

def smp(name, start=0.0, dur=None, gain=1.0, fin=0.004, fout=0.05, pitch=1.0, norm=True):
    a = load(name)
    if pitch != 1.0:
        idx = np.arange(0, len(a)-1, pitch)
        a = np.interp(idx, np.arange(len(a)), a)
    i = int(start*SR); a = a[i:i+int(dur*SR)] if dur else a[i:]
    a = a.copy()
    if norm and len(a): a /= max(np.abs(a).max(), 1e-6)
    n = len(a); fi = min(n, int(fin*SR)); fo = min(n, int(fout*SR))
    if fi: a[:fi] *= np.linspace(0,1,fi)
    if fo: a[-fo:] *= np.linspace(1,0,fo)
    return a*gain

def tail(name, last, **kw):  # los últimos `last` segundos (para risers que terminan en el golpe)
    a = load(name); start = max(0, len(a)/SR - last)
    return smp(name, start, **kw)

def shots(m, name, t0, n, step, gain, dur, pitch=1.0, pan=0.0, jitter=0.12):
    rng = np.random.default_rng(int(t0*1000)+n)
    for i in range(n):
        g = gain*(1-jitter*rng.random())
        m.add(smp(name, 0, dur, g, fout=0.04, pitch=pitch*(1+0.04*rng.standard_normal())), t0+i*step, 1.0, pan+0.15*rng.standard_normal())

def music_bus(dur, drop, tolls, end):
    m = Mix(dur)
    music(m, dur, drop, tolls, end)
    m.L *= 0.72; m.R *= 0.72
    return m

def story_sfx(m, k=1.0, t_off=0.0):
    f = lambda frames: t_off + fr(frames*k)
    # viento y aullido de fondo durante el cuento
    m.add(smp("graveyard_wind", 0, 9.5*k, 0.30, fin=0.8, fout=1.2), t_off, 1.0)
    m.add(smp("wolf_howl", 0, 5*k, 0.22, fin=0.4, fout=1.0), t_off+2.0*k, 1.0, 0.4)
    # campanadas reales
    for fr_, g in [(6,0.9),(106,0.9),(206,1.0)]:
        m.add(smp("church_bell", 0, 5.0*k+1.5, g, fin=0.003, fout=1.2, norm=True), f(fr_), 1.0, -0.15)
    m.add(smp("heartbeat_impact", 0, 3.0, 0.5, fout=0.8), f(150), 1.0)
    # gruñidos al abrirse el iris
    m.add(smp("zombie_growl", 0, 2.2, 0.75, fout=0.4), f(236), 1.0, -0.3)
    m.add(smp("zombie_grunt", 0, 1.5, 0.6, fout=0.3), f(262), 1.0, 0.3)
    m.add(smp("zombie_roar", 0, 1.0, 0.7, fout=0.2), f(284), 1.0, 0.0)

def build_long(path):
    m = music_bus(36.0, 10.0, [(0.2,196),(3.4,196),(6.6,174.6)], 32.0)
    story_sfx(m)
    # subida y golpe del drop
    m.add(tail("horror_sweep", 4.0, gain=0.8, fin=0.5, fout=0.01), 6.0, 1.0)
    m.add(tail("reverse_impact", 2.4, gain=0.9, fin=0.2, fout=0.01), 7.6, 1.0)
    m.add(smp("trailer_impact", 0, 3.5, 1.0, fout=1.0), 10.0, 1.0)
    m.add(smp("zoom_impact", 0, 1.2, 0.8), 10.0, 1.0)
    cuts = [364,428,492,556,620,684,812,960]
    for i, c in enumerate(cuts):
        nm = ["whoosh_fast","whoosh_fast2","windy_swoosh","whoosh_fast"][i%4]
        m.add(smp(nm, 0, 0.7, 0.75, fout=0.15), fr(c-10), 1.0, (-0.3 if i%2 else 0.3))
        m.add(smp(["zoom_impact","horror_impact","zoom_impact"][i%3], 0, 1.0, 0.55, fout=0.3), fr(c), 1.0)
    # B1 fusil
    shots(m, "gun_shot", fr(300)+0.3, 7, 0.19, 0.8, 0.32, pan=0.1)
    # B2 lanzallamas
    m.add(smp("fire_woosh", 0, 2.0, 0.8, fout=0.4), fr(366), 1.0)
    m.add(smp("fire_beam", 1.0, 2.4, 0.7, fin=0.15, fout=0.5), fr(368), 1.0)
    # B3 arsenal: fusil, minigun, ballesta
    shots(m, "gun_shot", fr(430), 4, 0.22, 0.65, 0.3, pan=-0.45)
    shots(m, "gun_shot", fr(430)+0.15, 9, 0.085, 0.5, 0.11, pitch=1.2, pan=0.0)
    m.add(smp("arrow_whoosh", 0, 1.0, 0.75), fr(430)+0.4, 1.0, 0.5)
    m.add(smp("small_hit", 0, 0.5, 0.6), fr(430)+0.9, 1.0, 0.5)
    m.add(smp("arrow_whoosh", 0, 1.0, 0.7), fr(430)+1.3, 1.0, 0.5)
    # B4 cifras
    m.add(smp("positive_ui", 0, 1.2, 0.5, fout=0.4), fr(492), 1.0)
    for i in range(4):
        m.add(smp("ball_tap", 0, 0.3, 0.9, pitch=1.0+0.18*i), fr(492)+(6+i*5)/30, 1.0, -0.4+0.27*i)
    # B5 combo
    shots(m, "gun_shot", fr(556)+0.05, 11, 0.088, 0.5, 0.11, pitch=1.15)
    for i in range(22):
        m.add(smp("retro_click", 0, 0.1, 0.55, pitch=0.9+0.035*i), fr(556)+(4+i*2.3)/30, 1.0)
    m.add(smp("small_hit", 0, 0.5, 0.7), fr(556)+1.8, 1.0)
    # B6 jefe
    m.add(smp("emergency_alert", 0, 2.3, 0.55, fin=0.02, fout=0.3), fr(620), 1.0)
    m.add(smp("horror_hit_drum", 0, 2.0, 0.9, fout=0.6), fr(620), 1.0)
    m.add(smp("giant_roar", 0, 2.6, 1.0, fout=0.6), fr(620)+0.35, 1.0)
    # B7 amigos
    m.add(smp("sparkle_whoosh", 0, 1.8, 0.55, fout=0.5), fr(684), 1.0)
    for i in range(5):
        m.add(smp("ball_tap", 0, 0.3, 0.85, pitch=0.9+0.13*i), fr(684)+(20+i*8)/30, 1.0, -0.5+0.25*i)
    m.add(smp("far_war", 0, 4.0, 0.25, fin=0.5, fout=1.0), fr(700), 1.0)
    # B8 clímax
    shots(m, "gun_shot", fr(812)+0.05, 20, 0.093, 0.5, 0.11, pitch=1.15)
    for i, nm in enumerate(["zombie_growl","zombie_roar","zombie_grunt","zombie_gasp"]):
        m.add(smp(nm, 0, 1.6, 0.6, fout=0.3), fr(812)+0.3+i*0.65, 1.0, (-0.4,0.4,-0.2,0.2)[i])
    m.add(smp("fire_big", 0, 2.0, 0.6, fin=0.1, fout=0.5), fr(812)+1.9, 1.0)
    m.add(smp("gun_echo", 0, 2.5, 0.6, fout=1.0), fr(812)+3.4, 1.0)
    # cierre
    m.add(smp("movie_logo_impact", 0, 4.5, 1.0, fout=1.4), 32.0, 1.0)
    m.add(smp("church_bell", 0, 3.5, 0.6, fout=1.2), 32.0, 1.0)
    m.add(smp("glitter_shot", 0, 2.2, 0.55, fout=0.8), 32.15, 1.0)
    m.add(smp("level_complete", 0, 2.5, 0.65, fout=0.8), 33.55, 1.0)
    m.save(path)

def build_short(path):
    m = music_bus(24.0, 8.0, [(0.15,196),(2.6,196),(4.4,174.6),(6.3,196)], 20.0)
    # gancho: 4 golpes
    for i, f in enumerate([0,19,38,57]):
        m.add(smp("zoom_impact", 0, 1.0, 0.8, fout=0.25), fr(f), 1.0)
        m.add(smp(["whoosh_fast","windy_swoosh"][i%2], 0, 0.6, 0.55, fout=0.12), max(0, fr(f)-0.2), 1.0)
        shots(m, "gun_shot", fr(f)+0.04, 3, 0.1, 0.6, 0.12, pitch=1.15)
    m.add(smp("zombie_roar", 0, 1.0, 0.6, fout=0.2), 1.1, 1.0)
    m.add(smp("heartbeat_impact", 0, 2.4, 0.5, fout=0.6), 0.3, 1.0)
    # cuento comprimido (k=.55) empezando en el frame 75
    story_sfx(m, k=0.55, t_off=fr(75))
    m.add(tail("horror_sweep", 3.5, gain=0.8, fin=0.4, fout=0.01), 4.5, 1.0)
    m.add(tail("reverse_impact", 2.2, gain=0.9, fin=0.2, fout=0.01), 5.8, 1.0)
    m.add(smp("trailer_impact", 0, 3.5, 1.0, fout=1.0), 8.0, 1.0)
    m.add(smp("zoom_impact", 0, 1.2, 0.8), 8.0, 1.0)
    for i, c in enumerate([304,368,432,496,596]):
        m.add(smp(["whoosh_fast","whoosh_fast2","windy_swoosh"][i%3], 0, 0.7, 0.75, fout=0.15), fr(c-10), 1.0, (-0.3 if i%2 else 0.3))
        m.add(smp(["zoom_impact","horror_impact"][i%2], 0, 1.0, 0.55, fout=0.3), fr(c), 1.0)
    shots(m, "gun_shot", fr(240)+0.3, 7, 0.19, 0.8, 0.32, pan=0.1)
    m.add(smp("fire_woosh", 0, 2.0, 0.8, fout=0.4), fr(306), 1.0)
    m.add(smp("fire_beam", 1.0, 2.2, 0.7, fin=0.15, fout=0.5), fr(308), 1.0)
    shots(m, "gun_shot", fr(368)+0.05, 11, 0.088, 0.5, 0.11, pitch=1.15)
    for i in range(22):
        m.add(smp("retro_click", 0, 0.1, 0.55, pitch=0.9+0.035*i), fr(368)+(4+i*2.3)/30, 1.0)
    m.add(smp("emergency_alert", 0, 2.3, 0.55, fin=0.02, fout=0.3), fr(432), 1.0)
    m.add(smp("horror_hit_drum", 0, 2.0, 0.9, fout=0.6), fr(432), 1.0)
    m.add(smp("giant_roar", 0, 2.6, 1.0, fout=0.6), fr(432)+0.35, 1.0)
    shots(m, "gun_shot", fr(496)+0.05, 16, 0.093, 0.5, 0.11, pitch=1.15)
    m.add(smp("zombie_growl", 0, 1.6, 0.6, fout=0.3), fr(496)+0.5, 1.0, -0.3)
    m.add(smp("movie_logo_impact", 0, 4.5, 1.0, fout=1.4), fr(596), 1.0)
    m.add(smp("church_bell", 0, 3.5, 0.6, fout=1.2), fr(596), 1.0)
    m.add(smp("glitter_shot", 0, 2.2, 0.55, fout=0.8), fr(596)+0.15, 1.0)
    m.add(smp("level_complete", 0, 2.5, 0.65, fout=0.8), fr(596)+1.55, 1.0)
    m.save(path)

if __name__ == "__main__":
    out = sys.argv[1]
    build_long(out+"/music.wav"); print("largo ok")
    build_short(out+"/music_short.wav"); print("corto ok")
