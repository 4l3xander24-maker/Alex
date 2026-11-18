// Videos cortos de la actualización: jefe final, bestiario coleccionable y
// resumen con el código de regalo. Sin clips grabados: montan capturas reales
// del juego (public/update: vistas en primera persona y zombis recortados del
// bestiario) con disparos, cubitos, combos y textos animados. El jefe final
// sale como silueta (todavía no hay captura suya). Los tiempos de cada escena
// están en updateScenes.json, que también lee audio_update.py.
import { Audio } from "@remotion/media";
import { loadFont } from "@remotion/fonts";
import {
  AbsoluteFill,
  Easing,
  Freeze,
  Img,
  Sequence,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import scenes from "./updateScenes.json";

const IMPACT = "UpdImpact";
const SERIF = "UpdGeorgia";
loadFont({ family: IMPACT, url: staticFile("fonts/Impact.ttf") });
loadFont({ family: SERIF, url: staticFile("fonts/GeorgiaBold.ttf"), weight: "700" });

const GOLD = "#ffd36b";
const BLOOD = "#ff3b2f";
const CREAM = "#fff1d6";
const NIGHT = "#07030c";
const OUT = Easing.bezier(0.16, 1, 0.3, 1);
const CLAMP = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

type GunKey = keyof typeof scenes.guns;
type ZombieSpec = { type: string; x: number; y: number; appear: number; hits: number[]; s0: number; s1: number; toast?: string };
type FightSpec = { from: number; len: number; gun: string; zombies: ZombieSpec[]; misses?: number[]; hurt?: number[] };

const hash = (n: number) => {
  const a = Math.sin(n * 12.9898) * 43758.5453;
  return a - Math.floor(a);
};

const shake = (frame: number, power: number, length = 14) => {
  const k = frame < 0 || frame > length ? 0 : 1 - frame / length;
  return { x: Math.sin(frame * 91.7) * power * k, y: Math.cos(frame * 57.3) * power * k };
};

// Colores de los cubitos al reventar (los del modelo de cada zombi)
const PALETTE: Record<string, string[]> = {
  Cone: ["#7cc44a", "#ff8a2b", "#2b2b2b", "#a33"],
  Knight: ["#8a8f96", "#5f9646", "#2b2b2b"],
  Spitter: ["#8cbe3c", "#ffe14a", "#2b2b2b"],
  Parasite: ["#9a5aaa", "#ff4ad8", "#2b2b2b"],
  Colossus: ["#8a9a90", "#5a5f66", "#2b2b2b"],
  Mutant: ["#3c963c", "#2b2b2b", "#a33"],
  Fatso: ["#96ba50", "#2b2b2b", "#c8e080"],
  King: ["#d4a83a", "#6ea060", "#2b2b2b", "#ff3b2f"],
  Queen: ["#d4a83a", "#96beaa", "#2b2b2b"],
  Dragon: ["#5c7854", "#e8e0c8"],
  Reaper: ["#e6e8ee", "#1c1c1c", "#ff3b2f"],
};
const NAMES: Record<string, string> = {
  Cone: "Zombi con cono",
  Knight: "Caballero",
  Spitter: "Escupidor",
  Parasite: "Parásito",
  Colossus: "Coloso",
  Mutant: "Mutante",
  Fatso: "Zombi Gordo",
  King: "Rey Zombi",
  Queen: "Reina",
  Dragon: "Dragón",
  Reaper: "Segador",
};

// ───────────── piezas base ─────────────

const Bg: React.FC<{ src: string; grade?: string; zoom?: number }> = ({ src, grade = "brightness(0.45) saturate(0.8)", zoom = 0.12 }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const s = 1.05 + zoom * Math.min(1, frame / Math.max(1, durationInFrames));
  return (
    <AbsoluteFill style={{ overflow: "hidden", background: NIGHT }}>
      <Img src={staticFile(src)} style={{ width: "100%", height: "100%", objectFit: "cover", transform: `scale(${s})`, filter: grade }} />
    </AbsoluteFill>
  );
};

const Vignette: React.FC<{ color?: string; inner?: number }> = ({ color = "rgba(0,0,0,0.85)", inner = 35 }) => (
  <AbsoluteFill style={{ background: `radial-gradient(ellipse at 50% 45%, transparent ${inner}%, ${color} 100%)` }} />
);

const Embers: React.FC<{ count?: number; color?: string }> = ({ count = 40, color = "#ff9a40" }) => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill>
      {new Array(count).fill(0).map((_, i) => {
        const r = hash(i + 1);
        const x = (r * 1080 + Math.sin((frame + i * 40) / 30) * 30) % 1080;
        const y = 1920 - ((frame * (2 + r * 4) + i * 97) % 2100);
        const size = 4 + r * 8;
        return <div key={i} style={{ position: "absolute", left: x, top: y, width: size, height: size, borderRadius: size, background: color, boxShadow: `0 0 ${size * 2}px ${color}`, opacity: 0.4 + r * 0.5 }} />;
      })}
    </AbsoluteFill>
  );
};

const Flash: React.FC<{ color?: string; peak?: number; length?: number }> = ({ color = "#fff", peak = 0.8, length = 10 }) => {
  const frame = useCurrentFrame();
  return <AbsoluteFill style={{ background: color, opacity: interpolate(frame, [0, length], [peak, 0], CLAMP) }} />;
};

const Stamp: React.FC<{ text: string; y: number; size: number; color?: string; glow?: string; delay?: number; tilt?: number }> = ({
  text,
  y,
  size,
  color = CREAM,
  glow = BLOOD,
  delay = 0,
  tilt = -3,
}) => {
  const frame = useCurrentFrame() - delay;
  const { fps } = useVideoConfig();
  if (frame < 0) return null;
  const s = spring({ frame, fps, config: { damping: 11, stiffness: 190 } });
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        top: y,
        textAlign: "center",
        fontFamily: IMPACT,
        fontSize: size,
        lineHeight: 1,
        color,
        opacity: interpolate(frame, [0, 3], [0, 1], CLAMP),
        transform: `scale(${interpolate(s, [0, 1], [2.6, 1])}) rotate(${tilt}deg)`,
        textShadow: `0 0 30px ${glow}, 0 8px 0 rgba(0,0,0,0.85), 0 0 4px #000`,
        WebkitTextStroke: "3px rgba(0,0,0,0.75)",
        padding: "0 40px",
      }}
    >
      {text}
    </div>
  );
};

const Sub: React.FC<{ text: string; y: number; size?: number; delay?: number; color?: string }> = ({ text, y, size = 56, delay = 0, color = CREAM }) => {
  const frame = useCurrentFrame() - delay;
  if (frame < 0) return null;
  const dy = interpolate(frame, [0, 12], [30, 0], { ...CLAMP, easing: OUT });
  return (
    <div style={{ position: "absolute", left: 60, right: 60, top: y + dy, textAlign: "center", fontFamily: SERIF, fontWeight: 700, fontSize: size, color, opacity: interpolate(frame, [0, 8], [0, 1], CLAMP), textShadow: "0 4px 12px #000, 0 0 3px #000" }}>
      {text}
    </div>
  );
};

// Subtítulo estilo TikTok: palabra por palabra, las marcadas con * en amarillo
const Caption: React.FC<{ text: string; y?: number; size?: number; every?: number; delay?: number }> = ({ text, y = 1380, size = 92, every = 4, delay = 0 }) => {
  const frame = useCurrentFrame() - delay;
  const { fps } = useVideoConfig();
  if (frame < 0) return null;
  const words = text.split(" ");
  return (
    <div style={{ position: "absolute", left: 50, right: 50, top: y, display: "flex", flexWrap: "wrap", justifyContent: "center", gap: "0 22px" }}>
      {words.map((word, i) => {
        const f = frame - i * every;
        if (f < 0) return null;
        const hot = word.startsWith("*");
        const s = spring({ frame: f, fps, config: { damping: 9, stiffness: 260 } });
        return (
          <span
            key={i}
            style={{
              fontFamily: IMPACT,
              fontSize: hot ? size * 1.25 : size,
              lineHeight: 1.15,
              color: hot ? GOLD : "#fff",
              WebkitTextStroke: "6px #000",
              paintOrder: "stroke",
              textShadow: hot ? "0 0 26px #ff7a2a, 0 6px 0 #000" : "0 6px 0 #000",
              display: "inline-block",
              transform: `scale(${interpolate(s, [0, 1], [1.8, 1])}) rotate(${hot ? -3 : 0}deg)`,
            }}
          >
            {hot ? word.slice(1) : word}
          </span>
        );
      })}
    </div>
  );
};

// Barra de avance arriba (la gente se queda a ver cómo termina)
const Progress: React.FC = () => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  return (
    <div style={{ position: "absolute", left: 0, top: 0, height: 12, width: `${(frame / durationInFrames) * 100}%`, background: `linear-gradient(90deg, ${BLOOD}, ${GOLD})`, boxShadow: "0 0 18px #ff7a2a" }} />
  );
};

const Combo: React.FC<{ count: number; at: number }> = ({ count, at }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  if (count <= 0) return null;
  const s = spring({ frame: frame - at, fps, config: { damping: 8, stiffness: 300 } });
  return (
    <div style={{ position: "absolute", right: 50, top: 300, textAlign: "right", transform: `scale(${interpolate(s, [0, 1], [1.7, 1])}) rotate(6deg)`, transformOrigin: "100% 50%" }}>
      <div style={{ fontFamily: IMPACT, fontSize: 130, color: count >= 5 ? "#ff8a2b" : GOLD, WebkitTextStroke: "5px #000", paintOrder: "stroke", textShadow: "0 0 30px #ff5a1a" }}>x{count}</div>
      <div style={{ fontFamily: IMPACT, fontSize: 44, color: CREAM, WebkitTextStroke: "3px #000", paintOrder: "stroke", marginTop: -10 }}>{count >= 5 ? "¡IMPARABLE! 🔥" : "COMBO"}</div>
    </div>
  );
};

// Cubitos que salen volando al morir un zombi (como en el juego)
const Burst: React.FC<{ x: number; y: number; colors: string[]; size?: number; count?: number; seed?: number }> = ({ x, y, colors, size = 34, count = 18, seed = 1 }) => {
  const frame = useCurrentFrame();
  if (frame < 0 || frame > 30) return null;
  return (
    <>
      {new Array(count).fill(0).map((_, i) => {
        const a = hash(seed * 31 + i) * Math.PI * 2;
        const speed = 14 + hash(seed * 7 + i) * 22;
        const vx = Math.cos(a) * speed;
        const vy = Math.sin(a) * speed - 16;
        const px = x + vx * frame;
        const py = y + vy * frame + 1.3 * frame * frame;
        const s = size * (0.6 + hash(i + seed) * 0.8) * interpolate(frame, [0, 30], [1, 0.3]);
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: px - s / 2,
              top: py - s / 2,
              width: s,
              height: s,
              background: colors[i % colors.length],
              border: "2px solid rgba(0,0,0,0.5)",
              transform: `rotate(${frame * (10 + i * 3)}deg)`,
              opacity: interpolate(frame, [18, 30], [1, 0], CLAMP),
            }}
          />
        );
      })}
    </>
  );
};

const Popup: React.FC<{ text: string; x: number; y: number; color?: string; size?: number }> = ({ text, x, y, color = GOLD, size = 64 }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  if (frame < 0 || frame > 26) return null;
  const s = spring({ frame, fps, config: { damping: 8, stiffness: 300 } });
  return (
    <div
      style={{
        position: "absolute",
        left: x - 300,
        width: 600,
        top: y - frame * 3,
        textAlign: "center",
        fontFamily: IMPACT,
        fontSize: size,
        color,
        WebkitTextStroke: "4px #000",
        paintOrder: "stroke",
        transform: `scale(${s})`,
        opacity: interpolate(frame, [18, 26], [1, 0], CLAMP),
      }}
    >
      {text}
    </div>
  );
};

// ───────────── la pelea en primera persona ─────────────

const recoilAt = (frame: number, shots: number[]) => shots.reduce((sum, f) => (frame >= f ? sum + Math.exp(-(frame - f) / 2.5) : sum), 0);

const Zombie: React.FC<{ spec: ZombieSpec; index: number }> = ({ spec, index }) => {
  const frame = useCurrentFrame();
  const last = spec.hits[spec.hits.length - 1];
  if (frame < spec.appear || frame >= last) return null;
  const p = (frame - spec.appear) / Math.max(1, last - spec.appear);
  const scale = spec.s0 + (spec.s1 - spec.s0) * p;
  const h = 620 * scale;
  const bob = Math.abs(Math.sin((frame + index * 5) / 3)) * 10;
  const hitNow = spec.hits.some((f) => frame >= f && frame < f + 2);
  const knock = spec.hits.reduce((sum, f) => (frame >= f ? sum + 14 * Math.exp(-(frame - f) / 3) : sum), 0);
  const fadeIn = interpolate(frame - spec.appear, [0, 5], [0, 1], CLAMP);
  return (
    <Img
      src={staticFile(`update/${spec.type}.png`)}
      style={{
        position: "absolute",
        left: spec.x - h * 0.5,
        top: spec.y - h * 0.5 - bob - knock,
        height: h,
        width: h,
        objectFit: "contain",
        opacity: fadeIn,
        transform: `rotate(${Math.sin((frame + index * 7) / 3) * 4}deg)`,
        filter: hitNow ? "brightness(3) saturate(0)" : "drop-shadow(0 12px 10px rgba(0,0,0,0.6))",
      }}
    />
  );
};

const Shots: React.FC<{ shots: { f: number; x: number; y: number; dmg: string; crit?: boolean; miss?: boolean }[]; muzzle: number[]; color?: string }> = ({ shots, muzzle, color = "#ffe27a" }) => {
  const frame = useCurrentFrame();
  return (
    <>
      {shots.map((shot, i) => {
        const f = frame - shot.f;
        return (
          <div key={i}>
            {f >= 0 && f < 3 ? (
              <>
                {/* fogonazo y trazo de la bala */}
                <div style={{ position: "absolute", left: muzzle[0] - 120, top: muzzle[1] - 120, width: 240, height: 240, borderRadius: 240, background: `radial-gradient(circle, #fff 0%, ${color} 25%, rgba(255,140,40,0.5) 50%, transparent 70%)` }} />
                <svg width={1080} height={1920} style={{ position: "absolute", left: 0, top: 0 }}>
                  <line x1={muzzle[0]} y1={muzzle[1]} x2={shot.x} y2={shot.y} stroke={color} strokeWidth={10 - f * 3} strokeLinecap="round" opacity={0.9} />
                </svg>
              </>
            ) : null}
            {f >= 0 && f < 5 && !shot.miss ? (
              <svg width={120} height={120} style={{ position: "absolute", left: shot.x - 60, top: shot.y - 60 }}>
                <g stroke={shot.crit ? GOLD : "#fff"} strokeWidth={9} strokeLinecap="round">
                  <line x1={18} y1={18} x2={42} y2={42} />
                  <line x1={102} y1={18} x2={78} y2={42} />
                  <line x1={18} y1={102} x2={42} y2={78} />
                  <line x1={102} y1={102} x2={78} y2={78} />
                </g>
              </svg>
            ) : null}
            <Sequence from={shot.f} durationInFrames={26} layout="none">
              <Popup text={shot.dmg} x={shot.x + (hash(i) - 0.5) * 140} y={shot.y - 160} color={shot.crit ? GOLD : "#fff"} size={shot.crit ? 96 : 66} />
            </Sequence>
          </div>
        );
      })}
    </>
  );
};

const Crosshair: React.FC<{ x: number; y: number }> = ({ x, y }) => (
  <svg width={90} height={90} style={{ position: "absolute", left: x - 45, top: y - 45 }}>
    <g stroke="#fff" strokeWidth={6} strokeLinecap="round" style={{ filter: "drop-shadow(0 0 3px #000)" }}>
      <line x1={45} y1={8} x2={45} y2={30} />
      <line x1={45} y1={60} x2={45} y2={82} />
      <line x1={8} y1={45} x2={30} y2={45} />
      <line x1={60} y1={45} x2={82} y2={45} />
    </g>
  </svg>
);

const gunOf = (key: string) => scenes.guns[key as GunKey];

// Una escena de pelea: fondo real en primera persona, zombis que se acercan,
// disparos, cubitos, monedas y combo
const Fight: React.FC<{ spec: FightSpec; comboStart?: number; showCombo?: boolean; grade?: string; children?: React.ReactNode }> = ({
  spec,
  comboStart = 0,
  showCombo = true,
  grade = "brightness(0.78) saturate(1.15) contrast(1.08)",
  children,
}) => {
  const frame = useCurrentFrame();
  const gun = gunOf(spec.gun);
  const shots = spec.zombies.flatMap((z, zi) =>
    z.hits.map((f, hi) => {
      const p = (f - z.appear) / Math.max(1, z.hits[z.hits.length - 1] - z.appear);
      const scale = z.s0 + (z.s1 - z.s0) * p;
      const crit = hi === z.hits.length - 1;
      return { f, x: z.x, y: z.y - 60 * scale, dmg: crit ? `CRÍTICO -${60 + Math.floor(hash(zi * 9 + hi) * 40)}` : `-${20 + Math.floor(hash(zi * 5 + hi) * 30)}`, crit };
    }),
  );
  (spec.misses ?? []).forEach((f, i) => {
    shots.push({ f, x: 540 + (hash(i + 31) - 0.5) * 700, y: 520 + hash(i + 7) * 300, dmg: "¡FALLÓ!", crit: false, miss: true } as (typeof shots)[number]);
  });
  const hurt = (spec.hurt ?? []).filter((f) => frame >= f && frame < f + 10).pop();
  const shotFrames = shots.map((s) => s.f);
  const kills = spec.zombies.map((z) => z.hits[z.hits.length - 1]).sort((a, b) => a - b);
  const killed = kills.filter((f) => frame >= f).length;
  const lastKill = killed > 0 ? kills[killed - 1] : 0;
  const r = recoilAt(frame, shotFrames);
  // la mira sigue al zombi vivo más cercano a morir
  const target = spec.zombies.filter((z) => frame >= z.appear && frame < z.hits[z.hits.length - 1]).sort((a, b) => a.hits[a.hits.length - 1] - b.hits[b.hits.length - 1])[0];
  const aim = target ? { x: target.x, y: target.y - 40 } : { x: 540, y: 760 };
  const k = shake(frame - (shotFrames.filter((f) => f <= frame).pop() ?? -99), 9, 6);
  return (
    <AbsoluteFill style={{ overflow: "hidden" }}>
      <AbsoluteFill style={{ transform: `translate(${k.x}px, ${k.y + r * 16}px) scale(${1.04 + r * 0.02})` }}>
        <Img src={staticFile(gun.bg)} style={{ width: "100%", height: "100%", filter: grade }} />
        {spec.zombies.map((z, i) => (
          <Zombie key={i} spec={z} index={i} />
        ))}
        <Shots shots={shots} muzzle={gun.muzzle} color={spec.gun === "lanzallamas" ? "#ff9a30" : "#ffe27a"} />
        {spec.zombies.map((z, i) => {
          const f = z.hits[z.hits.length - 1];
          return (
            <Sequence key={i} from={f} durationInFrames={32} layout="none">
              <Burst x={z.x} y={z.y - 40} colors={PALETTE[z.type] ?? ["#7cc44a", "#2b2b2b"]} seed={i + 3} size={30 * z.s1 + 10} />
              <Popup text="+5 🪙" x={z.x + 120} y={z.y - 260} size={70} />
            </Sequence>
          );
        })}
      </AbsoluteFill>
      <Crosshair x={aim.x} y={aim.y} />
      <Vignette color="rgba(0,0,0,0.65)" inner={45} />
      {hurt !== undefined ? <AbsoluteFill style={{ background: "radial-gradient(ellipse at 50% 50%, transparent 30%, rgba(220,0,0,0.75) 100%)", opacity: interpolate(frame - hurt, [0, 10], [1, 0]) }} /> : null}
      {(spec.hurt ?? []).map((f) => (
        <Sequence key={f} from={f} durationInFrames={26} layout="none">
          <Popup text="-25 ❤️" x={540} y={1150} color={BLOOD} size={110} />
        </Sequence>
      ))}
      {showCombo ? <Combo count={comboStart + killed} at={lastKill} /> : null}
      {children}
    </AbsoluteFill>
  );
};

// ───────────── el jefe ─────────────

// El Campanero Maldito en 3D (bloques como en el juego), hecho con
// tools/boss3d.html: de frente caminando, rugiendo y como silueta
const BossImg: React.FC<{ kind: "walk" | "roar" | "sil"; width: number }> = ({ kind, width }) => (
  <Img src={staticFile(`update/boss-${kind}.png`)} style={{ width, display: "block" }} />
);

const BossBar: React.FC<{ health: number; tag: string; show: number }> = ({ health, tag, show }) => (
  <div style={{ position: "absolute", left: 60, right: 60, top: 70, opacity: show, transform: `translateY(${(1 - show) * -60}px)` }}>
    <div style={{ fontFamily: IMPACT, fontSize: 44, color: CREAM, textAlign: "center", whiteSpace: "nowrap", textShadow: "0 3px 0 #000, 0 0 18px #ff5a2a" }}>
      🔔 CAMPANERO MALDITO{tag ? <span style={{ color: GOLD }}>{`  ·  ${tag}`}</span> : null}
    </div>
    <div style={{ marginTop: 10, height: 44, borderRadius: 10, background: "rgba(0,0,0,0.75)", border: "4px solid #2b1408", overflow: "hidden", position: "relative" }}>
      <div style={{ width: `${health * 100}%`, height: "100%", background: "linear-gradient(180deg,#ff6b4a,#b3160c)", boxShadow: "inset 0 6px 0 rgba(255,255,255,0.25)" }} />
      {[0.66, 0.33].map((m) => (
        <div key={m} style={{ position: "absolute", left: `${m * 100}%`, top: 0, bottom: 0, width: 4, background: "rgba(255,255,255,0.6)" }} />
      ))}
    </div>
  </div>
);

// El jefe sale detrás de la campana como silueta entre relámpagos, se le
// encienden los ojos y al final ruge a todo color con su barra de vida
const BossReveal: React.FC<{ eyesAt?: number; barAt?: number; stampAt?: number; fast?: boolean; stampText?: string }> = ({
  eyesAt = 30,
  barAt = 47,
  stampAt = 57,
  fast = false,
  stampText = "JEFE FINAL",
}) => {
  const frame = useCurrentFrame();
  const rise = interpolate(frame, [0, fast ? 22 : 50], [900, 0], { ...CLAMP, easing: OUT });
  const moon = interpolate(frame, [0, 60], [0.5, 1], CLAMP);
  const k = shake(frame - eyesAt, 30, 16);
  const k2 = shake(frame - stampAt, 34, 16);
  const breathe = 1 + Math.sin(frame / 8) * 0.012;
  const color = frame >= stampAt;
  const push = color ? interpolate(frame - stampAt, [0, 50], [1.12, 1.0], { ...CLAMP, easing: OUT }) : 1;
  const bolt = [8, 20, eyesAt].some((f) => frame >= f && frame < f + 3);
  return (
    <AbsoluteFill style={{ transform: `translate(${k.x + k2.x}px, ${k.y + k2.y}px)` }}>
      <Bg src="update/bg-asedio.jpg" grade={bolt ? "brightness(1.1) saturate(0.3) contrast(1.3)" : "brightness(0.42) saturate(0.7) sepia(0.35) hue-rotate(-25deg)"} zoom={0.15} />
      <div style={{ position: "absolute", left: 540 - 430, top: 240, width: 860, height: 860, borderRadius: 860, background: `radial-gradient(circle, rgba(255,90,40,${moon}) 0%, rgba(170,20,10,${moon * 0.8}) 50%, transparent 70%)` }} />
      {color ? (
        <div style={{ position: "absolute", left: 0, top: 470, transform: `scale(${push * breathe})`, transformOrigin: "50% 100%" }}>
          <BossImg kind="roar" width={1080} />
        </div>
      ) : (
        <div style={{ position: "absolute", left: 540 - 470, top: 360 + rise, transform: `scale(${breathe})`, transformOrigin: "50% 100%", opacity: frame >= eyesAt ? 1 : 0.92 }}>
          <BossImg kind="sil" width={940} />
        </div>
      )}
      <Embers count={70} />
      <Vignette />
      <BossBar health={1} tag="" show={interpolate(frame, [barAt, barAt + 8], [0, 1], CLAMP)} />
      {stampText ? <Stamp text={stampText} y={1560} size={210} color={CREAM} glow={BLOOD} delay={stampAt} /> : null}
      <Sequence from={eyesAt} durationInFrames={10} layout="none"><Flash color="#ff4020" peak={0.5} /></Sequence>
      <Sequence from={stampAt} durationInFrames={10} layout="none"><Flash peak={0.85} /></Sequence>
    </AbsoluteFill>
  );
};

// Pelea contra el jefe: daño, onda del campanazo (66%) y furia (33%)
const BossFight: React.FC<{ spec: typeof scenes.boss.boss }> = ({ spec }) => {
  const frame = useCurrentFrame();
  const gun = gunOf(spec.gun);
  const boss = { x: 540, y: 820 };
  const hitsDone = spec.hits.filter((f) => frame >= f).length;
  const health = Math.max(0.12, 1 - hitsDone * (0.88 / spec.hits.length));
  const p1 = frame >= spec.phase1;
  const p2 = frame >= spec.phase2;
  const tag = p2 ? "🔥 Furia" : p1 ? "🔔 Toque de difuntos" : "";
  const r = recoilAt(frame, spec.hits);
  const k1 = shake(frame - spec.phase1, 40, 18);
  const k2 = shake(frame - spec.phase2, 40, 18);
  const rage = p2 ? shake(frame % 4, 6, 4) : { x: 0, y: 0 };
  const shots = spec.hits.map((f, i) => ({
    f,
    x: boss.x + (hash(i) - 0.5) * 420,
    y: boss.y - 60 + (hash(i + 9) - 0.5) * 360,
    dmg: i % 5 === 4 ? `CRÍTICO -${110 + i * 3}` : `-${30 + Math.floor(hash(i * 3) * 25)}`,
    crit: i % 5 === 4,
  }));
  const ring = (start: number, color: string) => {
    const f = frame - start;
    if (f < 0 || f > 24) return null;
    const size = interpolate(f, [0, 24], [100, 2600], { ...CLAMP, easing: OUT });
    return (
      <div
        style={{
          position: "absolute",
          left: boss.x - size / 2,
          top: 1300 - size * 0.18,
          width: size,
          height: size * 0.36,
          borderRadius: "50%",
          border: `${interpolate(f, [0, 24], [40, 6])}px solid ${color}`,
          boxShadow: `0 0 60px ${color}, inset 0 0 60px ${color}`,
          opacity: interpolate(f, [12, 24], [1, 0], CLAMP),
        }}
      />
    );
  };
  return (
    <AbsoluteFill style={{ overflow: "hidden", transform: `translate(${k1.x + k2.x}px, ${k1.y + k2.y}px)` }}>
      <AbsoluteFill style={{ transform: `translateY(${r * 14}px) scale(${1.04 + r * 0.015})` }}>
        <Img src={staticFile(gun.bg)} style={{ width: "100%", height: "100%", filter: "brightness(0.45) saturate(0.8) sepia(0.35) hue-rotate(-20deg)" }} />
        <div style={{ position: "absolute", left: 540 - 400 + rage.x, top: 190 + rage.y }}>
          <div style={{ filter: spec.hits.some((f) => frame >= f && frame < f + 2) ? "brightness(2.6) saturate(0.4)" : "drop-shadow(0 0 30px rgba(255,60,20,0.6))" }}>
            <BossImg kind="walk" width={800} />
          </div>
        </div>
        {/* zombis que llama en la furia */}
        {p2
          ? ["Cone", "Knight", "Mutant", "Spitter"].map((type, i) => {
              const f = frame - spec.phase2 - i * 3;
              if (f < 0) return null;
              const side = i % 2 === 0 ? -1 : 1;
              const x = 540 + side * interpolate(f, [0, 30], [700, 180 + i * 40], { ...CLAMP, easing: OUT });
              return (
                <Img key={type} src={staticFile(`update/${type}.png`)} style={{ position: "absolute", left: x - 110, top: 820 + i * 30, height: 260, width: 220, objectFit: "contain", filter: "brightness(0.25) sepia(1) hue-rotate(-30deg) saturate(3)", transform: `rotate(${Math.sin(f / 2) * 6}deg)` }} />
              );
            })
          : null}
        <Shots shots={shots} muzzle={gun.muzzle} color="#ff9a30" />
      </AbsoluteFill>
      {ring(spec.phase1 + 2, "rgba(255,190,80,0.9)")}
      {ring(spec.phase2 + 2, "rgba(255,70,40,0.9)")}
      {p2 ? <AbsoluteFill style={{ background: "rgba(255,30,10,0.18)", opacity: 0.6 + 0.4 * Math.sin(frame / 3) }} /> : null}
      <Crosshair x={boss.x} y={boss.y - 40} />
      <Vignette color="rgba(60,0,0,0.85)" inner={40} />
      <BossBar health={health} tag={tag} show={1} />
      <Sequence from={spec.phase1} durationInFrames={30} layout="none">
        <Flash color="#ffb060" peak={0.5} />
        <Stamp text="¡CAMPANAZO!" y={1380} size={130} color={GOLD} glow="#ff7a2a" />
        <Popup text="-30 ❤️ y te empuja" x={540} y={1560} color={BLOOD} size={90} />
      </Sequence>
      <Sequence from={spec.phase2} durationInFrames={34} layout="none">
        <Flash color="#ff3020" peak={0.55} />
        <Stamp text="🔥 ¡FURIA!" y={1360} size={170} color={CREAM} glow={BLOOD} tilt={3} />
      </Sequence>
    </AbsoluteFill>
  );
};

// ───────────── cierre ─────────────

const EndCard: React.FC<{ news: string }> = ({ news }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame, fps, config: { damping: 9, stiffness: 160 } });
  const k = shake(frame - 2, 22, 12);
  const query = "Campana Maldita";
  const typed = query.slice(0, Math.max(0, Math.floor((frame - 30) / 1.6)));
  const cursor = Math.floor(frame / 8) % 2 === 0;
  const pill = 1 + Math.sin(frame / 4) * 0.04;
  const finger = Math.sin(frame / 4) * 18;
  return (
    <AbsoluteFill style={{ transform: `translate(${k.x}px, ${k.y}px)` }}>
      <Bg src="update/bg-horda.jpg" grade="brightness(0.3) saturate(0.8) blur(4px)" zoom={0.2} />
      <AbsoluteFill style={{ background: "radial-gradient(ellipse at 50% 35%, rgba(90,20,10,0.6) 0%, rgba(7,3,12,0.9) 75%)" }} />
      <Embers count={40} />
      <div style={{ position: "absolute", left: 0, right: 0, top: 200, display: "flex", justifyContent: "center" }}>
        <Img src={staticFile("icono.png")} style={{ width: 400, height: 400, borderRadius: 70, transform: `scale(${s}) rotate(${(1 - s) * -20}deg)`, boxShadow: "0 0 90px rgba(255,120,40,0.7)", border: `6px solid ${GOLD}` }} />
      </div>
      <Stamp text="CAMPANA MALDITA" y={650} size={124} color={GOLD} glow="#ff7a2a" delay={4} tilt={0} />
      <Sub text={news} y={790} size={50} delay={10} />
      <div style={{ position: "absolute", left: 0, right: 0, top: 940, display: "flex", justifyContent: "center", opacity: interpolate(frame, [16, 22], [0, 1], CLAMP) }}>
        <div style={{ padding: "18px 46px", borderRadius: 60, background: "linear-gradient(180deg,#3ccf5a,#1e8a35)", fontFamily: IMPACT, fontSize: 64, color: "#fff", WebkitTextStroke: "3px #0a3a14", paintOrder: "stroke", transform: `scale(${pill})`, boxShadow: "0 10px 0 #0d4a1c, 0 0 40px rgba(60,220,90,0.5)" }}>
          GRATIS · HASTA 5 AMIGOS
        </div>
      </div>
      {/* buscador: así lo encuentran */}
      <div style={{ position: "absolute", left: 90, right: 90, top: 1180, height: 120, borderRadius: 60, background: "#fff", display: "flex", alignItems: "center", padding: "0 40px", boxShadow: "0 10px 40px rgba(0,0,0,0.6)", opacity: interpolate(frame, [24, 30], [0, 1], CLAMP) }}>
        <span style={{ fontSize: 60, marginRight: 24 }}>🔍</span>
        <span style={{ fontFamily: SERIF, fontWeight: 700, fontSize: 60, color: "#111" }}>{typed}</span>
        <span style={{ width: 5, height: 64, background: "#111", marginLeft: 6, opacity: cursor ? 1 : 0 }} />
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, top: 1360 + finger, textAlign: "center", fontSize: 130 }}>👆</div>
      <Sub text="Búscalo en Roblox" y={1540} size={64} delay={30} color={GOLD} />
    </AbsoluteFill>
  );
};

// ───────────── 1 · Jefe final ─────────────

const Dread: React.FC = () => {
  const frame = useCurrentFrame();
  const k = shake(frame - 5, 30, 16);
  const k2 = shake(frame - 27, 30, 16);
  const swing = Math.sin(frame / 4) * 22;
  const dark = interpolate(frame, [0, 12], [0.75, 0.3], CLAMP);
  return (
    <AbsoluteFill style={{ transform: `translate(${k.x + k2.x}px, ${k.y + k2.y}px)` }}>
      <Img src={staticFile("update/fps-escopeta.jpg")} style={{ width: "100%", height: "100%", filter: `brightness(${dark}) saturate(0.2)` }} />
      <AbsoluteFill style={{ background: "radial-gradient(circle at 50% 40%, rgba(120,0,0,0.25), rgba(0,0,0,0.85) 75%)" }} />
      {[5, 27].map((at) => {
        const f = frame - at;
        if (f < 0 || f > 30) return null;
        const size = interpolate(f, [0, 30], [200, 1500], { ...CLAMP, easing: OUT });
        return <div key={at} style={{ position: "absolute", left: 540 - size / 2, top: 640 - size / 2, width: size, height: size, borderRadius: size, border: "10px solid rgba(255,200,90,0.8)", opacity: interpolate(f, [0, 30], [1, 0]) }} />;
      })}
      <div style={{ position: "absolute", left: 0, right: 0, top: 420, textAlign: "center", fontSize: 380, transform: `rotate(${swing}deg)`, transformOrigin: "50% 10%", filter: "drop-shadow(0 0 40px #ffb040)" }}>🔔</div>
      <Caption text="…hasta que la *campana sonó" y={1250} size={96} delay={4} />
    </AbsoluteFill>
  );
};

export const ShortFinalBoss: React.FC = () => {
  const s = scenes.boss;
  const [a, b] = s.fights;
  return (
    <AbsoluteFill style={{ background: NIGHT }}>
      <Audio src={staticFile("update/audio_boss.wav")} />
      <Sequence name="Pelea 1" from={a.from} durationInFrames={a.len}>
        <Fight spec={a}>
          <Caption text="POV: llegaste a la *ÚLTIMA *OLEADA" y={1330} delay={2} />
        </Fight>
      </Sequence>
      <Sequence name="Pelea 2" from={b.from} durationInFrames={b.len}>
        <Fight spec={b} comboStart={2}>
          <Caption text="todo iba *bien…" y={1380} delay={3} />
        </Fight>
      </Sequence>
      <Sequence name="Campana" from={95} durationInFrames={40}>
        <Dread />
      </Sequence>
      <Sequence name="Aparece" from={135} durationInFrames={105}>
        <BossReveal />
      </Sequence>
      <Sequence name="Pelea con el jefe" from={s.boss.from} durationInFrames={s.boss.len}>
        <BossFight spec={s.boss} />
      </Sequence>
      <Sequence name="Reto" from={330} durationInFrames={45}>
        <AbsoluteFill style={{ filter: "grayscale(0.85) contrast(1.2)", transform: `scale(1.12)` }}>
          <Freeze frame={s.boss.len + 30}>
            <BossFight spec={s.boss} />
          </Freeze>
        </AbsoluteFill>
        <AbsoluteFill style={{ background: "rgba(0,0,0,0.35)" }} />
        <Stamp text="¿LO DERROTAS?" y={720} size={140} color={GOLD} glow={BLOOD} delay={4} />
        <Caption text="si cae, *ganan la partida" y={1000} size={80} delay={14} every={3} />
      </Sequence>
      <Sequence name="Cierre" from={375}>
        <EndCard news="NUEVO: el Jefe Final" />
      </Sequence>
      <Sequence from={50} durationInFrames={6}><Flash peak={0.6} /></Sequence>
      <Sequence from={95} durationInFrames={8}><Flash peak={0.8} /></Sequence>
      <Sequence from={135} durationInFrames={8}><Flash color="#000" peak={1} /></Sequence>
      <Sequence from={240} durationInFrames={6}><Flash peak={0.7} /></Sequence>
      <Sequence from={330} durationInFrames={8}><Flash peak={0.8} /></Sequence>
      <Sequence from={375} durationInFrames={10}><Flash color={GOLD} peak={0.45} /></Sequence>
      <Progress />
    </AbsoluteFill>
  );
};

// ───────────── 2 · Bestiario coleccionable ─────────────

const GRID = ["Cone", "Knight", "Spitter", "Parasite", "Colossus", "Mutant", "Fatso", "King", "Queen", "Dragon", "Reaper", "Final"];
const MEDAL: Record<string, string> = { Cone: "🥉", Knight: "🥉", Spitter: "🥈", Parasite: "🥉", Colossus: "🥈", Mutant: "🥇", Fatso: "🥉", King: "🥈", Queen: "🥉", Dragon: "🥈", Reaper: "🥇" };

const Card: React.FC<{ type: string; x: number; y: number; w: number; h: number; revealAt: number | null; enterAt: number }> = ({ type, x, y, w, h, revealAt, enterAt }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const enter = spring({ frame: frame - enterAt, fps, config: { damping: 12 } });
  const last = type === "Final";
  const revealed = revealAt !== null && frame >= revealAt;
  const f = revealAt === null ? -1 : frame - revealAt;
  const flip = revealAt !== null && f >= -4 && f < 4 ? Math.abs(Math.cos(((f + 4) / 8) * Math.PI)) : 1;
  const pop = revealed ? spring({ frame: f, fps, config: { damping: 7, stiffness: 260 } }) : 0;
  const pulse = last ? 0.5 + 0.5 * Math.sin(frame / 4) : 0;
  const border = last ? `rgba(255,60,40,${0.5 + pulse * 0.5})` : revealed ? GOLD : "rgba(255,255,255,0.18)";
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width: w,
        height: h,
        borderRadius: 26,
        background: last ? "linear-gradient(180deg,#2a0a0c,#120406)" : revealed ? "linear-gradient(180deg,#3b3424,#1b1712)" : "linear-gradient(180deg,#2c2f3d,#191b24)",
        border: `5px solid ${border}`,
        boxShadow: revealed && f < 12 ? "0 0 50px rgba(255,200,90,0.9)" : last ? `0 0 ${20 + pulse * 40}px rgba(255,40,30,0.7)` : "0 8px 20px rgba(0,0,0,0.6)",
        transform: `scale(${interpolate(enter, [0, 1], [0, 1]) * (revealed ? 1 + (1 - pop) * 0.15 : 1)}) scaleX(${flip}) rotate(${(1 - enter) * 30}deg)`,
        overflow: "hidden",
      }}
    >
      {last ? (
        <div style={{ position: "absolute", left: w / 2 - 90, top: 14 }}>
          <BossImg kind="sil" width={180} />
        </div>
      ) : (
        <Img
          src={staticFile(`update/${type}.png`)}
          style={{ position: "absolute", left: 14, top: 16, width: w - 38, height: h - 96, objectFit: "contain", filter: revealed ? "none" : "brightness(0) drop-shadow(0 0 6px rgba(160,170,220,0.6))" }}
        />
      )}
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 12, textAlign: "center", fontFamily: IMPACT, fontSize: 36, color: revealed ? CREAM : last ? "#ff7a6a" : "#9aa0b8", textShadow: "0 3px 0 #000" }}>
        {revealed ? NAMES[type] : "???"}
      </div>
      {revealed ? <div style={{ position: "absolute", right: 8, top: 4, fontSize: 58, transform: `scale(${pop})` }}>{MEDAL[type]}</div> : null}
    </div>
  );
};

const Counter: React.FC<{ count: number; y: number }> = ({ count, y }) => (
  <div style={{ position: "absolute", left: 0, right: 0, top: y, textAlign: "center", fontFamily: IMPACT, fontSize: 70, color: CREAM, WebkitTextStroke: "4px #000", paintOrder: "stroke" }}>
    📖 DESCUBIERTOS <span style={{ color: GOLD }}>{count}</span>/16
  </div>
);

const Grid: React.FC<{ reveals: Record<string, number>; enterBase?: number; count: number }> = ({ reveals, enterBase = 0, count }) => {
  const w = 300;
  const h = 330;
  const gap = 36;
  const left = (1080 - (w * 3 + gap * 2)) / 2;
  return (
    <AbsoluteFill>
      {GRID.map((type, i) => (
        <Card key={type} type={type} x={left + (i % 3) * (w + gap)} y={360 + Math.floor(i / 3) * (h + 26)} w={w} h={h} revealAt={reveals[type] ?? null} enterAt={enterBase + i * 2} />
      ))}
      <Counter count={count} y={250} />
    </AbsoluteFill>
  );
};

// Aviso al descubrir un zombi (nombre, medalla y monedas)
const Toast: React.FC<{ type: string; boss?: boolean }> = ({ type, boss }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame, fps, config: { damping: 12, stiffness: 200 } });
  return (
    <div
      style={{
        position: "absolute",
        left: 50,
        right: 50,
        top: 1440,
        height: 190,
        borderRadius: 30,
        background: boss ? "linear-gradient(90deg,#5a3a08,#2a1a04)" : "linear-gradient(90deg,#1e2a14,#10160a)",
        border: `5px solid ${GOLD}`,
        boxShadow: "0 0 50px rgba(255,200,90,0.6)",
        display: "flex",
        alignItems: "center",
        padding: "0 30px",
        transform: `translateX(${(1 - s) * 1100}px)`,
      }}
    >
      <Img src={staticFile(`update/${type}.png`)} style={{ width: 150, height: 150, objectFit: "contain" }} />
      <div style={{ marginLeft: 26 }}>
        <div style={{ fontFamily: IMPACT, fontSize: 46, color: GOLD, WebkitTextStroke: "3px #000", paintOrder: "stroke" }}>{boss ? "¡MAESTRÍA DE ORO! 🥇" : "¡NUEVO EN EL BESTIARIO!"}</div>
        <div style={{ fontFamily: IMPACT, fontSize: 64, color: CREAM, WebkitTextStroke: "3px #000", paintOrder: "stroke" }}>
          {NAMES[type]} <span style={{ color: GOLD }}>{boss ? "+100 🪙" : "🥉 +5 🪙"}</span>
        </div>
      </div>
    </div>
  );
};

const BESTIARY_CAPTIONS = ["Cada zombi que *matas…", "…entra a tu *colección 📖", "gana *medallas 🥉🥈🥇", "¡y *monedas!", "cada vez más *raros…", "¡hasta los *JEFES!"];

export const ShortBestiary: React.FC = () => {
  const frame = useCurrentFrame();
  const s = scenes.bestiary;
  const fightTypes = s.fights.map((f) => f.zombies[0].type);
  // las cartas que ya se descubrieron en las peleas salen dadas vuelta desde el principio
  const reveals: Record<string, number> = {};
  fightTypes.forEach((type) => (reveals[type] = 0));
  ["Knight", "Spitter", "Mutant", "Fatso", "Dragon"].forEach((type, i) => (reveals[type] = s.flips[i] - 260));
  const gridCount = 6 + s.flips.filter((f) => frame >= f).length;
  const zoom = interpolate(frame, [320, 345], [1, 2.4], { ...CLAMP, easing: OUT });
  const lastX = 540 - ((1080 - (300 * 3 + 36 * 2)) / 2 + 2 * 336 + 150);
  const lastY = 960 - (360 + 3 * 356 + 165);
  return (
    <AbsoluteFill style={{ background: NIGHT }}>
      <Audio src={staticFile("update/audio_bestiary.wav")} />
      <Bg src="update/bg-campamento.jpg" grade="brightness(0.22) saturate(0.6) blur(6px)" zoom={0.08} />
      <Vignette />
      <Sequence name="Gancho" durationInFrames={45}>
        <Grid reveals={{}} count={0} />
        <AbsoluteFill style={{ background: "rgba(0,0,0,0.35)" }} />
        <Caption text="¿Puedes completar el *BESTIARIO?" y={720} size={110} delay={6} every={5} />
      </Sequence>
      {s.fights.map((fight, i) => {
        const z = fight.zombies[0];
        const kill = z.hits[z.hits.length - 1];
        return (
          <Sequence key={i} name={`Pelea ${z.type}`} from={fight.from} durationInFrames={fight.len}>
            <Fight spec={fight} showCombo={false}>
              <Counter count={i + (frame - fight.from >= kill ? 1 : 0)} y={120} />
              <Caption text={BESTIARY_CAPTIONS[i]} y={1180} size={86} every={3} />
              <Sequence from={kill + 2} layout="none">
                <Toast type={z.type} boss={z.type === "Reaper"} />
              </Sequence>
            </Fight>
          </Sequence>
        );
      })}
      <Sequence name="Colección" from={260} durationInFrames={115}>
        <AbsoluteFill style={{ transform: `scale(${zoom}) translate(${(lastX * (zoom - 1)) / 1.4}px, ${(lastY * (zoom - 1)) / 1.4}px)` }}>
          <Grid reveals={reveals} enterBase={-20} count={gridCount} />
        </AbsoluteFill>
        <Sequence from={4} durationInFrames={56} layout="none">
          <Caption text="¿te *faltan…?" y={1650} size={90} every={4} />
        </Sequence>
        <Sequence from={60}>
          <AbsoluteFill style={{ background: "rgba(80,0,0,0.25)" }} />
          <Stamp text="EL ÚLTIMO" y={150} size={160} color={CREAM} glow={BLOOD} />
          <Caption text="solo sale en la *OLEADA *FINAL 🔔" y={1560} size={84} delay={10} every={3} />
        </Sequence>
      </Sequence>
      <Sequence name="Cierre" from={375}>
        <EndCard news="NUEVO: Bestiario coleccionable" />
      </Sequence>
      {s.fights.map((fight) => (
        <Sequence key={fight.from} from={fight.from} durationInFrames={6}><Flash peak={0.3} /></Sequence>
      ))}
      <Sequence from={260} durationInFrames={8}><Flash peak={0.6} /></Sequence>
      <Sequence from={320} durationInFrames={10}><Flash color="#ff3020" peak={0.6} /></Sequence>
      <Sequence from={375} durationInFrames={10}><Flash color={GOLD} peak={0.45} /></Sequence>
      <Progress />
    </AbsoluteFill>
  );
};

// ───────────── 3 · Resumen de la actualización + código ─────────────

const Ribbon: React.FC<{ n: number; text: string; color: string }> = ({ n, text, color }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame, fps, config: { damping: 12, stiffness: 220 } });
  return (
    <div style={{ position: "absolute", left: 0, right: 0, top: 1460, display: "flex", justifyContent: "center", transform: `translateX(${(1 - s) * -1200}px) rotate(-3deg)` }}>
      <div style={{ padding: "14px 50px", background: color, fontFamily: IMPACT, fontSize: 104, color: "#fff", WebkitTextStroke: "5px #000", paintOrder: "stroke", boxShadow: "0 12px 0 rgba(0,0,0,0.6)" }}>
        {n} · {text}
      </div>
    </div>
  );
};

const MiniBoss: React.FC = () => {
  const frame = useCurrentFrame();
  const health = interpolate(frame, [32, 70], [1, 0.15], CLAMP);
  const tag = frame >= 55 ? "🔥 Furia" : frame >= 42 ? "🔔 Toque de difuntos" : "";
  const k = shake(frame - 42, 26, 12);
  const k2 = shake(frame - 55, 30, 12);
  return (
    <AbsoluteFill style={{ transform: `translate(${k.x + k2.x}px, ${k.y + k2.y}px)` }}>
      <BossReveal eyesAt={12} barAt={200} stampAt={24} fast stampText="" />
      <BossBar health={health} tag={tag} show={interpolate(frame, [24, 30], [0, 1], CLAMP)} />
      {frame >= 55 ? <AbsoluteFill style={{ background: "rgba(255,30,10,0.18)" }} /> : null}
    </AbsoluteFill>
  );
};

const Chests: React.FC<{ at: number[] }> = ({ at }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const rewards = [40, 50, 60, 75, 90, 110, 200];
  return (
    <AbsoluteFill>
      <Bg src="update/bg-campamento.jpg" grade="brightness(0.35) saturate(0.9)" zoom={0.1} />
      <Vignette />
      <Stamp text="🔥 RACHA DE 7 DÍAS" y={230} size={100} color={GOLD} glow="#ff7a2a" tilt={0} />
      {rewards.map((coins, i) => {
        const big = i === 6;
        const x = big ? 540 : 200 + (i % 3) * 340;
        const y = big ? 1150 : 480 + Math.floor(i / 3) * 330;
        const f = frame - at[i];
        const open = f >= 0;
        const s = spring({ frame: f, fps, config: { damping: 7, stiffness: 260 } });
        const size = big ? 330 : 220;
        return (
          <div key={i} style={{ position: "absolute", left: x - size / 2, top: y - size / 2, width: size, height: size, borderRadius: 30, background: open ? "linear-gradient(180deg,#5a3a08,#2a1a04)" : "linear-gradient(180deg,#2c2f3d,#191b24)", border: `5px solid ${open ? GOLD : "rgba(255,255,255,0.2)"}`, boxShadow: open ? "0 0 40px rgba(255,200,90,0.7)" : "none", transform: `scale(${open ? 1 + (1 - s) * 0.3 : 1})`, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
            <div style={{ fontFamily: IMPACT, fontSize: big ? 46 : 34, color: CREAM }}>DÍA {i + 1}</div>
            <div style={{ fontSize: big ? 130 : 84 }}>{open ? "🪙" : "🎁"}</div>
            <div style={{ fontFamily: IMPACT, fontSize: big ? 80 : 54, color: GOLD, WebkitTextStroke: "3px #000", paintOrder: "stroke", opacity: open ? 1 : 0.15 }}>+{coins}</div>
            <Sequence from={at[i]} durationInFrames={32} layout="none">
              <Burst x={size / 2} y={size / 2} colors={["#ffd36b", "#ffb020", "#fff1a0"]} count={big ? 30 : 12} seed={i + 40} size={big ? 34 : 22} />
            </Sequence>
          </div>
        );
      })}
    </AbsoluteFill>
  );
};

const Snow: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill>
      {new Array(90).fill(0).map((_, i) => {
        const r = hash(i + 77);
        const x = ((r * 1200 + frame * (3 + r * 4) + Math.sin(frame / 10 + i) * 20) % 1200) - 60;
        const y = ((hash(i + 5) * 1920 + frame * (6 + r * 10)) % 1980) - 30;
        const s = 6 + r * 14;
        return <div key={i} style={{ position: "absolute", left: x, top: y, width: s, height: s, borderRadius: s, background: "#fff", opacity: 0.5 + r * 0.5 }} />;
      })}
    </AbsoluteFill>
  );
};

const Gifts: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const skins = [
    { name: "Gorro navideño", icon: "🎅", color: "#d22a2a" },
    { name: "Muñeco de nieve", icon: "⛄", color: "#e8f0fa" },
    { name: "Reina del hielo", icon: "👑", color: "#78bef0" },
  ];
  return (
    <AbsoluteFill>
      <AbsoluteFill style={{ background: "radial-gradient(ellipse at 50% 40%, #1d3c5c 0%, #050a14 75%)" }} />
      <Snow />
      <Stamp text="❄️ SKINS DE INVIERNO" y={230} size={98} color="#bfe6ff" glow="#3aa0ff" tilt={0} />
      {skins.map((skin, i) => {
        const f = frame - (8 + i * 12);
        const s = spring({ frame: f, fps, config: { damping: 7, stiffness: 240 } });
        const wobble = f < 0 ? Math.sin(frame * 1.5 + i) * 8 : 0;
        return (
          <div key={skin.name} style={{ position: "absolute", left: 90, right: 90, top: 470 + i * 300, height: 250, borderRadius: 30, background: "rgba(10,25,45,0.85)", border: `5px solid ${skin.color}`, display: "flex", alignItems: "center", padding: "0 40px", transform: `rotate(${wobble}deg) scale(${f < 0 ? 0.9 : 0.9 + s * 0.1})` }}>
            <div style={{ fontSize: 150, transform: `scale(${f < 0 ? 1 : s})` }}>{f < 0 ? "🎁" : skin.icon}</div>
            <div style={{ marginLeft: 30, fontFamily: IMPACT, fontSize: 70, color: f < 0 ? "#8aa" : CREAM, WebkitTextStroke: "3px #000", paintOrder: "stroke" }}>{f < 0 ? "???" : skin.name}</div>
          </div>
        );
      })}
      <Sub text="Solo hasta el 7 de enero" y={1335} size={58} delay={40} color="#bfe6ff" />
    </AbsoluteFill>
  );
};

const CoinRain: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill>
      {new Array(40).fill(0).map((_, i) => {
        const r = hash(i + 200);
        const y = -150 + (frame - r * 20) * (18 + r * 12);
        return <div key={i} style={{ position: "absolute", left: r * 1080 - 40, top: y, fontSize: 70 + r * 40, transform: `rotate(${frame * (8 + r * 10)}deg)` }}>🪙</div>;
      })}
    </AbsoluteFill>
  );
};

export const ShortUpdate: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = scenes.update;
  const code = spring({ frame: frame - 324, fps, config: { damping: 8, stiffness: 200 } });
  return (
    <AbsoluteFill style={{ background: NIGHT }}>
      <Audio src={staticFile("update/audio_update.wav")} />
      <Sequence name="Gancho" from={0} durationInFrames={40}>
        <Fight spec={s.fights[0]}>
          <Stamp text="NUEVA" y={1250} size={150} color={CREAM} glow={BLOOD} delay={2} />
          <Stamp text="ACTUALIZACIÓN 🔥" y={1400} size={120} color={GOLD} glow="#ff7a2a" delay={8} tilt={2} />
        </Fight>
      </Sequence>
      <Sequence name="Jefe final" from={40} durationInFrames={80}>
        <MiniBoss />
        <Ribbon n={1} text="JEFE FINAL" color="#b3160c" />
      </Sequence>
      <Sequence name="Bestiario" from={120} durationInFrames={70}>
        <Grid
          reveals={{ Cone: 6, Knight: 10, Spitter: 14, Parasite: 18, Colossus: 22, Mutant: 26, Fatso: 30, King: 34, Queen: 38, Dragon: 42, Reaper: 46 }}
          count={Math.min(11, Math.max(0, Math.floor((frame - 126) / 4) + 1))}
        />
        <Ribbon n={2} text="BESTIARIO" color="#6b3fa0" />
      </Sequence>
      <Sequence name="Racha" from={190} durationInFrames={70}>
        <Chests at={s.chests.map((f) => f - 190)} />
        <Ribbon n={3} text="RACHA DIARIA" color="#d2641e" />
      </Sequence>
      <Sequence name="Invierno" from={260} durationInFrames={60}>
        <Gifts />
        <Ribbon n={4} text="INVIERNO" color="#2a78c8" />
      </Sequence>
      <Sequence name="Código" from={320} durationInFrames={65}>
        <Bg src="update/bg-horda.jpg" grade="brightness(0.3) saturate(0.8)" zoom={0.2} />
        <Vignette />
        <CoinRain />
        <Stamp text="CÓDIGO GRATIS" y={430} size={140} color={CREAM} glow={BLOOD} />
        <div
          style={{
            position: "absolute",
            left: 90,
            right: 90,
            top: 680,
            padding: "40px 0",
            borderRadius: 30,
            border: `8px dashed ${GOLD}`,
            background: "rgba(40,20,4,0.9)",
            textAlign: "center",
            fontFamily: IMPACT,
            fontSize: 150,
            color: GOLD,
            letterSpacing: 6,
            transform: `scale(${code}) rotate(${(1 - code) * 14}deg)`,
            textShadow: "0 0 30px #ff9a40, 0 6px 0 #000",
          }}
        >
          BIENVENIDO
        </div>
        <Caption text="= *200 monedas 🪙" y={1000} size={100} delay={14} every={3} />
        <Sub text="Canjéalo en ⚙️ Opciones › Códigos" y={1200} size={54} delay={26} />
      </Sequence>
      <Sequence name="Cierre" from={385}>
        <EndCard news="Nueva actualización disponible" />
      </Sequence>
      {[40, 120, 190, 260, 320].map((f) => (
        <Sequence key={f} from={f} durationInFrames={8}><Flash peak={0.65} /></Sequence>
      ))}
      <Sequence from={385} durationInFrames={10}><Flash color={GOLD} peak={0.45} /></Sequence>
      <Progress />
    </AbsoluteFill>
  );
};

// ───────────── miniatura del juego (1920×1080) ─────────────

export const Thumbnail: React.FC = () => {
  const horde: { type: string; x: number; y: number; h: number; dark: number }[] = [
    { type: "Colossus", x: 60, y: 560, h: 420, dark: 0.55 },
    { type: "Mutant", x: 330, y: 600, h: 380, dark: 0.5 },
    { type: "King", x: 560, y: 560, h: 420, dark: 0.55 },
    { type: "Cone", x: -60, y: 700, h: 470, dark: 0.85 },
    { type: "Parasite", x: 220, y: 720, h: 480, dark: 0.9 },
    { type: "Spitter", x: 470, y: 700, h: 500, dark: 0.85 },
    { type: "Queen", x: 720, y: 690, h: 470, dark: 0.8 },
  ];
  return (
    <AbsoluteFill style={{ background: NIGHT, overflow: "hidden" }}>
      <Img src={staticFile("update/thumb-bg.png")} style={{ position: "absolute", width: "100%", height: "100%", objectFit: "cover", filter: "brightness(0.42) saturate(0.75) sepia(0.35) hue-rotate(-25deg) contrast(1.1)" }} />
      <div style={{ position: "absolute", left: 1000, top: -160, width: 1100, height: 1100, borderRadius: 1100, background: "radial-gradient(circle, rgba(255,90,40,0.95) 0%, rgba(180,20,10,0.75) 45%, transparent 70%)" }} />
      <AbsoluteFill style={{ background: "linear-gradient(90deg, rgba(5,2,8,0.9) 0%, rgba(5,2,8,0.75) 40%, rgba(5,2,8,0.2) 58%, transparent 70%)" }} />
      <Img src={staticFile("update/boss-roar-hd.png")} style={{ position: "absolute", left: 930, top: -20, height: 1180, filter: "drop-shadow(0 0 40px rgba(255,70,20,0.75)) contrast(1.08) saturate(1.1)" }} />
      {horde.map((z) => (
        <Img key={z.type} src={staticFile(`update/${z.type}.png`)} style={{ position: "absolute", left: z.x, top: z.y, height: z.h, filter: `brightness(${z.dark}) drop-shadow(0 10px 14px rgba(0,0,0,0.8))` }} />
      ))}
      <AbsoluteFill style={{ background: "linear-gradient(0deg, rgba(5,2,8,0.8) 0%, transparent 22%)" }} />
      <Embers count={60} />
      <div style={{ position: "absolute", left: 60, top: 50, padding: "10px 34px", background: "linear-gradient(180deg,#3ccf5a,#1e8a35)", borderRadius: 18, fontFamily: IMPACT, fontSize: 64, color: "#fff", WebkitTextStroke: "4px #0a3a14", paintOrder: "stroke", transform: "rotate(-4deg)", boxShadow: "0 8px 0 #0d4a1c" }}>¡NUEVO!</div>
      <div style={{ position: "absolute", left: 50, top: 150, width: 980, fontFamily: IMPACT, fontSize: 168, lineHeight: 0.95, color: GOLD, WebkitTextStroke: "10px #1a0800", paintOrder: "stroke", textShadow: "0 0 40px #ff7a2a, 0 12px 0 #000" }}>
        CAMPANA
        <br />
        MALDITA
      </div>
      <div style={{ position: "absolute", left: 70, top: 500, padding: "12px 40px", background: "linear-gradient(180deg,#e0261a,#8a0c06)", fontFamily: IMPACT, fontSize: 96, color: "#fff", WebkitTextStroke: "5px #2a0000", paintOrder: "stroke", transform: "rotate(-3deg)", boxShadow: "0 10px 0 rgba(0,0,0,0.7), 0 0 40px rgba(255,40,20,0.6)" }}>
        🔔 ¡JEFE FINAL!
      </div>
    </AbsoluteFill>
  );
};

// ───────────── reemplazos de los videos viejos (cosas que ya están en el juego) ─────────────

// Combo: cinco peleas seguidas sin cortar el combo
export const ShortCombo2: React.FC = () => {
  const s = scenes.combo;
  let before = 0;
  const total = s.fights.reduce((sum, f) => sum + f.zombies.length, 0);
  const captions = ["Mi *récord de combo…", "sin *parar", "*más *rápido…", "¡NO *FALLES!", "¡último *golpe!"];
  return (
    <AbsoluteFill style={{ background: NIGHT }}>
      <Audio src={staticFile("update/audio_combo.wav")} />
      {s.fights.map((fight, i) => {
        const start = before;
        before += fight.zombies.length;
        return (
          <Sequence key={i} from={fight.from} durationInFrames={fight.len}>
            <Fight spec={fight} comboStart={start}>
              <Caption text={captions[i]} y={1360} size={92} every={3} />
            </Fight>
          </Sequence>
        );
      })}
      <Sequence name="Reto" from={330} durationInFrames={45}>
        <AbsoluteFill style={{ filter: "grayscale(0.6) brightness(0.6)", transform: "scale(1.1)" }}>
          <Freeze frame={74}>
            <Fight spec={s.fights[4]} comboStart={total - s.fights[4].zombies.length} />
          </Freeze>
        </AbsoluteFill>
        <Stamp text={`x${total}`} y={560} size={330} color="#ff8a2b" glow={BLOOD} />
        <Caption text="¿lo *superas? 👇" y={980} size={110} delay={10} every={4} />
      </Sequence>
      <Sequence name="Cierre" from={375}>
        <EndCard news="¿Cuál es tu récord de combo?" />
      </Sequence>
      {[60, 120, 180, 255, 330].map((f) => (
        <Sequence key={f} from={f} durationInFrames={6}><Flash peak={0.4} /></Sequence>
      ))}
      <Sequence from={375} durationInFrames={10}><Flash color={GOLD} peak={0.45} /></Sequence>
      <Progress />
    </AbsoluteFill>
  );
};

// Elige tu arma: tres armas peleando y la pregunta para comentar
const GunPick: React.FC<{ n: number; name: string; bg: string; x: number; delay: number; color: string }> = ({ n, name, bg, x, delay, color }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - delay, fps, config: { damping: 10, stiffness: 200 } });
  const pulse = 1 + Math.sin((frame + n * 10) / 5) * 0.03;
  return (
    <div style={{ position: "absolute", left: x, top: 620, width: 320, height: 560, borderRadius: 30, overflow: "hidden", border: `7px solid ${color}`, boxShadow: `0 0 40px ${color}`, transform: `translateY(${(1 - s) * 900}px) scale(${pulse})` }}>
      <Img src={staticFile(bg)} style={{ position: "absolute", width: "100%", height: "100%", objectFit: "cover", objectPosition: "62% 55%", transform: "scale(1.6)", transformOrigin: "62% 58%" }} />
      <div style={{ position: "absolute", left: 0, right: 0, top: 10, textAlign: "center", fontFamily: IMPACT, fontSize: 130, color: "#fff", WebkitTextStroke: "6px #000", paintOrder: "stroke" }}>{n}</div>
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 14, textAlign: "center", fontFamily: IMPACT, fontSize: 46, color: CREAM, WebkitTextStroke: "4px #000", paintOrder: "stroke" }}>{name}</div>
    </div>
  );
};

export const ShortArms2: React.FC = () => {
  const s = scenes.arms;
  const labels = [
    { n: 1, name: "BALLESTA", color: "#ffd36b" },
    { n: 2, name: "ESCOPETA", color: "#7fd4ff" },
    { n: 3, name: "LANZALLAMAS", color: "#ff7a3a" },
  ];
  return (
    <AbsoluteFill style={{ background: NIGHT }}>
      <Audio src={staticFile("update/audio_arms.wav")} />
      <Sequence name="Gancho" durationInFrames={30}>
        <Bg src="update/fps-escopeta.jpg" grade="brightness(0.4) saturate(0.8)" zoom={0.3} />
        <Vignette />
        <Caption text="Solo puedes *ELEGIR *UNA…" y={760} size={110} delay={2} every={4} />
      </Sequence>
      {s.fights.map((fight, i) => (
        <Sequence key={i} from={fight.from} durationInFrames={fight.len}>
          <Fight spec={fight} comboStart={i * 3}>
            <Ribbon n={labels[i].n} text={labels[i].name} color={["#9a6a10", "#1f6aa0", "#b3400c"][i]} />
          </Fight>
        </Sequence>
      ))}
      <Sequence name="Elige" from={270} durationInFrames={105}>
        <Bg src="update/bg-horda.jpg" grade="brightness(0.25) saturate(0.7) blur(5px)" zoom={0.1} />
        <Vignette />
        <Stamp text="¿CUÁL ELIGES?" y={300} size={150} color={GOLD} glow="#ff7a2a" delay={4} />
        <GunPick n={1} name="BALLESTA" bg="update/fps-ballesta.jpg" x={30} delay={8} color="#ffd36b" />
        <GunPick n={2} name="ESCOPETA" bg="update/fps-escopeta.jpg" x={380} delay={14} color="#7fd4ff" />
        <GunPick n={3} name="LANZALLAMAS" bg="update/fps-lanzallamas.jpg" x={730} delay={20} color="#ff7a3a" />
        <Caption text="comenta *1, *2 o *3 👇" y={1300} size={100} delay={30} every={4} />
      </Sequence>
      <Sequence name="Cierre" from={375}>
        <EndCard news="8 armas para mejorar" />
      </Sequence>
      {[30, 110, 190, 270].map((f) => (
        <Sequence key={f} from={f} durationInFrames={6}><Flash peak={0.45} /></Sequence>
      ))}
      <Sequence from={375} durationInFrames={10}><Flash color={GOLD} peak={0.45} /></Sequence>
      <Progress />
    </AbsoluteFill>
  );
};

// El Segador: llega en su semana, gigante, con su barra de vida
const ReaperFight: React.FC<{ spec: typeof scenes.reaper.boss }> = ({ spec }) => {
  const frame = useCurrentFrame();
  const gun = gunOf(spec.gun);
  const last = spec.hits[spec.hits.length - 1];
  const alive = frame < last;
  const p = Math.min(1, frame / last);
  const h = 900 + p * 500;
  const cx = 540 + Math.sin(frame / 14) * 60;
  const cy = 820 + p * 120;
  const hitsDone = spec.hits.filter((f) => frame >= f).length;
  const health = Math.max(0, 1 - hitsDone / spec.hits.length);
  const r = recoilAt(frame, spec.hits);
  const shots = spec.hits.map((f, i) => ({ f, x: 540 + (hash(i) - 0.5) * 300, y: 700 + (hash(i + 4) - 0.5) * 400, dmg: i === spec.hits.length - 1 ? "¡ELIMINADO!" : i % 6 === 5 ? `CRÍTICO -${18 + i}` : `-${4 + Math.floor(hash(i) * 6)}`, crit: i % 6 === 5 || i === spec.hits.length - 1 }));
  const swing = [40, 90, 140].map((f) => frame - f).find((f) => f >= 0 && f < 14);
  const k = swing !== undefined ? shake(swing, 30, 14) : { x: 0, y: 0 };
  return (
    <AbsoluteFill style={{ overflow: "hidden", transform: `translate(${k.x}px, ${k.y}px)` }}>
      <AbsoluteFill style={{ transform: `translateY(${r * 14}px) scale(${1.04 + r * 0.015})` }}>
        <Img src={staticFile(gun.bg)} style={{ width: "100%", height: "100%", filter: "brightness(0.42) saturate(0.6) hue-rotate(160deg) sepia(0.2)" }} />
        {alive ? (
          <Img src={staticFile("update/Reaper.png")} style={{ position: "absolute", left: cx - h * 0.5, top: cy - h * 0.55, height: h, width: h, objectFit: "contain", transform: `rotate(${Math.sin(frame / 4) * 3}deg)`, filter: spec.hits.some((f) => frame >= f && frame < f + 2) ? "brightness(3) saturate(0)" : "drop-shadow(0 0 40px rgba(140,200,255,0.5))" }} />
        ) : null}
        <Shots shots={shots} muzzle={gun.muzzle} />
        <Sequence from={last} durationInFrames={32} layout="none">
          <Burst x={540} y={800} colors={PALETTE.Reaper} count={40} size={60} seed={9} />
          <Popup text="+70 🪙" x={540} y={600} size={120} />
        </Sequence>
      </AbsoluteFill>
      {swing !== undefined ? <AbsoluteFill style={{ background: "rgba(255,0,0,0.25)" }} /> : null}
      <Crosshair x={540} y={700} />
      <Vignette color="rgba(0,10,30,0.85)" inner={40} />
      <div style={{ position: "absolute", left: 60, right: 60, top: 70 }}>
        <div style={{ fontFamily: IMPACT, fontSize: 52, color: CREAM, textAlign: "center", textShadow: "0 3px 0 #000, 0 0 18px #7fc0ff" }}>💀 SEGADOR</div>
        <div style={{ marginTop: 10, height: 44, borderRadius: 10, background: "rgba(0,0,0,0.75)", border: "4px solid #0a1a2b", overflow: "hidden" }}>
          <div style={{ width: `${health * 100}%`, height: "100%", background: "linear-gradient(180deg,#9fd8ff,#2a6ab0)" }} />
        </div>
      </div>
    </AbsoluteFill>
  );
};

export const ShortReaper: React.FC = () => {
  const s = scenes.reaper;
  return (
    <AbsoluteFill style={{ background: NIGHT }}>
      <Audio src={staticFile("update/audio_reaper.wav")} />
      <Sequence name="Normal" durationInFrames={45}>
        <Fight spec={s.fights[0]}>
          <Caption text="una partida *normal…" y={1360} delay={2} every={3} />
        </Fight>
      </Sequence>
      <Sequence name="Llega" from={45} durationInFrames={65}>
        <Bg src="update/fps-ballesta.jpg" grade="brightness(0.25) saturate(0.3) hue-rotate(160deg)" zoom={0.3} />
        <Img src={staticFile("update/Reaper.png")} style={{ position: "absolute", left: 140, top: 340, width: 800, height: 800, objectFit: "contain", filter: "brightness(0) drop-shadow(0 0 30px rgba(140,200,255,0.8))" }} />
        <Vignette />
        <Caption text="hasta que llega *SU *SEMANA 💀" y={1250} size={96} delay={6} every={4} />
        <Sequence from={41}>
          <Stamp text="EL SEGADOR" y={180} size={170} color="#cfe8ff" glow="#3a8aff" />
        </Sequence>
      </Sequence>
      <Sequence name="Pelea" from={s.boss.from} durationInFrames={s.boss.len}>
        <ReaperFight spec={s.boss} />
        <Caption text="¿solo o con *amigos?" y={1420} size={88} delay={20} every={4} />
      </Sequence>
      <Sequence name="Reto" from={310} durationInFrames={65}>
        <Bg src="update/bg-horda.jpg" grade="brightness(0.3) saturate(0.6) hue-rotate(160deg)" zoom={0.2} />
        <Vignette />
        <Stamp text="¿LO VENCES?" y={640} size={170} color="#cfe8ff" glow="#3a8aff" delay={20} />
        <Caption text="sale cada *3 *oleadas en su semana" y={900} size={76} delay={30} every={3} />
      </Sequence>
      <Sequence name="Cierre" from={375}>
        <EndCard news="Jefes semanales y ranking" />
      </Sequence>
      {[45, 110, 310].map((f) => (
        <Sequence key={f} from={f} durationInFrames={8}><Flash peak={0.6} /></Sequence>
      ))}
      <Sequence from={375} durationInFrames={10}><Flash color={GOLD} peak={0.45} /></Sequence>
      <Progress />
    </AbsoluteFill>
  );
};

// ───────────── contenido nuevo: clasificación, noob vs pro y oleadas ─────────────

const TIERS = [
  { id: "S", color: "#ff4d4d" },
  { id: "A", color: "#ff9a3a" },
  { id: "B", color: "#ffd84a" },
  { id: "C", color: "#7fe07f" },
  { id: "D", color: "#6ab0ff" },
];

// Clasifico a TODOS los zombis: cada uno sale grande y vuela a su fila
export const ShortTier: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const items = scenes.tier.items;
  const rowY = (i: number) => 330 + i * 230;
  const placed: Record<string, number> = {};
  return (
    <AbsoluteFill style={{ background: NIGHT }}>
      <Audio src={staticFile("update/audio_tier.wav")} />
      <Bg src="update/bg-horda.jpg" grade="brightness(0.22) saturate(0.6) blur(6px)" zoom={0.1} />
      <Stamp text="CLASIFICO A TODOS" y={70} size={110} color={GOLD} glow="#ff7a2a" tilt={0} />
      <Stamp text="LOS ZOMBIS" y={185} size={90} color={CREAM} glow={BLOOD} delay={6} tilt={0} />
      {TIERS.map((tier, i) => (
        <div key={tier.id} style={{ position: "absolute", left: 30, right: 30, top: rowY(i), height: 210, borderRadius: 18, background: "rgba(10,8,16,0.75)", border: `4px solid ${tier.color}`, overflow: "hidden" }}>
          <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: 150, background: tier.color, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: IMPACT, fontSize: 120, color: "#1a0a0a" }}>{tier.id}</div>
        </div>
      ))}
      {items.map((item) => {
        const tierIndex = TIERS.findIndex((t) => t.id === item.tier);
        const slot = placed[item.tier] ?? 0;
        placed[item.tier] = slot + 1;
        const f = frame - item.at;
        if (f < -14) return null;
        // entra al centro grande (-14..0) y vuela a su fila (0..12)
        const fly = interpolate(f, [0, 12], [0, 1], { ...CLAMP, easing: OUT });
        const pop = spring({ frame: f + 14, fps, config: { damping: 10, stiffness: 220 } });
        const big = 620;
        const small = 190;
        const tx = interpolate(fly, [0, 1], [540, 280 + slot * 210]);
        const ty = interpolate(fly, [0, 1], [1000, rowY(tierIndex) + 105]);
        const size = interpolate(fly, [0, 1], [big, small]) * (f < 0 ? pop : 1);
        return (
          <div key={item.type}>
            {f < 6 ? (
              <div style={{ position: "absolute", left: 0, right: 0, top: 1360, textAlign: "center", fontFamily: IMPACT, fontSize: 96, color: "#fff", WebkitTextStroke: "6px #000", paintOrder: "stroke", opacity: interpolate(f, [0, 6], [1, 0], CLAMP) }}>{NAMES[item.type]}</div>
            ) : null}
            <Img src={staticFile(`update/${item.type}.png`)} style={{ position: "absolute", left: tx - size / 2, top: ty - size / 2, width: size, height: size, objectFit: "contain", filter: "drop-shadow(0 8px 12px rgba(0,0,0,0.8))" }} />
            <Sequence from={item.at + 12} durationInFrames={20} layout="none">
              <Burst x={280 + slot * 210} y={rowY(tierIndex) + 105} colors={[TIERS[tierIndex].color, "#fff"]} count={10} size={18} seed={tierIndex + slot} />
            </Sequence>
          </div>
        );
      })}
      <Sequence name="Pregunta" from={330} durationInFrames={45}>
        <AbsoluteFill style={{ background: "rgba(0,0,0,0.7)" }} />
        <Stamp text="¿ESTÁS DE ACUERDO?" y={760} size={100} color={GOLD} glow={BLOOD} />
        <Caption text="dime cuál *cambiarías 👇" y={1010} size={90} delay={8} every={3} />
      </Sequence>
      <Sequence name="Cierre" from={375}>
        <EndCard news="11 zombis y jefes para cazar" />
      </Sequence>
      <Sequence from={375} durationInFrames={10}><Flash color={GOLD} peak={0.45} /></Sequence>
      <Progress />
    </AbsoluteFill>
  );
};

// Noob vs Pro: las dos peleas lado a lado (cada una a media escala)
const Half: React.FC<{ x: number; label: string; color: string; children: React.ReactNode }> = ({ x, label, color, children }) => (
  <>
    <div style={{ position: "absolute", left: x, top: 470, width: 540, height: 960, overflow: "hidden", borderLeft: x > 0 ? "6px solid #000" : "none" }}>
      <div style={{ position: "absolute", left: -108, top: -192, width: 1080, height: 1920, transform: "scale(0.7)", transformOrigin: "0 0" }}>{children}</div>
    </div>
    <div style={{ position: "absolute", left: x, width: 540, top: 330, textAlign: "center", fontFamily: IMPACT, fontSize: 120, color, WebkitTextStroke: "6px #000", paintOrder: "stroke", textShadow: `0 0 30px ${color}` }}>{label}</div>
  </>
);

export const ShortNoobPro: React.FC = () => {
  const s = scenes.noobpro;
  const noob = s.noob as FightSpec;
  const pro = s.pro as FightSpec;
  return (
    <AbsoluteFill style={{ background: "#0b0710" }}>
      <Audio src={staticFile("update/audio_noobpro.wav")} />
      <Stamp text="NOOB vs PRO" y={90} size={150} color={GOLD} glow="#ff7a2a" tilt={0} />
      <Sequence from={s.noob.from} durationInFrames={s.noob.len} layout="none">
        <Half x={0} label="NOOB 🤡" color="#9fd8ff">
          <Fight spec={noob} />
        </Half>
      </Sequence>
      <Sequence from={s.pro.from} durationInFrames={s.pro.len} layout="none">
        <Half x={540} label="PRO 😎" color="#ffd36b">
          <Fight spec={pro} />
        </Half>
      </Sequence>
      <Sequence from={30} durationInFrames={300} layout="none">
        <Caption text="mismo juego… *distinto *nivel" y={1470} size={80} delay={10} every={4} />
      </Sequence>
      <Sequence name="Pregunta" from={330} durationInFrames={45}>
        <AbsoluteFill style={{ background: "rgba(0,0,0,0.6)" }} />
        <Stamp text="¿CUÁL ERES TÚ?" y={760} size={140} color={GOLD} glow={BLOOD} />
        <Caption text="sé *sincero 👇" y={960} size={100} delay={8} every={3} />
      </Sequence>
      <Sequence name="Cierre" from={375}>
        <EndCard news="De noob a pro: mejora tus armas" />
      </Sequence>
      <Sequence from={30} durationInFrames={8}><Flash peak={0.5} /></Sequence>
      <Sequence from={375} durationInFrames={10}><Flash color={GOLD} peak={0.45} /></Sequence>
      <Progress />
    </AbsoluteFill>
  );
};

// ¿Cuántas oleadas aguantas?: cada vez más zombis y la campana bajando
const WaveTag: React.FC<{ wave: number; bell: number }> = ({ wave, bell }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame, fps, config: { damping: 9, stiffness: 240 } });
  return (
    <>
      <div style={{ position: "absolute", left: 0, right: 0, top: 120, textAlign: "center", fontFamily: IMPACT, fontSize: 150, color: wave >= 8 ? "#ff5a3a" : CREAM, WebkitTextStroke: "7px #000", paintOrder: "stroke", transform: `scale(${interpolate(s, [0, 1], [2, 1])})`, textShadow: "0 0 30px #ff3a1a" }}>OLEADA {wave}</div>
      <div style={{ position: "absolute", left: 140, right: 140, top: 300, height: 40, borderRadius: 10, background: "rgba(0,0,0,0.7)", border: "4px solid #2b1408", overflow: "hidden" }}>
        <div style={{ width: `${bell * 100}%`, height: "100%", background: "linear-gradient(180deg,#ffd36b,#c98a1a)" }} />
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, top: 350, textAlign: "center", fontFamily: IMPACT, fontSize: 44, color: GOLD, WebkitTextStroke: "3px #000", paintOrder: "stroke" }}>🔔 CAMPANA</div>
    </>
  );
};

export const ShortWaves: React.FC = () => {
  const s = scenes.waves;
  const bells = [1, 0.85, 0.65, 0.4, 0.15];
  return (
    <AbsoluteFill style={{ background: NIGHT }}>
      <Audio src={staticFile("update/audio_waves.wav")} />
      <Sequence name="Gancho" durationInFrames={30}>
        <Bg src="update/bg-asedio.jpg" grade="brightness(0.45) saturate(0.8)" zoom={0.3} />
        <Vignette />
        <Caption text="¿Cuántas *oleadas aguantas?" y={760} size={120} delay={2} every={4} />
      </Sequence>
      {s.fights.map((fight, i) => (
        <Sequence key={i} from={fight.from} durationInFrames={fight.len}>
          <Fight spec={fight} comboStart={s.fights.slice(0, i).reduce((n, f) => n + f.zombies.length, 0)} grade={`brightness(${0.8 - i * 0.08}) saturate(${1.15 - i * 0.1}) sepia(${i * 0.12}) hue-rotate(${-i * 6}deg)`}>
            <WaveTag wave={s.labels[i]} bell={bells[i]} />
          </Fight>
        </Sequence>
      ))}
      <Sequence name="Cae" from={330} durationInFrames={45}>
        <Bg src="update/bg-asedio.jpg" grade="brightness(0.3) saturate(0.2) contrast(1.3)" zoom={0.4} />
        <AbsoluteFill style={{ background: "rgba(120,0,0,0.35)" }} />
        <Stamp text="¡LA CAMPANA CAYÓ!" y={640} size={120} color={CREAM} glow={BLOOD} />
        <Caption text="llegué a la *oleada *10… ¿y *tú? 👇" y={860} size={86} delay={10} every={3} />
      </Sequence>
      <Sequence name="Cierre" from={375}>
        <EndCard news="Oleadas sin fin con tus amigos" />
      </Sequence>
      {s.fights.map((f) => (
        <Sequence key={f.from} from={f.from} durationInFrames={6}><Flash peak={0.4} /></Sequence>
      ))}
      <Sequence from={330} durationInFrames={10}><Flash color="#ff3020" peak={0.7} /></Sequence>
      <Sequence from={375} durationInFrames={10}><Flash color={GOLD} peak={0.45} /></Sequence>
      <Progress />
    </AbsoluteFill>
  );
};
