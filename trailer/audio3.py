"""Audio de la tanda de videos cortos (15 s): música sintetizada + efectos Mixkit (sfx_raw)."""
import sys
sys.path.insert(0, ".")
from audio2 import Mix, smp, tail, shots, music_bus, fr

DUR = 15.0
def base(drop=0.8):
    return music_bus(DUR, drop, [(0.1, 196)], 12.0)

def cuts(m, frames):
    for i, c in enumerate(frames):
        nm = ["whoosh_fast", "whoosh_fast2", "windy_swoosh", "whoosh_fast"][i % 4]
        m.add(smp(nm, 0, 0.7, 0.75, fout=0.15), fr(c-10), 1.0, (-0.3 if i % 2 else 0.3))
        m.add(smp(["zoom_impact", "horror_impact"][i % 2], 0, 1.0, 0.55, fout=0.3), fr(c), 1.0)

def end_card(m, f=360):
    t = fr(f)
    m.add(smp("movie_logo_impact", 0, 4.0, 1.0, fout=1.2), t, 1.0)
    m.add(smp("church_bell", 0, 3.0, 0.6, fout=1.0), t, 1.0)
    m.add(smp("glitter_shot", 0, 2.0, 0.55, fout=0.7), t+0.15, 1.0)
    m.add(smp("level_complete", 0, 2.2, 0.65, fout=0.7), t+1.55, 1.0)

def boss(path):
    m = base(); cuts(m, [64, 200, 360])
    m.add(smp("emergency_alert", 0, 2.3, 0.55, fin=0.02, fout=0.3), 0.0, 1.0)
    m.add(smp("horror_hit_drum", 0, 2.0, 0.9, fout=0.6), 0.0, 1.0)
    m.add(smp("giant_roar", 0, 2.6, 1.0, fout=0.6), 0.35, 1.0)
    shots(m, "gun_shot", fr(64)+0.4, 14, 0.093, 0.5, 0.11, pitch=1.15)
    m.add(smp("zombie_roar", 0, 1.0, 0.7, fout=0.2), fr(100), 1.0, 0.3)
    shots(m, "gun_shot", fr(200)+0.3, 10, 0.19, 0.7, 0.32, pan=0.1)
    m.add(smp("giant_roar", 0, 2.0, 0.7, fout=0.5), fr(260), 1.0)
    end_card(m); m.save(path)

def combo(path):
    m = base(); cuts(m, [64, 200, 360])
    shots(m, "gun_shot", 0.1, 11, 0.088, 0.55, 0.11, pitch=1.15)
    for i in range(22): m.add(smp("retro_click", 0, 0.1, 0.55, pitch=0.9+0.035*i), fr(4+i*2.3), 1.0)
    m.add(smp("small_hit", 0, 0.5, 0.7), 1.8, 1.0)
    shots(m, "gun_shot", fr(64)+0.2, 16, 0.09, 0.5, 0.11, pitch=1.2)
    m.add(smp("positive_ui", 0, 1.2, 0.45, fout=0.4), fr(200), 1.0)
    shots(m, "gun_shot", fr(200)+0.4, 20, 0.088, 0.5, 0.11, pitch=1.15)
    end_card(m); m.save(path)

def arms(path):
    m = base(); cuts(m, [150, 214, 278, 360])
    shots(m, "gun_shot", 0.3, 5, 0.2, 0.7, 0.3, pan=-0.3)
    shots(m, "gun_shot", 1.8, 9, 0.085, 0.5, 0.11, pitch=1.2)
    shots(m, "gun_shot", fr(150)+0.1, 4, 0.22, 0.65, 0.3, pan=-0.45)
    shots(m, "gun_shot", fr(150)+0.3, 9, 0.085, 0.5, 0.11, pitch=1.2)
    m.add(smp("arrow_whoosh", 0, 1.0, 0.75), fr(150)+0.9, 1.0, 0.5)
    m.add(smp("fire_woosh", 0, 2.0, 0.8, fout=0.4), fr(216), 1.0)
    m.add(smp("fire_beam", 1.0, 2.2, 0.7, fin=0.15, fout=0.5), fr(218), 1.0)
    m.add(smp("arrow_whoosh", 0, 1.0, 0.75), fr(282), 1.0, 0.4)
    m.add(smp("small_hit", 0, 0.5, 0.6), fr(282)+0.6, 1.0, 0.4)
    m.add(smp("arrow_whoosh", 0, 1.0, 0.7), fr(282)+1.4, 1.0, -0.3)
    end_card(m); m.save(path)

def how(path):
    m = base(); cuts(m, [90, 180, 270, 360])
    m.add(smp("zombie_growl", 0, 1.8, 0.6, fout=0.3), 1.0, 1.0, -0.3)
    for i in range(3): m.add(smp("ball_tap", 0, 0.3, 0.85, pitch=0.9+0.15*i), fr(10+i*8)+0.3, 1.0)
    for k, s in enumerate([90, 180, 270]):
        m.add(smp("pops_whoosh", 0, 0.18, 0.9), fr(s)+0.1, 1.0)
        m.add(smp("positive_ui", 0, 0.9, 0.4, fout=0.3), fr(s)+0.15, 1.0)
        m.add(smp("ball_tap", 0, 0.3, 0.9, pitch=1.0+0.2*k), fr(s+8), 1.0)
    m.add(smp("sparkle_whoosh", 0, 1.6, 0.5, fout=0.5), fr(90), 1.0)
    shots(m, "gun_shot", fr(180)+0.5, 8, 0.12, 0.5, 0.18, pitch=1.1)
    shots(m, "gun_shot", fr(270)+0.4, 6, 0.2, 0.6, 0.3, pan=0.2)
    end_card(m); m.save(path)

def night(path):
    m = base(drop=2.0)
    m.add(smp("graveyard_wind", 0, 12.0, 0.30, fin=0.6, fout=1.5), 0.0, 1.0)
    m.add(smp("wolf_howl", 0, 5.0, 0.22, fin=0.4, fout=1.0), 1.5, 1.0, 0.4)
    for t in (0.3, 4.4, 8.3): m.add(smp("church_bell", 0, 4.0, 0.9, fout=1.0), t, 1.0, -0.15)
    m.add(smp("heartbeat_impact", 0, 3.0, 0.5, fout=0.8), 2.5, 1.0)
    for i, nm in enumerate(["zombie_growl", "zombie_grunt", "zombie_roar", "zombie_gasp"]):
        m.add(smp(nm, 0, 1.6, 0.6, fout=0.3), 1.0+i*1.7, 1.0, (-0.4, 0.4, -0.2, 0.2)[i])
    cuts(m, [130, 250, 360])
    shots(m, "gun_shot", fr(250)+0.3, 10, 0.19, 0.7, 0.32, pan=0.1)
    m.add(smp("fire_big", 0, 2.0, 0.55, fin=0.1, fout=0.5), fr(260), 1.0)
    end_card(m); m.save(path)

if __name__ == "__main__":
    o = sys.argv[1]
    boss(o+"/audio_boss.wav"); combo(o+"/audio_combo.wav"); arms(o+"/audio_arms.wav")
    how(o+"/audio_how.wav"); night(o+"/audio_night.wav"); print("ok")
