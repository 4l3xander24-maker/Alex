// Videos cortos de la actualización: jefe final, bestiario coleccionable y
// resumen con el código de regalo. Sin clips grabados: usan capturas reales
// del juego (public/update) y el jefe final se muestra como silueta (teaser).
import { Audio } from "@remotion/media";
import { loadFont } from "@remotion/fonts";
import {
  AbsoluteFill,
  Easing,
  Img,
  Sequence,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

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

const shake = (frame: number, power: number, length = 14) => {
  const k = frame < 0 || frame > length ? 0 : 1 - frame / length;
  return {
    x: Math.sin(frame * 91.7) * power * k,
    y: Math.cos(frame * 57.3) * power * k,
  };
};

// ───────────── piezas ─────────────

const Bg: React.FC<{ src: string; grade?: string; zoom?: number }> = ({ src, grade = "brightness(0.45) saturate(0.8)", zoom = 0.12 }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const s = 1.05 + zoom * (frame / durationInFrames);
  return (
    <AbsoluteFill style={{ overflow: "hidden", background: NIGHT }}>
      <Img src={staticFile(src)} style={{ width: "100%", height: "100%", objectFit: "cover", transform: `scale(${s})`, filter: grade }} />
    </AbsoluteFill>
  );
};

const Vignette: React.FC<{ color?: string }> = ({ color = "rgba(0,0,0,0.85)" }) => (
  <AbsoluteFill style={{ background: `radial-gradient(ellipse at 50% 45%, transparent 35%, ${color} 100%)` }} />
);

const Embers: React.FC<{ count?: number; color?: string }> = ({ count = 40, color = "#ff9a40" }) => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill>
      {new Array(count).fill(0).map((_, i) => {
        const seed = Math.sin(i * 12.9898) * 43758.5453;
        const r = seed - Math.floor(seed);
        const x = (r * 1080 + Math.sin((frame + i * 40) / 30) * 30) % 1080;
        const speed = 2 + r * 4;
        const y = 1920 - ((frame * speed + i * 97) % 2100);
        const size = 4 + r * 8;
        return <div key={i} style={{ position: "absolute", left: x, top: y, width: size, height: size, borderRadius: size, background: color, boxShadow: `0 0 ${size * 2}px ${color}`, opacity: 0.4 + r * 0.5 }} />;
      })}
    </AbsoluteFill>
  );
};

const Flash: React.FC<{ color?: string; peak?: number; length?: number }> = ({ color = "#fff", peak = 0.8, length = 10 }) => {
  const frame = useCurrentFrame();
  const o = interpolate(frame, [0, length], [peak, 0], CLAMP);
  return <AbsoluteFill style={{ background: color, opacity: o }} />;
};

// Texto grande que cae y rebota
const Stamp: React.FC<{ text: string; y: number; size: number; color?: string; glow?: string; delay?: number; font?: string; tilt?: number }> = ({
  text,
  y,
  size,
  color = CREAM,
  glow = BLOOD,
  delay = 0,
  font = IMPACT,
  tilt = -3,
}) => {
  const frame = useCurrentFrame() - delay;
  const { fps } = useVideoConfig();
  if (frame < 0) return null;
  const s = spring({ frame, fps, config: { damping: 11, stiffness: 180 } });
  const scale = interpolate(s, [0, 1], [2.4, 1]);
  const o = interpolate(frame, [0, 4], [0, 1], CLAMP);
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        top: y,
        textAlign: "center",
        fontFamily: font,
        fontSize: size,
        lineHeight: 1,
        color,
        opacity: o,
        transform: `scale(${scale}) rotate(${tilt}deg)`,
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
  const o = interpolate(frame, [0, 10], [0, 1], CLAMP);
  const dy = interpolate(frame, [0, 14], [30, 0], { ...CLAMP, easing: OUT });
  return (
    <div style={{ position: "absolute", left: 60, right: 60, top: y + dy, textAlign: "center", fontFamily: SERIF, fontWeight: 700, fontSize: size, color, opacity: o, textShadow: "0 4px 12px #000, 0 0 3px #000" }}>
      {text}
    </div>
  );
};

// Silueta del Campanero Maldito: zombi gigante de bloques con una campana rajada de casco
const BellringerShape: React.FC<{ eyes: number; rim: number }> = ({ eyes, rim }) => (
  <svg viewBox="0 0 600 900" width={900} height={1350} style={{ overflow: "visible" }}>
    <defs>
      <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
        <feGaussianBlur stdDeviation="8" result="b" />
        <feMerge>
          <feMergeNode in="b" />
          <feMergeNode in="SourceGraphic" />
        </feMerge>
      </filter>
    </defs>
    <g fill="#050307" stroke={`rgba(255,140,60,${rim})`} strokeWidth={4}>
      {/* piernas */}
      <rect x={175} y={600} width={110} height={300} />
      <rect x={315} y={600} width={110} height={300} />
      {/* torso */}
      <rect x={130} y={330} width={340} height={300} />
      {/* brazos estirados como zombi */}
      <rect x={20} y={340} width={120} height={120} />
      <rect x={-60} y={360} width={110} height={90} />
      <rect x={460} y={340} width={120} height={120} />
      <rect x={550} y={360} width={110} height={90} />
      {/* cabeza */}
      <rect x={215} y={200} width={170} height={150} />
      {/* campana de casco */}
      <path d="M180 250 Q180 60 300 40 Q420 60 420 250 L445 275 L155 275 Z" />
      <rect x={285} y={10} width={30} height={34} />
    </g>
    {/* cadenas */}
    <g stroke={`rgba(200,170,120,${rim * 0.8})`} strokeWidth={10} fill="none" strokeDasharray="22 12">
      <path d="M140 350 L460 600" />
      <path d="M460 350 L140 600" />
    </g>
    {/* grieta brillante de la campana */}
    <path d="M300 45 L285 110 L310 150 L292 210 L305 262" stroke={`rgba(255,180,60,${rim})`} strokeWidth={7} fill="none" filter="url(#glow)" />
    {/* ojos */}
    <g fill="#ff2a1a" opacity={eyes} filter="url(#glow)">
      <rect x={240} y={290} width={40} height={24} />
      <rect x={320} y={290} width={40} height={24} />
    </g>
  </svg>
);

const BossBar: React.FC<{ health: number; tag: string; show: number }> = ({ health, tag, show }) => (
  <div style={{ position: "absolute", left: 70, right: 70, top: 210, opacity: show, transform: `translateY(${(1 - show) * -40}px)` }}>
    <div style={{ fontFamily: IMPACT, fontSize: 58, color: CREAM, textAlign: "center", textShadow: "0 3px 0 #000, 0 0 18px #ff5a2a" }}>
      🔔 CAMPANERO MALDITO{tag ? <span style={{ color: GOLD }}>{`  ·  ${tag}`}</span> : null}
    </div>
    <div style={{ marginTop: 12, height: 46, borderRadius: 10, background: "rgba(0,0,0,0.75)", border: "4px solid #2b1408", overflow: "hidden" }}>
      <div style={{ width: `${health * 100}%`, height: "100%", background: "linear-gradient(180deg,#ff6b4a,#b3160c)", boxShadow: "inset 0 6px 0 rgba(255,255,255,0.25)" }} />
    </div>
  </div>
);

const EndCard: React.FC<{ news: string }> = ({ news }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame, fps, config: { damping: 12 } });
  return (
    <AbsoluteFill style={{ background: `radial-gradient(ellipse at 50% 40%, #3a0f12 0%, ${NIGHT} 70%)` }}>
      <Embers count={30} />
      <div style={{ position: "absolute", left: 0, right: 0, top: 360, display: "flex", justifyContent: "center" }}>
        <Img src={staticFile("icono.png")} style={{ width: 420, height: 420, borderRadius: 64, transform: `scale(${s})`, boxShadow: "0 0 80px rgba(255,120,40,0.6)" }} />
      </div>
      <Stamp text="CAMPANA MALDITA" y={860} size={118} color={GOLD} glow="#ff7a2a" delay={6} tilt={0} />
      <Sub text={news} y={1030} size={60} delay={14} color={CREAM} />
      <Sub text="Gratis en Roblox · hasta 5 amigos" y={1150} size={50} delay={22} color="#e6d3b5" />
      <Sub text="Busca «Campana Maldita» 👇" y={1500} size={58} delay={34} color={GOLD} />
    </AbsoluteFill>
  );
};

// ───────────── 1 · Jefe final ─────────────

const BossReveal: React.FC = () => {
  const frame = useCurrentFrame();
  const rise = interpolate(frame, [0, 70], [700, 0], { ...CLAMP, easing: OUT });
  const eyes = interpolate(frame, [42, 48], [0, 1], CLAMP);
  const rim = interpolate(frame, [0, 60], [0.15, 0.9], CLAMP);
  const moon = interpolate(frame, [0, 165], [0.5, 1], CLAMP);
  // la barra baja al 66% y al 33% (las fases)
  const health = interpolate(frame, [95, 115, 120, 140, 145, 160], [1, 0.66, 0.66, 0.33, 0.33, 0.12], CLAMP);
  const tag = frame >= 140 ? "🔥 Furia" : frame >= 115 ? "🔔 Toque de difuntos" : "";
  const hit = frame >= 140 ? shake(frame - 140, 26) : frame >= 115 ? shake(frame - 115, 18) : shake(frame - 45, 22);
  const barIn = interpolate(frame, [80, 95], [0, 1], CLAMP);
  return (
    <AbsoluteFill style={{ transform: `translate(${hit.x}px, ${hit.y}px)` }}>
      <Bg src="update/bg-asedio.jpg" grade="brightness(0.28) saturate(0.6) sepia(0.4) hue-rotate(-25deg)" zoom={0.1} />
      <div style={{ position: "absolute", left: 540 - 330, top: 330, width: 660, height: 660, borderRadius: 660, background: `radial-gradient(circle, rgba(255,70,40,${moon}) 0%, rgba(160,20,10,${moon * 0.8}) 55%, transparent 72%)`, filter: "blur(2px)" }} />
      <div style={{ position: "absolute", left: 540 - 450, top: 520 + rise }}>
        <BellringerShape eyes={eyes} rim={rim} />
      </div>
      <Embers count={50} />
      <Vignette />
      <BossBar health={health} tag={tag} show={barIn} />
      <Stamp text="JEFE FINAL" y={1500} size={190} color={CREAM} glow={BLOOD} delay={50} />
      <Sequence from={45} durationInFrames={10}><Flash color="#ff4020" peak={0.45} /></Sequence>
      <Sequence from={115} durationInFrames={8}><Flash color="#ffb060" peak={0.35} /></Sequence>
      <Sequence from={140} durationInFrames={8}><Flash color="#ff3020" peak={0.45} /></Sequence>
    </AbsoluteFill>
  );
};

export const ShortFinalBoss: React.FC = () => {
  const frame = useCurrentFrame();
  const hook = shake(frame - 8, 16);
  return (
    <AbsoluteFill style={{ background: NIGHT }}>
      <Audio src={staticFile("update/audio_boss.wav")} />
      <Sequence name="Gancho" durationInFrames={105}>
        <AbsoluteFill style={{ transform: `translate(${hook.x}px, ${hook.y}px)` }}>
          <Bg src="update/bg-asedio.jpg" grade="brightness(0.5) saturate(0.8)" zoom={0.2} />
          <Vignette />
          <Stamp text="OLEADA FINAL" y={560} size={170} color={GOLD} glow="#ff7a2a" delay={4} />
          <Sub text="La campana suena una última vez…" y={780} size={62} delay={18} />
          <Sequence from={62}>
            <Stamp text="ALGO DESPIERTA" y={1150} size={140} color={CREAM} glow={BLOOD} tilt={2} />
          </Sequence>
        </AbsoluteFill>
      </Sequence>
      <Sequence name="Aparece" from={105} durationInFrames={170}>
        <BossReveal />
      </Sequence>
      <Sequence name="Reto" from={275} durationInFrames={95}>
        <Bg src="update/bg-horda.jpg" grade="brightness(0.4) saturate(0.9)" zoom={0.15} />
        <Vignette />
        <Stamp text="¿LO DERROTAS?" y={700} size={160} color={GOLD} glow={BLOOD} />
        <Sub text="Si cae, ganan la partida" y={900} size={64} delay={14} />
        <Sub text="Solo o con hasta 5 amigos" y={1000} size={56} delay={26} color="#e6d3b5" />
      </Sequence>
      <Sequence name="Cierre" from={370}>
        <EndCard news="NUEVO: el Jefe Final" />
      </Sequence>
      <Sequence from={0} durationInFrames={10}><Flash peak={0.6} /></Sequence>
      <Sequence from={105} durationInFrames={8}><Flash peak={0.7} /></Sequence>
      <Sequence from={275} durationInFrames={8}><Flash peak={0.6} /></Sequence>
      <Sequence from={370} durationInFrames={10}><Flash color={GOLD} peak={0.6} /></Sequence>
    </AbsoluteFill>
  );
};

// ───────────── 2 · Bestiario coleccionable ─────────────

const ENEMIES = ["Cone", "Knight", "Spitter", "Parasite", "Colossus", "Mutant", "Fatso", "King", "Queen", "Dragon", "Reaper"];
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
const MEDALS = ["🥉", "🥈", "🥇", "🥉", "🥇", "🥈", "🥉", "🥈", "🥇", "🥉", "🥈"];
const REVEAL_START = 70;
const REVEAL_EVERY = 17;

const Card: React.FC<{ index: number; x: number; y: number; w: number; h: number }> = ({ index, x, y, w, h }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const enter = spring({ frame: frame - index * 2, fps, config: { damping: 14 } });
  const last = index >= ENEMIES.length;
  const revealAt = REVEAL_START + index * REVEAL_EVERY;
  const revealed = !last && frame >= revealAt;
  const pop = revealed ? spring({ frame: frame - revealAt, fps, config: { damping: 9, stiffness: 200 } }) : 0;
  const flip = revealed ? interpolate(frame - revealAt, [0, 5], [0, 1], CLAMP) : 0;
  const pulse = last ? 0.5 + 0.5 * Math.sin(frame / 5) : 0;
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
        background: last ? "linear-gradient(180deg,#2a0a0c,#120406)" : "linear-gradient(180deg,#2c2f3d,#191b24)",
        border: `5px solid ${border}`,
        boxShadow: revealed ? `0 0 ${30 * (1 - flip) + 14}px rgba(255,200,90,0.55)` : last ? `0 0 ${20 + pulse * 30}px rgba(255,40,30,0.6)` : "0 8px 20px rgba(0,0,0,0.6)",
        transform: `scale(${interpolate(enter, [0, 1], [0.3, 1]) * (1 + pop * 0.0 + (revealed ? (1 - pop) * 0.12 : 0))})`,
        opacity: enter,
        overflow: "hidden",
      }}
    >
      {last ? (
        <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", transform: "scale(0.24)", transformOrigin: "50% 50%" }}>
          <div style={{ position: "absolute", top: -360 }}>
            <BellringerShape eyes={1} rim={0.5} />
          </div>
        </div>
      ) : (
        <Img
          src={staticFile(`update/${ENEMIES[index]}.png`)}
          style={{ position: "absolute", left: 14, right: 14, top: 18, width: w - 38, height: h - 100, objectFit: "contain", filter: revealed ? "none" : "brightness(0) drop-shadow(0 0 6px rgba(160,170,220,0.5))" }}
        />
      )}
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 14, textAlign: "center", fontFamily: IMPACT, fontSize: 38, color: revealed ? CREAM : last ? "#ff7a6a" : "#9aa0b8", textShadow: "0 3px 0 #000" }}>
        {revealed ? NAMES[ENEMIES[index]] : "???"}
      </div>
      {revealed ? <div style={{ position: "absolute", right: 10, top: 6, fontSize: 56, transform: `scale(${pop})` }}>{MEDALS[index]}</div> : null}
    </div>
  );
};

const Grid: React.FC = () => {
  const frame = useCurrentFrame();
  const found = Math.max(0, Math.min(ENEMIES.length, Math.floor((frame - REVEAL_START) / REVEAL_EVERY) + 1));
  const w = 300;
  const h = 330;
  const gap = 36;
  const left = (1080 - (w * 3 + gap * 2)) / 2;
  return (
    <AbsoluteFill>
      {new Array(12).fill(0).map((_, i) => (
        <Card key={i} index={i} x={left + (i % 3) * (w + gap)} y={390 + Math.floor(i / 3) * (h + 26)} w={w} h={h} />
      ))}
      <div style={{ position: "absolute", left: 0, right: 0, top: 260, textAlign: "center", fontFamily: SERIF, fontWeight: 700, fontSize: 54, color: CREAM, textShadow: "0 3px 10px #000" }}>
        📖 Descubiertos <span style={{ color: GOLD }}>{found}</span>/16
      </div>
    </AbsoluteFill>
  );
};

export const ShortBestiary: React.FC = () => {
  const frame = useCurrentFrame();
  // al final la cámara se acerca a la última carta (el jefe final)
  const zoom = interpolate(frame, [262, 300], [1, 2.3], { ...CLAMP, easing: OUT });
  const fade = interpolate(frame, [262, 290], [1, 0], CLAMP);
  const lastX = 540 - ((1080 - (300 * 3 + 36 * 2)) / 2 + 2 * 336 + 150);
  const lastY = 960 - (390 + 3 * 356 + 165);
  return (
    <AbsoluteFill style={{ background: NIGHT }}>
      <Audio src={staticFile("update/audio_bestiary.wav")} />
      <Bg src="update/bg-campamento.jpg" grade="brightness(0.25) saturate(0.6) blur(6px)" zoom={0.08} />
      <Vignette />
      <Sequence name="Colección" durationInFrames={370}>
        <AbsoluteFill style={{ transform: `scale(${zoom}) translate(${(lastX * (zoom - 1)) / zoom}px, ${(lastY * (zoom - 1)) / zoom}px)` }}>
          <Grid />
        </AbsoluteFill>
        <AbsoluteFill style={{ opacity: fade }}>
          <Stamp text="¿LOS TIENES TODOS?" y={110} size={112} color={GOLD} glow="#ff7a2a" tilt={0} />
        </AbsoluteFill>
        <Sequence from={300}>
          <Stamp text="EL ÚLTIMO" y={170} size={150} color={CREAM} glow={BLOOD} />
          <Sub text="solo aparece en la oleada final…" y={1560} size={60} delay={10} />
          <Sub text="Mátalos y gana medallas 🥉🥈🥇" y={1680} size={52} delay={24} color={GOLD} />
        </Sequence>
      </Sequence>
      <Sequence name="Cierre" from={370}>
        <EndCard news="NUEVO: Bestiario coleccionable" />
      </Sequence>
      <Sequence from={300} durationInFrames={10}><Flash color="#ff3020" peak={0.5} /></Sequence>
      <Sequence from={370} durationInFrames={10}><Flash color={GOLD} peak={0.6} /></Sequence>
    </AbsoluteFill>
  );
};

// ───────────── 3 · Resumen de la actualización + código ─────────────

const Feature: React.FC<{ icon: string; title: string; text: string; color: string }> = ({ icon, title, text, color }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame, fps, config: { damping: 12 } });
  const k = shake(frame, 14, 10);
  return (
    <AbsoluteFill style={{ transform: `translate(${k.x}px, ${k.y}px)` }}>
      <div style={{ position: "absolute", left: 0, right: 0, top: 520, textAlign: "center", fontSize: 260, transform: `scale(${s}) rotate(${(1 - s) * -30}deg)` }}>{icon}</div>
      <Stamp text={title} y={880} size={130} color={color} glow={BLOOD} tilt={-2} />
      <Sub text={text} y={1080} size={60} delay={8} />
    </AbsoluteFill>
  );
};

export const ShortUpdate: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const code = spring({ frame: frame - 300, fps, config: { damping: 10 } });
  const features = [
    { icon: "🔔", title: "JEFE FINAL", text: "El Campanero Maldito cierra la última oleada", color: GOLD },
    { icon: "📖", title: "BESTIARIO", text: "Colecciona a todos los zombis y gana medallas", color: CREAM },
    { icon: "🔥", title: "RACHA DIARIA", text: "Juega cada día y el premio crece", color: "#ff9a50" },
    { icon: "❄️", title: "SKINS DE INVIERNO", text: "Gorro navideño, Muñeco de nieve y Reina del hielo", color: "#9fdcff" },
  ];
  return (
    <AbsoluteFill style={{ background: NIGHT }}>
      <Audio src={staticFile("update/audio_update.wav")} />
      <Bg src="update/bg-horda.jpg" grade="brightness(0.3) saturate(0.7)" zoom={0.25} />
      <Embers count={36} />
      <Vignette />
      <Sequence name="Gancho" durationInFrames={60}>
        <Stamp text="ACTUALIZACIÓN" y={640} size={150} color={GOLD} glow="#ff7a2a" />
        <Stamp text="ÉPICA" y={820} size={230} color={CREAM} glow={BLOOD} delay={14} tilt={3} />
      </Sequence>
      {features.map((f, i) => (
        <Sequence key={f.title} name={f.title} from={60 + i * 60} durationInFrames={60}>
          <Feature {...f} />
        </Sequence>
      ))}
      <Sequence name="Código" from={300} durationInFrames={80}>
        <Stamp text="CÓDIGO GRATIS" y={520} size={140} color={CREAM} glow={BLOOD} />
        <div
          style={{
            position: "absolute",
            left: 120,
            right: 120,
            top: 760,
            padding: "40px 0",
            borderRadius: 30,
            border: `8px dashed ${GOLD}`,
            background: "rgba(40,20,4,0.85)",
            textAlign: "center",
            fontFamily: IMPACT,
            fontSize: 140,
            color: GOLD,
            letterSpacing: 6,
            transform: `scale(${code}) rotate(${(1 - code) * 12}deg)`,
            textShadow: "0 0 30px #ff9a40, 0 6px 0 #000",
          }}
        >
          BIENVENIDO
        </div>
        <Sub text="= 200 monedas 🪙" y={1060} size={80} delay={14} color={GOLD} />
        <Sub text="Canjéalo en ⚙️ Opciones › Códigos" y={1190} size={54} delay={24} />
      </Sequence>
      <Sequence name="Cierre" from={380}>
        <EndCard news="Nueva actualización disponible" />
      </Sequence>
      {[0, 60, 120, 180, 240, 300].map((f) => (
        <Sequence key={f} from={f} durationInFrames={8}><Flash peak={0.55} /></Sequence>
      ))}
      <Sequence from={380} durationInFrames={10}><Flash color={GOLD} peak={0.6} /></Sequence>
    </AbsoluteFill>
  );
};
