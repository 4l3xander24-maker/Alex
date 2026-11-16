"""Audio sintetizado (sin muestras) de los 3 videos de la actualización: drones,
campanadas, golpes, latidos y zumbidos. Uso: python3 audio_update.py"""
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


# 1 · Jefe final
b = buf()
drone(b, 49, 0.2, 0, fr(370))
add(b, bell(147, 5), fr(4), 0.9)
add(b, impact(), fr(0), 0.6)
for i in range(4):
    add(b, heartbeat(), fr(62) + i * 0.36, 0.7)
add(b, whoosh(), fr(95), 0.5)
add(b, impact(), fr(105), 1.0)
add(b, growl(), fr(150), 0.9)
add(b, impact(), fr(150), 0.8)
add(b, bell(110, 3), fr(220), 0.7)
add(b, impact(), fr(220), 0.8, pan=-0.2)
add(b, impact(), fr(245), 0.9, pan=0.2)
add(b, growl(1.5), fr(245), 0.6)
pulse(b, fr(185), fr(365), 140, 0.45)
add(b, whoosh(), fr(265), 0.5)
add(b, impact(), fr(275), 0.9)
end_card(b, fr(370))
save(b, "public/update/audio_boss.wav")

# 2 · Bestiario
b = buf()
drone(b, 65, 0.16, 0, fr(370))
add(b, impact(), 0.0, 0.7)
pulse(b, fr(60), fr(298), 128, 0.4)
scale = [523, 587, 659, 784, 880, 988, 1046, 1175, 1318, 1568, 1760]
for i, f in enumerate(scale):
    t = fr(70 + i * 17)
    add(b, whoosh(0.25), t - 0.18, 0.25, pan=(-0.5 + (i % 3) * 0.5))
    add(b, chime(f), t, 0.35, pan=(-0.5 + (i % 3) * 0.5))
add(b, whoosh(), fr(285), 0.5)
add(b, impact(), fr(300), 1.0)
add(b, growl(), fr(300), 0.8)
add(b, bell(110, 3), fr(302), 0.6)
end_card(b, fr(370))
save(b, "public/update/audio_bestiary.wav")

# 3 · Actualización
b = buf()
drone(b, 55, 0.14, 0, fr(380))
pulse(b, 0.0, fr(375), 120, 0.5)
for f in [0, 60, 120, 180, 240, 300]:
    add(b, whoosh(), fr(f) - 0.35, 0.5)
    add(b, impact(), fr(f), 0.85)
add(b, bell(196, 3), fr(60), 0.5)
for i in range(6):
    add(b, chime(1318 + i * 120, 0.5), fr(314) + i * 0.06, 0.18, pan=(-0.5 + i * 0.2))
end_card(b, fr(380))
save(b, "public/update/audio_update.wav")
print("ok")
