"""Audio sintetizado (sin muestras) de los 3 videos de la actualización: drones,
campanadas, golpes, latidos y zumbidos. Uso: python3 audio_update.py"""
import json
import wave
import numpy as np

SR = 48000
DUR = 15.0
rng = np.random.default_rng(7)


def buf():
    return np.zeros((int(SR * DUR), 2))


def add(b, sig, t, gain=1.0, pan=0.0):
    i = int(t * SR)
    if i < 0:
        sig = sig[-i:]; i = 0
    n = min(len(sig), len(b) - i)
    if n <= 0:
        return
    b[i:i + n, 0] += sig[:n] * gain * (1 - max(0, pan))
    b[i:i + n, 1] += sig[:n] * gain * (1 + min(0, pan))


def env(n, a, d):
    t = np.arange(n) / SR
    return np.minimum(1, t / max(a, 1e-4)) * np.exp(-t / d)


def bell(f=196, length=4.0):
    n = int(SR * length); t = np.arange(n) / SR; s = np.zeros(n)
    for ratio, amp, dec in [(0.5, 0.5, 2.8), (1, 1, 2.2), (1.19, 0.6, 1.6), (1.5, 0.45, 1.3), (2, 0.5, 1.0), (2.74, 0.3, 0.7), (3.76, 0.2, 0.5), (5.4, 0.12, 0.3)]:
        s += amp * np.sin(2 * np.pi * f * ratio * t + ratio) * np.exp(-t / dec)
    s *= np.minimum(1, t / 0.003)
    return s / np.abs(s).max()


def noise(n):
    return rng.standard_normal(n)


def lp_fast(x, k):
    # media móvil (barata) como paso bajo
    c = np.cumsum(np.insert(x, 0, 0)); y = (c[k:] - c[:-k]) / k
    return np.concatenate([y, np.zeros(k - 1)])


def impact(length=1.6):
    n = int(SR * length); t = np.arange(n) / SR
    f = 30 + 90 * np.exp(-t / 0.08)
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.45)
    crack = lp_fast(noise(n), 6) * np.exp(-t / 0.06)
    s = body * 1.0 + crack * 0.8
    return s / np.abs(s).max()


def kick():
    n = int(SR * 0.35); t = np.arange(n) / SR
    f = 45 + 110 * np.exp(-t / 0.03)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.12)


def heartbeat():
    k = kick() * 0.9
    s = np.zeros(int(SR * 0.6)); s[:len(k)] += k
    j = int(SR * 0.22); s[j:j + len(k)] += k[:len(s) - j] * 0.7
    return s


def whoosh(length=0.5):
    n = int(SR * length); t = np.linspace(0, 1, n)
    x = lp_fast(noise(n), 3) - lp_fast(noise(n), 40)
    return x * np.sin(np.pi * t) ** 2 * 0.8


def growl(length=2.2):
    n = int(SR * length); t = np.arange(n) / SR
    f = 55 + 8 * np.sin(2 * np.pi * 6 * t)
    s = np.sign(np.sin(2 * np.pi * np.cumsum(f) / SR)) * 0.5
    s = lp_fast(s + lp_fast(noise(n), 20) * 1.5, 25)
    return s * np.minimum(1, t / 0.15) * np.exp(-t / 1.0)


def chime(f=880, length=0.9):
    n = int(SR * length); t = np.arange(n) / SR
    s = np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 2.01 * t) + 0.2 * np.sin(2 * np.pi * f * 3 * t)
    return s * np.exp(-t / 0.25) * np.minimum(1, t / 0.002)


def drone(b, f=55, gain=0.18, start=0.0, end=DUR):
    n = int(SR * (end - start)); t = np.arange(n) / SR
    s = np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 1.5 * t + 1) + 0.3 * np.sin(2 * np.pi * f * 2.01 * t)
    s *= np.minimum(1, t / 1.5) * np.minimum(1, (n / SR - t) / 1.0)
    s *= 0.75 + 0.25 * np.sin(2 * np.pi * 0.3 * t)
    add(b, s, start, gain)


def pulse(b, start, end, bpm=120, gain=0.5):
    step = 60 / bpm; t = start
    while t < end:
        add(b, kick(), t, gain); t += step


def end_card(b, t):
    add(b, impact(), t, 0.9)
    add(b, bell(262, 4), t, 0.55)
    for i, f in enumerate([523, 659, 784, 1046]):
        add(b, chime(f), t + 0.25 + i * 0.09, 0.12, pan=(-0.4 + i * 0.25))


def fr(frame):
    return frame / 30


def save(b, path):
    b = b / max(1e-6, np.abs(b).max()) * 0.89
    data = (b * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())



def gunshot(kind):
    n = int(SR * 0.45); t = np.arange(n) / SR
    if kind == "bow":
        f = 220 * np.exp(-t / 0.05) + 90
        s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.06) * 0.8 + whoosh(0.45)[:n] * 0.6
    elif kind == "pistol":
        s = lp_fast(noise(n), 2) * np.exp(-t / 0.03) + kick()[:n] * 0.5 if n <= len(kick()) else lp_fast(noise(n), 2) * np.exp(-t / 0.03)
    else:
        s = lp_fast(noise(n), 5) * np.exp(-t / 0.09)
        k = kick(); s[:len(k)] += k * 0.9
    return s / np.abs(s).max()


def tick():
    n = int(SR * 0.06); t = np.arange(n) / SR
    return np.sin(2 * np.pi * 2400 * t) * np.exp(-t / 0.012)


def crunch():
    n = int(SR * 0.35); t = np.arange(n) / SR
    s = np.zeros(n)
    for j in range(6):
        i = int(SR * 0.04 * j * (0.6 + 0.8 * rng.random()))
        m = min(n - i, int(SR * 0.05))
        if m > 0:
            s[i:i + m] += lp_fast(noise(m), 3) * np.exp(-np.arange(m) / SR / 0.012) * (1 - j * 0.12)
    return s / np.abs(s).max()


def coin():
    return np.concatenate([chime(1568, 0.12)[: int(SR * 0.07)], chime(2093, 0.5)])


def music(b, start, end, bpm, gain=0.55):
    step = 60 / bpm; t = start; i = 0
    notes = [55, 55, 65.4, 49, 55, 55, 73.4, 65.4]
    while t < end - 0.05:
        add(b, kick(), t, gain)
        hat = lp_fast(noise(int(SR * 0.05)), 1) - lp_fast(noise(int(SR * 0.05)), 8)
        hat *= np.exp(-np.arange(len(hat)) / SR / 0.015)
        add(b, hat, t + step / 2, gain * 0.35, pan=0.3)
        if i % 2 == 1:
            add(b, hat, t, gain * 0.25, pan=-0.3)
        n = int(SR * step); tt = np.arange(n) / SR; f = notes[(i // 2) % len(notes)]
        bass = np.sign(np.sin(2 * np.pi * f * tt)) * 0.5 + np.sin(2 * np.pi * f * tt)
        add(b, lp_fast(bass, 30) * np.exp(-tt / 0.25), t, gain * 0.35)
        t += step; i += 1


def stinger(b, name, t, arg=None):
    if name == "bell":
        add(b, bell(147, 4), t, 0.9); add(b, impact(), t, 0.5)
    elif name == "heart":
        add(b, heartbeat(), t, 0.8)
    elif name == "riser":
        n = int(SR * (arg or 30) / 30); tt = np.linspace(0, 1, n)
        x = (lp_fast(noise(n), 4) - lp_fast(noise(n), 30)) * tt ** 2
        add(b, x * 0.8, t, 0.6)
    elif name == "impact":
        add(b, impact(), t, 1.0)
    elif name == "growl":
        add(b, growl(), t, 0.9)
    elif name == "stamp":
        add(b, impact(0.8), t, 0.7); add(b, whoosh(0.3), t - 0.25, 0.4)
    elif name == "shock":
        add(b, bell(98, 3), t, 0.8); add(b, impact(), t, 0.9); add(b, whoosh(0.8), t, 0.6)
    elif name == "whoosh":
        add(b, whoosh(), t, 0.6)
    elif name == "swell":
        for i, f in enumerate([523, 659, 784]):
            add(b, chime(f, 1.2), t + i * 0.05, 0.2)
    elif name == "coins":
        for i in range(10):
            add(b, coin(), t + i * 0.07, 0.18, pan=(-0.6 + (i % 5) * 0.3))
    elif name == "end":
        end_card(b, t)
        for i in range(15):
            add(b, tick(), t + 1.0 + i / 30 * 1.6, 0.25)


def fights(b, fights_list, guns):
    for fight in fights_list:
        kind = guns[fight["gun"]]["sound"]
        add(b, whoosh(0.35), fr(fight["from"]) - 0.2, 0.45)
        for z in fight["zombies"]:
            last = z["hits"][-1]
            for h in z["hits"]:
                t = fr(fight["from"] + h)
                add(b, gunshot(kind), t, 0.75, pan=0.15)
                add(b, tick(), t + 0.02, 0.35)
            t = fr(fight["from"] + last)
            add(b, crunch(), t + 0.02, 0.8, pan=(z["x"] - 540) / 900)
            add(b, coin(), t + 0.12, 0.3)
            if "toast" in z:
                for i, f in enumerate([784, 988, 1175]):
                    add(b, chime(f, 0.7), t + 0.15 + i * 0.07, 0.22)


S = json.load(open("src/updateScenes.json"))
G = S["guns"]

for key, out in [("boss", "audio_boss.wav"), ("bestiary", "audio_bestiary.wav"), ("update", "audio_update.wav"), ("combo", "audio_combo.wav"), ("arms", "audio_arms.wav"), ("reaper", "audio_reaper.wav"), ("tier", "audio_tier.wav"), ("noobpro", "audio_noobpro.wav"), ("waves", "audio_waves.wav")]:
    v = S[key]; b = buf()
    for seg in v["music"]:
        music(b, fr(seg[0]), fr(seg[1]), seg[2])
    drone(b, 49, 0.12, 0, fr(375))
    fl = list(v["fights"])
    if key == "noobpro":
        fl = [v["noob"], v["pro"]]
        for f in v["noob"]["misses"]:
            add(b, gunshot("pistol"), fr(v["noob"]["from"] + f), 0.5, pan=-0.4)
        for f in v["noob"]["hurt"]:
            add(b, impact(0.6), fr(v["noob"]["from"] + f), 0.6, pan=-0.4); add(b, growl(0.6), fr(v["noob"]["from"] + f), 0.4, pan=-0.4)
    fights(b, fl, G)
    if key in ("boss", "reaper"):
        bf = v["boss"]
        for h in bf["hits"]:
            t = fr(bf["from"] + h)
            add(b, gunshot(G[bf["gun"]]["sound"]), t, 0.6); add(b, tick(), t + 0.02, 0.3)
    if key == "bestiary":
        for i, f in enumerate(v["flips"]):
            add(b, whoosh(0.2), fr(f) - 0.12, 0.3); add(b, chime(880 + i * 110, 0.6), fr(f), 0.3)
    if key == "update":
        for i, f in enumerate(v["chests"]):
            add(b, coin(), fr(f), 0.35 if i < 6 else 0.6)
        for f in [40, 120, 190, 260, 320]:
            add(b, whoosh(), fr(f) - 0.3, 0.5)
    for ev in v["sfx"]:
        stinger(b, ev[0], fr(ev[1]), ev[2] if len(ev) > 2 else None)
    save(b, "public/update/" + out)
print("ok")
