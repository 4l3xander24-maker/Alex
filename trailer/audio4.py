import sys
sys.path.insert(0, ".")
from audio2 import smp, shots, fr
from audio3 import base, cuts, end_card

def lobby(path):
    m = base(); cuts(m, [110, 230, 340])
    m.add(smp("sparkle_whoosh", 0, 1.8, 0.45, fout=0.5), 0.0, 1.0)
    for i in range(5): m.add(smp("ball_tap", 0, 0.3, 0.85, pitch=0.9+0.13*i), 0.6+i*0.5, 1.0, -0.5+0.25*i)
    m.add(smp("positive_ui", 0, 1.2, 0.45, fout=0.4), fr(110), 1.0)
    m.add(smp("church_bell", 0, 3.5, 0.45, fout=1.0), fr(110)+0.3, 1.0)
    m.add(smp("unlock_item", 0, 1.8, 0.6, fout=0.5), fr(230)+0.4, 1.0)
    end_card(m); m.save(path)

def pick(path):
    m = base(); cuts(m, [70, 140, 210, 280, 360])
    shots(m, "gun_shot", 0.15, 6, 0.19, 0.7, 0.3, pan=0.1)
    shots(m, "gun_shot", fr(70)+0.1, 12, 0.085, 0.5, 0.11, pitch=1.2)
    m.add(smp("arrow_whoosh", 0, 1.0, 0.8), fr(140)+0.3, 1.0, 0.4)
    m.add(smp("small_hit", 0, 0.5, 0.6), fr(140)+0.8, 1.0, 0.4)
    m.add(smp("arrow_whoosh", 0, 1.0, 0.75), fr(140)+1.5, 1.0, -0.3)
    m.add(smp("fire_woosh", 0, 2.0, 0.8, fout=0.4), fr(210)+0.1, 1.0)
    m.add(smp("fire_beam", 1.0, 2.0, 0.7, fin=0.15, fout=0.5), fr(210)+0.3, 1.0)
    m.add(smp("zombie_growl", 0, 1.6, 0.6, fout=0.3), fr(280)+0.3, 1.0)
    m.add(smp("giant_roar", 0, 2.0, 0.6, fout=0.5), fr(300), 1.0)
    end_card(m); m.save(path)

if __name__ == "__main__":
    o = sys.argv[1]; lobby(o+"/audio_lobby.wav"); pick(o+"/audio_pick.wav"); print("ok")
