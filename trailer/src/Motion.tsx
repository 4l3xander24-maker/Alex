import { Audio, Video } from "@remotion/media";
import { loadFont } from "@remotion/fonts";
import {
  AbsoluteFill,
  Easing,
  Img,
  Sequence,
  interpolate,
  random,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

const IMPACT = "MotionImpact";
const SERIF = "MotionGeorgia";
loadFont({ family: IMPACT, url: staticFile("fonts/Impact.ttf") });
loadFont({ family: SERIF, url: staticFile("fonts/GeorgiaBold.ttf"), weight: "700" });

const GOLD = "#ffd36b";
const ORANGE = "#ff8a2b";
const BLOOD = "#ff3b2f";
const CREAM = "#fff1d6";
const NIGHT = "#08030f";
const PLUM = "#2a0b2e";

const OUT = Easing.bezier(0.16, 1, 0.3, 1);
const CLAMP = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

// ───────────────────────── piezas base ─────────────────────────

const shakeAt = (frame: number, power: number, length = 14) => {
  const decay = frame < 0 || frame > length ? 0 : 1 - frame / length;
  const a = Math.sin(frame * 12.9898) * 43758.5453;
  const b = Math.sin(frame * 78.233) * 12345.678;
  return { x: (a - Math.floor(a) - 0.5) * 2 * power * decay, y: (b - Math.floor(b) - 0.5) * 2 * power * decay };
};

// Fondo gráfico: degradado, puntos que se desplazan y bloques diagonales
const Backdrop: React.FC<{ from?: string; to?: string; accent?: string; blocks?: boolean }> = ({
  from = PLUM,
  to = NIGHT,
  accent = BLOOD,
  blocks = true,
}) => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{ background: `radial-gradient(ellipse at 50% 35%, ${from} 0%, ${to} 70%)` }}>
      <AbsoluteFill
        style={{
          backgroundImage: "radial-gradient(rgba(255,255,255,0.09) 2.5px, transparent 2.5px)",
          backgroundSize: "44px 44px",
          backgroundPosition: `${frame * 0.8}px ${frame * 0.5}px`,
        }}
      />
      {blocks ? (
        <>
          <div
            style={{
              position: "absolute",
              left: -200,
              top: interpolate(frame, [0, 70], [1500, 1060], { ...CLAMP, easing: OUT }),
              width: 1600,
              height: 700,
              background: accent,
              opacity: 0.22,
              rotate: "-14deg",
            }}
          />
          <div
            style={{
              position: "absolute",
              left: -300,
              top: interpolate(frame, [0, 70], [-600, -230], { ...CLAMP, easing: OUT }),
              width: 1700,
              height: 520,
              background: GOLD,
              opacity: 0.13,
              rotate: "-14deg",
            }}
          />
        </>
      ) : null}
    </AbsoluteFill>
  );
};

const Embers: React.FC<{ count?: number; tint?: string }> = ({ count = 30, tint = ORANGE }) => {
  const frame = useCurrentFrame();
  const { height } = useVideoConfig();
  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      {new Array(count).fill(0).map((_, i) => {
        const speed = 0.5 + random(`s${i}`) * 1.6;
        const size = 3 + random(`z${i}`) * 7;
        const y = height - ((frame * speed * 3 + random(`y${i}`) * height) % (height + 80)) + 40;
        const x = random(`x${i}`) * 1080 + Math.sin(frame / 20 + i) * 30;
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: x,
              top: y,
              width: size,
              height: size,
              borderRadius: size,
              backgroundColor: tint,
              boxShadow: `0 0 ${size * 3}px ${tint}`,
              opacity: interpolate(y, [0, height * 0.25, height], [0, 0.9, 0.2]),
            }}
          />
        );
      })}
    </AbsoluteFill>
  );
};

// Texto cinético: cada palabra sube desde una máscara
const KText: React.FC<{
  words: string[];
  size: number;
  y: number;
  color?: string;
  font?: string;
  stagger?: number;
  stroke?: string;
  glow?: string;
  fadeOut?: number;
}> = ({ words, size, y, color = CREAM, font = IMPACT, stagger = 5, stroke, glow, fadeOut = 10 }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const out = fadeOut > 0 ? interpolate(frame, [durationInFrames - fadeOut, durationInFrames], [1, 0], CLAMP) : 1;
  return (
    <div
      style={{
        position: "absolute",
        left: 40,
        right: 40,
        top: y,
        display: "flex",
        flexWrap: "wrap",
        justifyContent: "center",
        columnGap: size * 0.28,
        opacity: out,
      }}
    >
      {words.map((word, i) => {
        const t = interpolate(frame - i * stagger, [0, 16], [0, 1], { ...CLAMP, easing: OUT });
        return (
          <div key={i} style={{ overflow: "hidden", paddingTop: size * 0.12, paddingBottom: size * 0.12 }}>
            <div
              style={{
                fontFamily: font,
                fontSize: size,
                lineHeight: 1.05,
                color,
                letterSpacing: font === IMPACT ? 3 : 1,
                textTransform: font === IMPACT ? "uppercase" : "none",
                translate: `0 ${(1 - t) * 120}%`,
                rotate: `${(1 - t) * 6}deg`,
                WebkitTextStroke: stroke ? `3px ${stroke}` : undefined,
                textShadow: glow ? `0 0 40px ${glow}, 0 7px 0 rgba(0,0,0,0.6)` : "0 7px 0 rgba(0,0,0,0.6)",
              }}
            >
              {word}
            </div>
          </div>
        );
      })}
    </div>
  );
};

// Texto de contorno que se rellena
const OutlineText: React.FC<{ text: string; size: number; y: number; delay?: number; color?: string }> = ({
  text,
  size,
  y,
  delay = 0,
  color = CREAM,
}) => {
  const frame = useCurrentFrame() - delay;
  const fill = interpolate(frame, [8, 22], [0, 1], CLAMP);
  const scale = interpolate(frame, [0, 14], [1.35, 1], { ...CLAMP, easing: OUT });
  const sh = shakeAt(frame - 8, 12, 12);
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
        letterSpacing: 6,
        textTransform: "uppercase",
        scale: String(scale),
        translate: `${sh.x}px ${sh.y}px`,
        opacity: interpolate(frame, [0, 4], [0, 1], CLAMP),
        color: fill > 0 ? color : "transparent",
        WebkitTextStroke: `4px ${fill > 0.99 ? "#1a0500" : GOLD}`,
        textShadow: `0 10px 0 rgba(120,10,0,${fill * 0.9}), 0 0 60px rgba(255,80,40,${fill * 0.6})`,
        paintOrder: "stroke fill",
      }}
    >
      {text}
    </div>
  );
};

// Marcas de esquina estilo HUD
const Corners: React.FC<{ color?: string; inset?: number }> = ({ color = GOLD, inset = 46 }) => {
  const frame = useCurrentFrame();
  const t = interpolate(frame, [0, 14], [0, 1], { ...CLAMP, easing: OUT });
  const len = 120 * t;
  const base: React.CSSProperties = { position: "absolute", width: len, height: len, borderColor: color, borderStyle: "solid" };
  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      <div style={{ ...base, left: inset, top: inset, borderWidth: "8px 0 0 8px" }} />
      <div style={{ ...base, right: inset, top: inset, borderWidth: "8px 8px 0 0" }} />
      <div style={{ ...base, left: inset, bottom: inset, borderWidth: "0 0 8px 8px" }} />
      <div style={{ ...base, right: inset, bottom: inset, borderWidth: "0 8px 8px 0" }} />
    </AbsoluteFill>
  );
};

// Panel de gameplay con entrada, borde y brillo
const Panel: React.FC<{
  src: string;
  trimBefore: number;
  x: number;
  y: number;
  w: number;
  h: number;
  radius?: number;
  rot?: number;
  delay?: number;
  fromX?: number;
  fromY?: number;
  border?: string;
  grade?: string;
}> = ({ src, trimBefore, x, y, w, h, radius = 46, rot = 0, delay = 0, fromX = 0, fromY = 900, border = GOLD, grade }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - delay, fps, config: { damping: 14, stiffness: 110, mass: 0.9 } });
  const drift = interpolate(frame, [0, 120], [1.04, 1.16], CLAMP);
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width: w,
        height: h,
        borderRadius: radius,
        overflow: "hidden",
        border: `10px solid ${border}`,
        boxShadow: `0 24px 0 rgba(0,0,0,0.55), 0 0 70px ${border}66`,
        translate: `${(1 - s) * fromX}px ${(1 - s) * fromY}px`,
        rotate: `${rot * s}deg`,
        scale: String(interpolate(s, [0, 1], [0.7, 1])),
        opacity: interpolate(frame - delay, [0, 4], [0, 1], CLAMP),
      }}
    >
      <Video
        src={src}
        trimBefore={trimBefore}
        premountFor={30}
        muted
        objectFit="cover"
        style={{ width: "100%", height: "100%", scale: String(drift), filter: grade ?? "none" }}
      />
    </div>
  );
};

// Video a pantalla completa con zoom y temblor
const Full: React.FC<{ src: string; trimBefore: number; grade?: string; punch?: number }> = ({
  src,
  trimBefore,
  grade,
  punch = 0.14,
}) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const zoom = interpolate(frame, [0, 9], [1 + punch, 1], { ...CLAMP, easing: OUT });
  const creep = interpolate(frame, [0, durationInFrames], [1, 1.07]);
  const sh = shakeAt(frame, 10, 10);
  return (
    <AbsoluteFill style={{ overflow: "hidden", backgroundColor: "#000" }}>
      <Video
        src={src}
        trimBefore={trimBefore}
        premountFor={30}
        muted
        objectFit="cover"
        style={{
          width: "100%",
          height: "100%",
          scale: String(zoom * creep),
          translate: `${sh.x}px ${sh.y}px`,
          filter: grade ?? "none",
        }}
      />
    </AbsoluteFill>
  );
};

const Flash: React.FC<{ color?: string; frames?: number; peak?: number }> = ({ color = "#fff", frames = 8, peak = 0.8 }) => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill
      style={{ backgroundColor: color, opacity: interpolate(frame, [0, 1, frames], [0, peak, 0], CLAMP) }}
    />
  );
};

// Barras verticales que cruzan la pantalla (transición)
const Wipe: React.FC<{ colors?: string[] }> = ({ colors = [GOLD, BLOOD, NIGHT, ORANGE, GOLD] }) => {
  const frame = useCurrentFrame();
  const n = colors.length;
  return (
    <AbsoluteFill style={{ pointerEvents: "none", flexDirection: "row" }}>
      {colors.map((c, i) => {
        const d = i * 1.5;
        const grow = interpolate(frame - d, [0, 6], [0, 1], { ...CLAMP, easing: Easing.out(Easing.cubic) });
        const shrink = interpolate(frame - d, [6, 13], [0, 1], { ...CLAMP, easing: Easing.in(Easing.cubic) });
        return (
          <div key={i} style={{ position: "relative", width: `${100 / n}%`, height: "100%" }}>
            <div
              style={{
                position: "absolute",
                left: -1,
                right: -1,
                top: 0,
                height: "100%",
                background: c,
                transformOrigin: grow < 1 ? "top" : "bottom",
                scale: `1 ${grow * (1 - shrink)}`,
              }}
            />
          </div>
        );
      })}
    </AbsoluteFill>
  );
};

// ───────────────────────── ilustraciones vectoriales ─────────────────────────

const BellSvg: React.FC<{ size: number; color?: string; dark?: string }> = ({ size, color = GOLD, dark = "#b8731a" }) => (
  <svg width={size} height={size * 1.2} viewBox="0 0 200 240">
    <defs>
      <linearGradient id="bellg" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor={color} />
        <stop offset="1" stopColor={dark} />
      </linearGradient>
    </defs>
    <circle cx="100" cy="14" r="11" fill="none" stroke={dark} strokeWidth="7" />
    <path
      d="M100 24 C62 24 46 70 46 120 C46 160 30 176 14 192 L186 192 C170 176 154 160 154 120 C154 70 138 24 100 24 Z"
      fill="url(#bellg)"
      stroke="#2a0f00"
      strokeWidth="7"
      strokeLinejoin="round"
    />
    <path d="M72 62 C60 84 58 112 60 140" stroke="#fff6" strokeWidth="9" strokeLinecap="round" fill="none" />
    <rect x="22" y="188" width="156" height="14" rx="7" fill={dark} stroke="#2a0f00" strokeWidth="6" />
    <circle cx="100" cy="216" r="15" fill={dark} stroke="#2a0f00" strokeWidth="6" />
  </svg>
);

const ZombieHead: React.FC<{ size: number; delay?: number }> = ({ size, delay = 0 }) => {
  const frame = useCurrentFrame() - delay;
  const { fps } = useVideoConfig();
  const s = spring({ frame, fps, config: { damping: 9, stiffness: 180 } });
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" style={{ scale: String(s), rotate: `${(1 - s) * -30}deg` }}>
      <rect x="8" y="8" width="84" height="84" rx="10" fill="#6dbb4d" stroke="#1d3a0e" strokeWidth="6" />
      <rect x="22" y="30" width="20" height="18" fill="#12200a" />
      <rect x="58" y="30" width="20" height="18" fill="#12200a" />
      <rect x="28" y="34" width="8" height="8" fill="#ffe14d" />
      <rect x="64" y="34" width="8" height="8" fill="#ffe14d" />
      <rect x="26" y="66" width="48" height="10" fill="#12200a" />
      <rect x="34" y="66" width="8" height="10" fill="#e8e8d0" />
      <rect x="54" y="66" width="8" height="10" fill="#e8e8d0" />
    </svg>
  );
};

const Rings: React.FC<{ at: number[]; x: number; y: number; color?: string }> = ({ at, x, y, color = GOLD }) => {
  const frame = useCurrentFrame();
  return (
    <>
      {at.map((start) =>
        [0, 8, 16].map((d, k) => {
          const t = interpolate(frame - start - d, [0, 46], [0, 1], { ...CLAMP, easing: Easing.out(Easing.cubic) });
          if (t <= 0 || t >= 1) return null;
          return (
            <div
              key={`${start}-${k}`}
              style={{
                position: "absolute",
                left: x,
                top: y,
                width: 300,
                height: 300,
                translate: "-50% -50%",
                borderRadius: 999,
                border: `${10 - k * 3}px solid ${color}`,
                scale: String(0.3 + t * 3.6),
                opacity: (1 - t) * 0.8,
              }}
            />
          );
        }),
      )}
    </>
  );
};

// ───────────────────────── escenas ─────────────────────────

// 0–10 s: el cuento, contado con gráficos
const Story: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const loop = frame % 100;
  const toll = frame >= 206 ? 206 : frame >= 106 ? 106 : 6;
  const since = frame - toll;
  const swing = 15 * Math.exp(-since / 28) * Math.sin(since * 0.55) * (frame >= 206 ? 1.6 : 1);
  const cracked = frame >= 206;
  const sh = shakeAt(frame - 206, 18, 40);
  const bellY = interpolate(frame, [0, 24], [-300, 470], { ...CLAMP, easing: Easing.bounce });
  const iris = interpolate(frame, [214, 296], [0, 1700], { ...CLAMP, easing: Easing.in(Easing.cubic) });
  void loop;
  void fps;
  return (
    <AbsoluteFill>
      <Backdrop blocks={false} from="#241036" to={NIGHT} />
      <Embers />
      <Rings at={[6, 106, 206]} x={540} y={bellY + 150} color={cracked ? BLOOD : GOLD} />
      <div
        style={{
          position: "absolute",
          left: 540,
          top: bellY,
          translate: `${sh.x - 180}px ${sh.y}px`,
          transformOrigin: "50% 0%",
          rotate: `${swing}deg`,
          filter: `drop-shadow(0 0 ${cracked ? 60 : 40}px ${cracked ? BLOOD : ORANGE})`,
        }}
      >
        <BellSvg size={360} color={cracked ? "#ff6a4d" : GOLD} dark={cracked ? "#7a1208" : "#b8731a"} />
      </div>
      {/* la horda aparece dentro de un iris que se abre desde la campana */}
      <AbsoluteFill style={{ clipPath: `circle(${iris}px at 540px 640px)` }}>
        <Full
          src={staticFile("clips/v8.mp4")}
          trimBefore={0}
          punch={0.05}
          grade="saturate(0.8) brightness(0.62) contrast(1.25) sepia(0.3) hue-rotate(-18deg)"
        />
        <AbsoluteFill style={{ background: "radial-gradient(ellipse at 50% 70%, rgba(120,0,0,0.0), rgba(60,0,0,0.6))" }} />
      </AbsoluteFill>
      <Sequence from={14} durationInFrames={88}>
        <KText words={["Durante", "siglos,", "una", "campana", "protegió", "al", "pueblo…"]} size={78} y={1060} font={SERIF} stagger={5} />
      </Sequence>
      <Sequence from={108} durationInFrames={82}>
        <KText words={["Esta", "noche,", "volvió", "a", "sonar."]} size={96} y={1090} font={SERIF} color={GOLD} stagger={6} glow={ORANGE} />
      </Sequence>
      <Sequence from={198} durationInFrames={96}>
        <KText words={["Y", "los", "muertos", "despertaron."]} size={100} y={1020} font={SERIF} color={BLOOD} stagger={6} glow={BLOOD} />
      </Sequence>
      <Sequence from={236} durationInFrames={60}>
        <div style={{ position: "absolute", left: 0, right: 0, top: 1400, display: "flex", justifyContent: "center", gap: 26 }}>
          <ZombieHead size={150} delay={0} />
          <ZombieHead size={190} delay={8} />
          <ZombieHead size={150} delay={16} />
        </div>
      </Sequence>
    </AbsoluteFill>
  );
};

// Bloque 1: golpe + título
const Hit: React.FC = () => (
  <AbsoluteFill>
    <Full src={staticFile("clips/v1.mp4")} trimBefore={20} punch={0.2} />
    <AbsoluteFill style={{ background: "linear-gradient(180deg, rgba(0,0,0,0.45), rgba(0,0,0,0) 35%, rgba(0,0,0,0) 55%, rgba(0,0,0,0.7))" }} />
    <Corners />
    <OutlineText text="Campana" size={230} y={720} />
    <OutlineText text="Maldita" size={230} y={930} delay={6} />
    <div style={{ position: "absolute", left: 90, right: 90, top: 1210 }}>
      <LineDraw />
    </div>
  </AbsoluteFill>
);

const LineDraw: React.FC = () => {
  const frame = useCurrentFrame();
  const w = interpolate(frame, [14, 40], [0, 100], { ...CLAMP, easing: OUT });
  return <div style={{ height: 10, width: `${w}%`, margin: "0 auto", background: `linear-gradient(90deg, ${GOLD}, ${BLOOD})`, borderRadius: 6 }} />;
};

// Bloque 2: panel inclinado + palabra gigante
const Flame: React.FC = () => {
  const frame = useCurrentFrame();
  const shift = interpolate(frame, [0, 64], [0, -160]);
  return (
    <AbsoluteFill>
      <Backdrop from="#3a0f0a" to={NIGHT} accent={ORANGE} />
      <div
        style={{
          position: "absolute",
          left: 0,
          top: 150,
          fontFamily: IMPACT,
          fontSize: 430,
          lineHeight: 0.9,
          color: "transparent",
          WebkitTextStroke: `4px ${GOLD}55`,
          whiteSpace: "nowrap",
          translate: `${shift}px 0`,
        }}
      >
        FUEGO FUEGO
      </div>
      <Panel src={staticFile("clips/v9.mp4")} trimBefore={40} x={150} y={330} w={780} h={1180} rot={-3} fromY={1100} border={ORANGE} />
      <Sequence from={10}>
        <Tag text="Lanzallamas" x={540} y={1430} color={ORANGE} />
      </Sequence>
    </AbsoluteFill>
  );
};

const Tag: React.FC<{ text: string; x: number; y: number; color?: string; rot?: number }> = ({
  text,
  x,
  y,
  color = GOLD,
  rot = -3,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame, fps, config: { damping: 10, stiffness: 200 } });
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        translate: "-50% 0",
        scale: String(interpolate(s, [0, 1], [0.2, 1])),
        rotate: `${rot}deg`,
        padding: "12px 38px",
        borderRadius: 16,
        background: color,
        border: "6px solid #1a0500",
        boxShadow: "0 12px 0 rgba(0,0,0,0.65)",
        fontFamily: IMPACT,
        fontSize: 86,
        letterSpacing: 5,
        color: "#1a0500",
        textTransform: "uppercase",
        whiteSpace: "nowrap",
      }}
    >
      {text}
    </div>
  );
};

// Bloque 3: tres tiras con armas
const Strips: React.FC = () => (
  <AbsoluteFill>
    <Backdrop from="#10233a" to={NIGHT} accent="#2a7fff" />
    <Panel src={staticFile("clips/v2.mp4")} trimBefore={30} x={34} y={190} w={320} h={1300} radius={36} fromY={-1400} delay={0} border="#7fd4ff" />
    <Panel src={staticFile("clips/v10.mp4")} trimBefore={20} x={380} y={190} w={320} h={1300} radius={36} fromY={1400} delay={4} border={GOLD} />
    <Panel src={staticFile("clips/v3.mp4")} trimBefore={20} x={726} y={190} w={320} h={1300} radius={36} fromY={-1400} delay={8} border="#9be29b" />
    <Sequence from={14}>
      <Label text="Fusil" x={194} y={1510} color="#7fd4ff" />
    </Sequence>
    <Sequence from={20}>
      <Label text="Minigun" x={540} y={1510} color={GOLD} />
    </Sequence>
    <Sequence from={26}>
      <Label text="Ballesta" x={886} y={1510} color="#9be29b" />
    </Sequence>
    <KText words={["Tu", "arsenal"]} size={110} y={50} stagger={6} stroke="#1a0500" glow="#2a7fff" />
  </AbsoluteFill>
);

const Label: React.FC<{ text: string; x: number; y: number; color: string }> = ({ text, x, y, color }) => {
  const frame = useCurrentFrame();
  const t = interpolate(frame, [0, 12], [0, 1], { ...CLAMP, easing: OUT });
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        translate: `-50% ${(1 - t) * 60}px`,
        opacity: t,
        fontFamily: IMPACT,
        fontSize: 56,
        letterSpacing: 3,
        color,
        textTransform: "uppercase",
        textShadow: "0 5px 0 #000",
      }}
    >
      {text}
    </div>
  );
};

// Bloque 4: tarjetas con contadores
const Stats: React.FC = () => {
  const items = [
    { n: 50, suffix: "+", label: "zombis por oleada", color: "#6dbb4d" },
    { n: 8, suffix: "", label: "armas distintas", color: GOLD },
    { n: 10, suffix: "", label: "salas de juego", color: "#7fd4ff" },
    { n: 5, suffix: "", label: "amigos en equipo", color: ORANGE },
  ];
  return (
    <AbsoluteFill>
      <Backdrop from="#2b0a14" to={NIGHT} accent={BLOOD} />
      <KText words={["Esto", "te", "espera"]} size={120} y={150} stagger={6} stroke="#1a0500" glow={BLOOD} />
      {items.map((it, i) => (
        <Sequence key={it.label} from={6 + i * 5} premountFor={30}>
          <StatCard {...it} x={60 + (i % 2) * 485} y={420 + Math.floor(i / 2) * 560} />
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};

const StatCard: React.FC<{ n: number; suffix: string; label: string; color: string; x: number; y: number }> = ({
  n,
  suffix,
  label,
  color,
  x,
  y,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame, fps, config: { damping: 12, stiffness: 160 } });
  const value = Math.round(interpolate(frame, [4, 30], [0, n], { ...CLAMP, easing: Easing.out(Easing.cubic) }));
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width: 450,
        height: 500,
        borderRadius: 50,
        background: "linear-gradient(160deg, rgba(255,255,255,0.14), rgba(255,255,255,0.04))",
        border: `8px solid ${color}`,
        boxShadow: `0 20px 0 rgba(0,0,0,0.5), 0 0 60px ${color}55`,
        scale: String(interpolate(s, [0, 1], [0.4, 1])),
        rotate: `${interpolate(s, [0, 1], [-8, 0])}deg`,
        opacity: interpolate(frame, [0, 3], [0, 1], CLAMP),
        textAlign: "center",
      }}
    >
      <div style={{ fontFamily: IMPACT, fontSize: 250, lineHeight: 1.05, color, marginTop: 60, textShadow: "0 9px 0 #000" }}>
        {value}
        {suffix}
      </div>
      <div style={{ fontFamily: IMPACT, fontSize: 52, color: CREAM, letterSpacing: 3, textTransform: "uppercase", padding: "0 20px" }}>
        {label}
      </div>
    </div>
  );
};

// Bloque 5: combo con contador
const Combo: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const count = Math.round(interpolate(frame, [4, 54], [1, 22], { ...CLAMP, easing: Easing.out(Easing.quad) }));
  const beat = spring({ frame: frame % 8, fps, config: { damping: 8, stiffness: 300 } });
  return (
    <AbsoluteFill>
      <Full src={staticFile("clips/v5.mp4")} trimBefore={60} punch={0.18} />
      <AbsoluteFill style={{ background: "linear-gradient(180deg, rgba(0,0,0,0.0) 40%, rgba(0,0,0,0.7))" }} />
      <Corners color={BLOOD} />
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: 1180,
          textAlign: "center",
          fontFamily: IMPACT,
          color: GOLD,
          textShadow: "0 12px 0 #1a0500, 0 0 60px #ff7a2b",
          WebkitTextStroke: "5px #1a0500",
          paintOrder: "stroke fill",
        }}
      >
        <div style={{ fontSize: 80, letterSpacing: 10 }}>COMBO</div>
        <div style={{ fontSize: 330, lineHeight: 0.9, scale: String(1 + (1 - beat) * 0.12) }}>x{count}</div>
      </div>
    </AbsoluteFill>
  );
};

// Bloque 6: alerta de jefe con cintas de peligro
const Boss: React.FC = () => {
  const frame = useCurrentFrame();
  const pulse = 0.18 + Math.abs(Math.sin(frame / 5)) * 0.3;
  const sh = shakeAt(frame, 14, 64);
  const stripe = (dir: number): React.CSSProperties => ({
    position: "absolute",
    left: -40,
    right: -40,
    height: 120,
    backgroundImage: `repeating-linear-gradient(-45deg, #ffd000 0 46px, #111 46px 92px)`,
    backgroundPosition: `${frame * 14 * dir}px 0`,
    border: "6px solid #111",
  });
  return (
    <AbsoluteFill>
      <Full src={staticFile("clips/v8.mp4")} trimBefore={215} punch={0.2} grade="saturate(1.2) contrast(1.15) hue-rotate(-8deg)" />
      <AbsoluteFill style={{ backgroundColor: `rgba(255,20,10,${pulse})` }} />
      <div style={{ ...stripe(1), top: 330 }} />
      <div style={{ ...stripe(-1), top: 1470 }} />
      <div style={{ translate: `${sh.x}px ${sh.y}px` }}>
        <KText words={["¡Llega"]} size={180} y={560} color={CREAM} stroke="#1a0500" glow={BLOOD} stagger={0} />
        <KText words={["el", "Segador!"]} size={165} y={780} color={BLOOD} stroke="#1a0500" glow={BLOOD} stagger={7} />
      </div>
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "flex-end", paddingBottom: 640 }}>
        <SkullBar />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const SkullBar: React.FC = () => {
  const frame = useCurrentFrame();
  const w = interpolate(frame, [10, 50], [0, 100], { ...CLAMP, easing: OUT });
  return (
    <div style={{ width: 760, height: 46, borderRadius: 24, border: "7px solid #1a0500", background: "rgba(0,0,0,0.6)", overflow: "hidden" }}>
      <div style={{ width: `${w}%`, height: "100%", background: `linear-gradient(90deg, ${BLOOD}, #ff8a5c)` }} />
    </div>
  );
};

// Bloque 7: amigos en círculos
const Friends: React.FC = () => (
  <AbsoluteFill>
    <Backdrop from="#103a2a" to={NIGHT} accent="#2ecf8b" />
    <KText words={["Con", "tus", "amigos"]} size={130} y={120} stagger={6} stroke="#1a0500" glow="#2ecf8b" />
    <CirclePanel src={staticFile("clips/v3.mp4")} trimBefore={60} cx={330} cy={760} r={290} delay={4} border="#9be29b" />
    <CirclePanel src={staticFile("clips/v4.mp4")} trimBefore={60} cx={760} cy={1160} r={290} delay={12} border={GOLD} />
    <div style={{ position: "absolute", left: 0, right: 0, top: 1580, display: "flex", justifyContent: "center", gap: 22 }}>
      {[0, 1, 2, 3, 4].map((i) => (
        <ZombieFriend key={i} delay={20 + i * 8} hue={i * 58} />
      ))}
    </div>
    <Sequence from={50} durationInFrames={80}>
      <KText words={["Hasta", "5", "jugadores"]} size={78} y={1440} stagger={5} color={GOLD} />
    </Sequence>
  </AbsoluteFill>
);

const ZombieFriend: React.FC<{ delay: number; hue: number }> = ({ delay, hue }) => {
  const frame = useCurrentFrame() - delay;
  const { fps } = useVideoConfig();
  const s = spring({ frame, fps, config: { damping: 8, stiffness: 190 } });
  return (
    <div style={{ scale: String(s), filter: `hue-rotate(${hue}deg)` }}>
      <svg width={120} height={120} viewBox="0 0 100 100">
        <rect x="8" y="8" width="84" height="84" rx="12" fill="#ffc98a" stroke="#1a0500" strokeWidth="7" />
        <rect x="8" y="8" width="84" height="26" rx="8" fill="#5a3a1a" stroke="#1a0500" strokeWidth="7" />
        <rect x="26" y="46" width="14" height="14" fill="#1a0500" />
        <rect x="60" y="46" width="14" height="14" fill="#1a0500" />
        <path d="M30 72 Q50 88 70 72" stroke="#1a0500" strokeWidth="7" fill="none" strokeLinecap="round" />
      </svg>
    </div>
  );
};

const CirclePanel: React.FC<{
  src: string;
  trimBefore: number;
  cx: number;
  cy: number;
  r: number;
  delay: number;
  border: string;
}> = ({ src, trimBefore, cx, cy, r, delay, border }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - delay, fps, config: { damping: 13, stiffness: 120 } });
  return (
    <div
      style={{
        position: "absolute",
        left: cx - r,
        top: cy - r,
        width: r * 2,
        height: r * 2,
        borderRadius: r,
        overflow: "hidden",
        border: `12px solid ${border}`,
        boxShadow: `0 20px 0 rgba(0,0,0,0.5), 0 0 70px ${border}66`,
        scale: String(interpolate(s, [0, 1], [0, 1])),
        rotate: `${interpolate(s, [0, 1], [-90, 0])}deg`,
      }}
    >
      <Video
        src={src}
        trimBefore={trimBefore}
        premountFor={30}
        muted
        objectFit="cover"
        style={{ width: "100%", height: "100%", scale: String(interpolate(frame, [0, 120], [1.15, 1.3], CLAMP)) }}
      />
    </div>
  );
};

// Bloque 8: clímax y pregunta
const Climax: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill>
      <Full src={staticFile("clips/v8.mp4")} trimBefore={150} punch={0.22} grade="saturate(1.15) contrast(1.12)" />
      <Sequence from={74}>
        <Full src={staticFile("clips/v6.mp4")} trimBefore={90} punch={0.24} grade="saturate(1.2) contrast(1.1)" />
      </Sequence>
      <AbsoluteFill style={{ background: "radial-gradient(ellipse at center, rgba(0,0,0,0) 40%, rgba(20,0,0,0.75))" }} />
      <Corners color={GOLD} />
      <Sequence from={22} durationInFrames={122}>
        <KText words={["¿Resistirás"]} size={170} y={640} stagger={0} color={GOLD} stroke="#1a0500" glow={ORANGE} />
        <KText words={["la", "noche?"]} size={185} y={830} stagger={8} color={CREAM} stroke="#1a0500" glow={BLOOD} />
      </Sequence>
      <TimerRing frame={frame} />
    </AbsoluteFill>
  );
};

const TimerRing: React.FC<{ frame: number }> = ({ frame }) => {
  const p = interpolate(frame, [30, 140], [0, 1], CLAMP);
  const r = 70;
  const c = 2 * Math.PI * r;
  return (
    <svg width={190} height={190} viewBox="0 0 190 190" style={{ position: "absolute", left: 445, top: 1330, opacity: interpolate(frame, [26, 36], [0, 1], CLAMP) }}>
      <circle cx="95" cy="95" r={r} fill="rgba(0,0,0,0.5)" stroke="#fff3" strokeWidth="14" />
      <circle
        cx="95"
        cy="95"
        r={r}
        fill="none"
        stroke={BLOOD}
        strokeWidth="14"
        strokeLinecap="round"
        strokeDasharray={c}
        strokeDashoffset={c * (1 - p)}
        transform="rotate(-90 95 95)"
      />
      <text x="95" y="118" textAnchor="middle" fontFamily={IMPACT} fontSize="70" fill={CREAM}>
        {Math.max(0, Math.ceil(5 - p * 5))}
      </text>
    </svg>
  );
};

// Cierre
const End: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const logo = spring({ frame: frame - 4, fps, config: { damping: 10, stiffness: 110 } });
  const cta = spring({ frame: frame - 50, fps, config: { damping: 9, stiffness: 150 } });
  const shine = interpolate((frame - 70) % 60, [0, 30], [-300, 900], CLAMP);
  const glow = 0.5 + Math.sin(frame / 9) * 0.25;
  const burst = interpolate(frame, [0, 24], [0, 1], { ...CLAMP, easing: Easing.out(Easing.cubic) });
  return (
    <AbsoluteFill>
      <Backdrop from="#4a0f0a" to="#050005" accent={GOLD} />
      <Embers count={26} tint="#ff7a2b" />
      {new Array(14).fill(0).map((_, i) => {
        const a = (i / 14) * Math.PI * 2;
        const d = burst * (420 + random(`b${i}`) * 260);
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: 540 + Math.cos(a) * d,
              top: 400 + Math.sin(a) * d,
              width: 22,
              height: 22,
              rotate: `${i * 30}deg`,
              background: i % 2 ? GOLD : BLOOD,
              opacity: 1 - burst,
            }}
          />
        );
      })}
      <div
        style={{
          position: "absolute",
          left: 310,
          top: 170,
          width: 460,
          height: 460,
          scale: String(interpolate(logo, [0, 1], [0.1, 1]) * (1 + Math.sin(frame / 7) * 0.025)),
          rotate: `${interpolate(logo, [0, 1], [-25, 0])}deg`,
        }}
      >
        <Img
          src={staticFile("icono.png")}
          style={{
            width: 460,
            height: 460,
            borderRadius: 84,
            border: "8px solid #1a0500",
            boxShadow: `0 0 ${90 * glow + 30}px rgba(255,120,40,${glow})`,
          }}
        />
      </div>
      <Sequence from={14}>
        <KText words={["Campana", "Maldita"]} size={175} y={690} stagger={8} stroke="#1a0500" glow={BLOOD} />
      </Sequence>
      <Sequence from={34}>
        <KText words={["Zombis", "·", "Cooperativo", "·", "Roblox"]} size={50} y={1230} color={GOLD} stagger={4} fadeOut={0} />
      </Sequence>
      <div style={{ position: "absolute", left: 0, right: 0, top: 1420, display: "flex", justifyContent: "center" }}>
        <div
          style={{
            position: "relative",
            overflow: "hidden",
            scale: String(interpolate(cta, [0, 1], [0.2, 1]) * (1 + Math.sin(frame / 6) * 0.02)),
            padding: "26px 60px",
            borderRadius: 28,
            background: "linear-gradient(180deg,#ffe08a,#ff9a2b)",
            border: "7px solid #1a0500",
            boxShadow: "0 14px 0 rgba(0,0,0,0.7)",
            fontFamily: IMPACT,
            fontSize: 74,
            letterSpacing: 5,
            color: "#1a0500",
            whiteSpace: "nowrap",
          }}
        >
          ▶ JUEGA GRATIS
          <div
            style={{
              position: "absolute",
              top: -40,
              bottom: -40,
              left: shine,
              width: 90,
              background: "rgba(255,255,255,0.7)",
              rotate: "20deg",
            }}
          />
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ───────────────────────── línea de tiempo ─────────────────────────

export const TrailerMotion: React.FC = () => {
  const { fps } = useVideoConfig();
  const wipes = [364, 428, 492, 556, 620, 684, 812, 960];
  return (
    <AbsoluteFill style={{ backgroundColor: "#000" }}>
      <Audio src={staticFile("music.wav")} premountFor={fps} />

      <Sequence name="1 · Cuento" from={0} durationInFrames={300} premountFor={fps}>
        <Story />
      </Sequence>
      <Sequence name="2 · Golpe y título" from={300} durationInFrames={64} premountFor={fps}>
        <Hit />
      </Sequence>
      <Sequence name="3 · Lanzallamas" from={364} durationInFrames={64} premountFor={fps}>
        <Flame />
      </Sequence>
      <Sequence name="4 · Arsenal" from={428} durationInFrames={64} premountFor={fps}>
        <Strips />
      </Sequence>
      <Sequence name="5 · Cifras" from={492} durationInFrames={64} premountFor={fps}>
        <Stats />
      </Sequence>
      <Sequence name="6 · Combo" from={556} durationInFrames={64} premountFor={fps}>
        <Combo />
      </Sequence>
      <Sequence name="7 · Jefe" from={620} durationInFrames={64} premountFor={fps}>
        <Boss />
      </Sequence>
      <Sequence name="8 · Amigos" from={684} durationInFrames={128} premountFor={fps}>
        <Friends />
      </Sequence>
      <Sequence name="9 · Clímax" from={812} durationInFrames={148} premountFor={fps}>
        <Climax />
      </Sequence>
      <Sequence name="10 · Cierre" from={960} durationInFrames={120} premountFor={fps}>
        <End />
      </Sequence>

      <Sequence name="Flash · golpe" from={300} durationInFrames={14}>
        <Flash peak={1} frames={14} />
      </Sequence>
      <Sequence name="Flash · campana" from={0} durationInFrames={10}>
        <Flash color="#ffe9b0" peak={0.5} frames={10} />
      </Sequence>
      <Sequence name="Flash · repique" from={206} durationInFrames={12}>
        <Flash color={BLOOD} peak={0.7} frames={12} />
      </Sequence>
      {wipes.map((f, i) => (
        <Sequence key={f} name={`Transición ${i + 1}`} from={f - 6} durationInFrames={14}>
          <Wipe colors={i % 2 ? [BLOOD, GOLD, NIGHT, GOLD, BLOOD] : [GOLD, NIGHT, BLOOD, NIGHT, GOLD]} />
        </Sequence>
      ))}
      <Sequence name="Entrada negra" from={0} durationInFrames={14}>
        <FadeIn />
      </Sequence>
    </AbsoluteFill>
  );
};

const FadeIn: React.FC = () => {
  const frame = useCurrentFrame();
  return <AbsoluteFill style={{ backgroundColor: "#000", opacity: interpolate(frame, [0, 13], [1, 0], CLAMP) }} />;
};
