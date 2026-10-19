# Estimación rápida de la carga de cada dificultad (no es el juego: es un modelo).
# Compara la vida total de la oleada contra el daño por segundo que se supone
# que tiene un jugador solo en esa oleada. ratio < 1 = holgado, > 2 = muro.
# Uso: python3 tools/balance.py   (copiar aquí los números si cambia Config.luau)
HP = {"Walker": 3, "Runner": 2, "Cone": 7, "Knight": 10, "Brute": 14, "Mutant": 9, "Bomber": 3, "Parasite": 12, "Colossus": 28, "Spitter": 5}
LINEUPS = [["Walker"], ["Runner"], ["Walker", "Cone"], ["Brute"], ["Walker", "Runner"], ["Mutant", "Bomber"], ["Cone", "Knight", "Parasite"], ["Runner", "Brute", "Bomber"], ["Mutant", "Knight", "Colossus"], ["Walker", "Runner", "Cone"]]
BOSS_HP = [150, 220, 300, 240]
# nombre: (Count, Growth, Health, Spawn, Goal)
DIFFS = {"Normal": (.88, 1.30, .55, .91, 8), "Dificil": (1.1, 1.22, 1.05, 1.1, 10), "Experto": (1.15, 1.15, 1.15, 1.15, 12), "Pesadilla": (1.4, 1.13, 1.4, 1.3, 14), "Infierno": (1.7, 1.1, 1.7, 1.5, 16)}

def avg_hp(w):
    l = LINEUPS[w - 1] if w <= 10 else list(HP)
    return sum(HP[t] for t in l) / len(l)

def player_dps(w):
    base = 6 if w <= 3 else 14 if w <= 7 else 26 if w <= 12 else 38 if w <= 18 else 50
    return base * 1.3  # talentos, poderes y mascota

for name, (count, growth, health, spawn, goal) in DIFFS.items():
    for w in (1, 5, goal):
        n = 22 * growth ** (w - 1) * count
        hm = (1 + .12 * (w - 1)) * health
        pool = n * avg_hp(w) * hm + (sum(BOSS_HP[i % 4] for i in range(w // 5)) * hm if w % 5 == 0 else 0)
        rate = min(30, (3.5 + 1.5 * (w - 1)) * spawn)
        need = pool / (n / rate + 25)
        print(f"{name:10s} oleada {w:2d}: zombis {int(n):4d}  ratio {need / player_dps(w):5.2f}")
