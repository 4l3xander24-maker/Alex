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

const IMPACT = "TrailerImpact";
const SERIF = "TrailerGeorgia";
loadFont({ family: IMPACT, url: staticFile("fonts/Impact.ttf") });
loadFont({ family: SERIF, url: staticFile("fonts/GeorgiaBold.ttf"), weight: "700" });

const GOLD = "#ffd36b";
const BLOOD = "#ff3b2f";
const CREAM = "#fff1d6";

// ───────────────────────── helpers de movimiento ─────────────────────────

const useShake = (power: number, startFrame = 0, length = 14) => {
  const frame = useCurrentFrame();
  const local = frame - startFrame;
  const decay = local < 0 || local > length ? 0 : 1 - local / length;
  const x = Math.sin(local * 12.9898) * 43758.5453;
  const y = Math.sin(local * 78.233) * 12345.678;
  return {
    x: (x - Math.floor(x) - 0.5) * 2 * power * decay,
    y: (y - Math.floor(y) - 0.5) * 2 * power * decay,
  };
};

// Un plano de gameplay con "punch" de zoom al entrar, temblor y gradación
const Shot: React.FC<{
  src: string;
  trimBefore: number;
  grade?: string;
  punch?: number;
  drift?: number;
  slow?: boolean;
}> = ({ src, trimBefore, grade, punch = 0.12, drift = 0.06, slow }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();
  const zoom = interpolate(frame, [0, 9], [1 + punch, 1], {
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.16, 1, 0.3, 1),
  });
  const creep = interpolate(frame, [0, durationInFrames], [1, 1 + drift]);
  const shake = useShake(10, 0, 10);
  return (
    <AbsoluteFill style={{ overflow: "hidden", backgroundColor: "#000" }}>
      <Video
        src={src}
        trimBefore={trimBefore}
        playbackRate={slow ? 0.6 : 1}
        premountFor={fps}
        muted
        objectFit="cover"
        style={{
          width: "100%",
          height: "100%",
          scale: String(zoom * creep),
          translate: `${shake.x}px ${shake.y}px`,
          filter: grade ?? "none",
        }}
      />
    </AbsoluteFill>
  );
};

const Flash: React.FC<{ color?: string; frames?: number; peak?: number }> = ({
  color = "#fff",
  frames = 8,
  peak = 0.85,
}) => {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [0, 1, frames], [0, peak, 0], {
    extrapolateRight: "clamp",
    extrapolateLeft: "clamp",
  });
  return <AbsoluteFill style={{ backgroundColor: color, opacity }} />;
};

const Vignette: React.FC<{ strength?: number }> = ({ strength = 0.75 }) => (
  <AbsoluteFill
    style={{
      background: `radial-gradient(ellipse at center, rgba(0,0,0,0) 45%, rgba(0,0,0,${strength}) 100%)`,
    }}
  />
);

// Brasas que suben (determinista, sin CSS animation)
const Embers: React.FC<{ count?: number; tint?: string }> = ({
  count = 34,
  tint = "#ff9a3c",
}) => {
  const frame = useCurrentFrame();
  const { height } = useVideoConfig();
  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      {new Array(count).fill(0).map((_, i) => {
        const speed = 0.5 + random(`s${i}`) * 1.6;
        const startX = random(`x${i}`) * 1080;
        const size = 3 + random(`z${i}`) * 7;
        const y = height - ((frame * speed * 3 + random(`y${i}`) * height) % (height + 80)) + 40;
        const x = startX + Math.sin(frame / 20 + i) * 30;
        const opacity = interpolate(y, [0, height * 0.25, height], [0, 0.9, 0.2]);
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
              opacity,
            }}
          />
        );
      })}
    </AbsoluteFill>
  );
};

// ───────────────────────── textos ─────────────────────────

// Cuento: aparece con fundido, sube un poco y se apaga
const StoryLine: React.FC<{
  children: string;
  color?: string;
  size?: number;
  y?: number;
}> = ({ children, color = CREAM, size = 70, y = 880 }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const opacity = interpolate(frame, [0, 18, durationInFrames - 14, durationInFrames], [0, 1, 1, 0], {
    extrapolateRight: "clamp",
  });
  const rise = interpolate(frame, [0, 30], [26, 0], {
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.16, 1, 0.3, 1),
  });
  const blur = interpolate(frame, [0, 14], [12, 0], { extrapolateRight: "clamp" });
  return (
    <div
      style={{
        position: "absolute",
        left: 70,
        right: 70,
        top: y,
        textAlign: "center",
        fontFamily: SERIF,
        fontWeight: 700,
        fontSize: size,
        lineHeight: 1.18,
        color,
        letterSpacing: 2,
        opacity,
        translate: `0 ${rise}px`,
        filter: `blur(${blur}px)`,
        textShadow: "0 6px 30px rgba(0,0,0,0.9), 0 0 40px rgba(255,160,60,0.25)",
      }}
    >
      {children}
    </div>
  );
};

// Título tipo "slam": cada palabra cae con rebote y un temblor
const Slam: React.FC<{
  words: string[];
  size?: number;
  y?: number;
  color?: string;
  stagger?: number;
  hold?: number;
}> = ({ words, size = 190, y = 780, color = CREAM, stagger = 7, hold = 60 }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();
  const out = interpolate(frame, [durationInFrames - 8, durationInFrames], [1, 0], {
    extrapolateLeft: "clamp",
  });
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        top: y,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        opacity: out,
      }}
    >
      {words.map((word, i) => {
        const f = frame - i * stagger;
        const s = spring({ frame: f, fps, config: { damping: 9, stiffness: 200, mass: 0.7 } });
        const shake = useShake(14, i * stagger, 12);
        return (
          <div
            key={word + i}
            style={{
              fontFamily: IMPACT,
              fontSize: size,
              lineHeight: 1,
              color,
              letterSpacing: 4,
              textTransform: "uppercase",
              scale: String(interpolate(s, [0, 1], [2.6, 1])),
              opacity: interpolate(f, [0, 4], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }),
              translate: `${shake.x}px ${shake.y}px`,
              textShadow: `0 8px 0 rgba(120,10,0,0.85), 0 0 50px ${BLOOD}99`,
              WebkitTextStroke: "3px rgba(40,0,0,0.9)",
              filter: f < 3 ? "blur(8px)" : "none",
            }}
          >
            {word}
          </div>
        );
      })}
      <div style={{ height: hold * 0 }} />
    </div>
  );
};

// Subtítulo con barrido de luz y cinta dorada
const Banner: React.FC<{ children: string; y?: number; color?: string; size?: number }> = ({
  children,
  y = 1330,
  color = GOLD,
  size = 84,
}) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const inP = interpolate(frame, [0, 10], [0, 1], {
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.16, 1, 0.3, 1),
  });
  const out = interpolate(frame, [durationInFrames - 8, durationInFrames], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        top: y,
        display: "flex",
        justifyContent: "center",
        opacity: out,
      }}
    >
      <div
        style={{
          padding: "18px 44px",
          background: "linear-gradient(90deg, rgba(10,0,0,0), rgba(10,0,0,0.82) 18%, rgba(10,0,0,0.82) 82%, rgba(10,0,0,0))",
          clipPath: `inset(0 ${(1 - inP) * 50}% 0 ${(1 - inP) * 50}%)`,
        }}
      >
        <div
          style={{
            fontFamily: IMPACT,
            fontSize: size,
            color,
            letterSpacing: 5,
            textTransform: "uppercase",
            textShadow: "0 5px 0 rgba(0,0,0,0.9), 0 0 30px rgba(255,170,60,0.55)",
            whiteSpace: "nowrap",
          }}
        >
          {children}
        </div>
      </div>
    </div>
  );
};

// Etiquetas de armas que saltan una tras otra
const WeaponChip: React.FC<{ label: string; x: number; y: number; hue: string }> = ({ label, x, y, hue }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();
  const s = spring({ frame, fps, config: { damping: 11, stiffness: 220 } });
  const out = interpolate(frame, [durationInFrames - 6, durationInFrames], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        translate: "-50% 0",
        scale: String(interpolate(s, [0, 1], [0.2, 1])),
        rotate: `${interpolate(s, [0, 1], [-12, -3])}deg`,
        opacity: out,
        padding: "14px 34px",
        borderRadius: 14,
        background: hue,
        border: "5px solid #1a0500",
        boxShadow: "0 10px 0 rgba(0,0,0,0.6)",
        fontFamily: IMPACT,
        fontSize: 78,
        letterSpacing: 4,
        color: "#1a0500",
        textTransform: "uppercase",
        whiteSpace: "nowrap",
      }}
    >
      {label}
    </div>
  );
};

// ───────────────────────── tráiler ─────────────────────────

export const Trailer: React.FC = () => {
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();
  // Cinta negra que se abre durante el cuento
  const bars = interpolate(frame, [0, 20, 270, 300], [260, 150, 150, 0], {
    extrapolateRight: "clamp",
    extrapolateLeft: "clamp",
    easing: Easing.bezier(0.4, 0, 0.2, 1),
  });
  const dim = interpolate(frame, [0, 300], [0.55, 0.25]);

  return (
    <AbsoluteFill style={{ backgroundColor: "#000" }}>
      <Audio src={staticFile("music.wav")} premountFor={fps} />

      {/* ───── 1. El cuento (0–10 s) ───── */}
      <Sequence name="Cuento · campana" from={0} durationInFrames={150} premountFor={fps}>
        <Shot
          src={staticFile("clips/v6.mp4")}
          trimBefore={0}
          punch={0.04}
          drift={0.1}
          grade="saturate(0.55) brightness(0.62) contrast(1.2) sepia(0.25) hue-rotate(-12deg)"
        />
      </Sequence>
      <Sequence name="Cuento · horda" from={150} durationInFrames={150} premountFor={fps}>
        <Shot
          src={staticFile("clips/v8.mp4")}
          trimBefore={0}
          punch={0.06}
          drift={0.1}
          grade="saturate(0.75) brightness(0.7) contrast(1.25) sepia(0.35) hue-rotate(-18deg)"
        />
      </Sequence>
      <Sequence name="Brasas" from={0} durationInFrames={300} premountFor={fps}>
        <Embers />
      </Sequence>
      <Sequence name="Cuento · oscurecer" from={0} durationInFrames={300}>
        <AbsoluteFill style={{ backgroundColor: `rgba(5,0,10,${dim})` }} />
      </Sequence>

      <Sequence name="Cuento 1" from={14} durationInFrames={86} premountFor={fps}>
        <StoryLine>Durante siglos, una campana protegió al pueblo…</StoryLine>
      </Sequence>
      <Sequence name="Cuento 2" from={106} durationInFrames={80} premountFor={fps}>
        <StoryLine>Esta noche, volvió a sonar.</StoryLine>
      </Sequence>
      <Sequence name="Cuento 3" from={196} durationInFrames={92} premountFor={fps}>
        <StoryLine color={BLOOD} size={96} y={840}>
          Y los muertos despertaron.
        </StoryLine>
      </Sequence>

      {/* ───── 2. Montaje de gameplay (10–32 s) ───── */}
      <Sequence name="Gameplay 1 · combo" from={300} durationInFrames={64} premountFor={fps}>
        <Shot src={staticFile("clips/v1.mp4")} trimBefore={20} punch={0.2} />
      </Sequence>
      <Sequence name="Gameplay 2 · lanzallamas" from={364} durationInFrames={64} premountFor={fps}>
        <Shot src={staticFile("clips/v9.mp4")} trimBefore={40} punch={0.16} />
      </Sequence>
      <Sequence name="Gameplay 3 · puerta" from={428} durationInFrames={64} premountFor={fps}>
        <Shot src={staticFile("clips/v2.mp4")} trimBefore={30} punch={0.16} />
      </Sequence>
      <Sequence name="Gameplay 4 · minigun" from={492} durationInFrames={64} premountFor={fps}>
        <Shot src={staticFile("clips/v10.mp4")} trimBefore={20} punch={0.16} />
      </Sequence>
      <Sequence name="Gameplay 5 · combo x22" from={556} durationInFrames={64} premountFor={fps}>
        <Shot src={staticFile("clips/v5.mp4")} trimBefore={60} punch={0.18} />
      </Sequence>
      <Sequence name="Gameplay 6 · pistola" from={620} durationInFrames={64} premountFor={fps}>
        <Shot src={staticFile("clips/v11.mp4")} trimBefore={60} punch={0.16} />
      </Sequence>
      <Sequence name="Gameplay 7 · ballesta" from={684} durationInFrames={64} premountFor={fps}>
        <Shot src={staticFile("clips/v3.mp4")} trimBefore={20} punch={0.16} />
      </Sequence>
      <Sequence name="Gameplay 8 · camino" from={748} durationInFrames={64} premountFor={fps}>
        <Shot src={staticFile("clips/v4.mp4")} trimBefore={40} punch={0.16} />
      </Sequence>
      <Sequence name="Gameplay 9 · horda en la campana" from={812} durationInFrames={64} premountFor={fps}>
        <Shot
          src={staticFile("clips/v8.mp4")}
          trimBefore={150}
          punch={0.2}
          grade="saturate(1.15) contrast(1.12)"
        />
      </Sequence>
      <Sequence name="Gameplay 10 · campana" from={876} durationInFrames={84} premountFor={fps}>
        <Shot
          src={staticFile("clips/v6.mp4")}
          trimBefore={90}
          punch={0.2}
          drift={0.12}
          grade="saturate(1.2) contrast(1.1)"
        />
      </Sequence>

      {/* Viñeta y brillo sobre todo el montaje */}
      <Sequence name="Viñeta" from={300} durationInFrames={660}>
        <Vignette strength={0.6} />
      </Sequence>

      {/* Destellos en cada corte (al ritmo de la música) */}
      <Sequence name="Flash · golpe" from={300} durationInFrames={14} premountFor={fps}>
        <Flash peak={1} frames={14} />
      </Sequence>
      <Sequence name="Flash 1" from={364} durationInFrames={8}>
        <Flash peak={0.45} />
      </Sequence>
      <Sequence name="Flash 2" from={428} durationInFrames={8}>
        <Flash peak={0.45} />
      </Sequence>
      <Sequence name="Flash 3" from={492} durationInFrames={8}>
        <Flash peak={0.45} />
      </Sequence>
      <Sequence name="Flash 4" from={556} durationInFrames={8}>
        <Flash peak={0.45} />
      </Sequence>
      <Sequence name="Flash 5" from={620} durationInFrames={8}>
        <Flash peak={0.45} />
      </Sequence>
      <Sequence name="Flash 6" from={684} durationInFrames={8}>
        <Flash peak={0.45} />
      </Sequence>
      <Sequence name="Flash 7" from={748} durationInFrames={8}>
        <Flash peak={0.45} />
      </Sequence>
      <Sequence name="Flash 8" from={812} durationInFrames={8}>
        <Flash peak={0.55} color="#ffd9a0" />
      </Sequence>
      <Sequence name="Flash 9" from={876} durationInFrames={8}>
        <Flash peak={0.55} color="#ffd9a0" />
      </Sequence>

      {/* Textos del montaje */}
      <Sequence name="Título" from={304} durationInFrames={84} premountFor={fps}>
        <Slam words={["Campana", "Maldita"]} size={210} y={620} />
      </Sequence>
      <Sequence name="Defiende la campana" from={400} durationInFrames={80} premountFor={fps}>
        <Banner>Defiende la campana</Banner>
      </Sequence>
      <Sequence name="Arma · minigun" from={496} durationInFrames={30} premountFor={fps}>
        <WeaponChip label="Minigun" x={540} y={1180} hue="#ffd36b" />
      </Sequence>
      <Sequence name="Arma · ballesta" from={514} durationInFrames={44} premountFor={fps}>
        <WeaponChip label="Ballesta" x={540} y={1300} hue="#9be29b" />
      </Sequence>
      <Sequence name="Arma · lanzallamas" from={532} durationInFrames={48} premountFor={fps}>
        <WeaponChip label="Lanzallamas" x={540} y={1420} hue="#ff9a54" />
      </Sequence>
      <Sequence name="Jefes y hordas" from={600} durationInFrames={84} premountFor={fps}>
        <Banner color={BLOOD} size={64}>Hordas · Jefes · El Segador</Banner>
      </Sequence>
      <Sequence name="Cooperativo" from={700} durationInFrames={90} premountFor={fps}>
        <Banner size={74}>Con tus amigos · hasta 5</Banner>
      </Sequence>
      <Sequence name="Pregunta final" from={830} durationInFrames={120} premountFor={fps}>
        <Slam words={["¿Resistirás", "la noche?"]} size={150} y={720} color={GOLD} stagger={10} />
      </Sequence>

      {/* ───── 3. Cierre (32–36 s) ───── */}
      <Sequence name="Cierre" from={950} durationInFrames={130} premountFor={fps}>
        <EndCard />
      </Sequence>

      {/* Fundido de entrada */}
      <Sequence name="Entrada negra" from={0} durationInFrames={20}>
        <FadeFromBlack />
      </Sequence>

      {/* Cinta de cine durante el cuento */}
      <AbsoluteFill style={{ pointerEvents: "none" }}>
        <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: bars, backgroundColor: "#000" }} />
        <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, height: bars, backgroundColor: "#000" }} />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const FadeFromBlack: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill
      style={{
        backgroundColor: "#000",
        opacity: interpolate(frame, [0, 19], [1, 0], { extrapolateRight: "clamp" }),
      }}
    />
  );
};

const EndCard: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const bg = interpolate(frame, [0, 14], [0, 1], { extrapolateRight: "clamp" });
  const logo = spring({ frame: frame - 6, fps, config: { damping: 12, stiffness: 120 } });
  const pulse = 1 + Math.sin(frame / 7) * 0.03;
  const sub = spring({ frame: frame - 34, fps, config: { damping: 14, stiffness: 140 } });
  const cta = spring({ frame: frame - 54, fps, config: { damping: 10, stiffness: 160 } });
  const glow = 0.5 + Math.sin(frame / 9) * 0.25;
  return (
    <AbsoluteFill>
      <AbsoluteFill
        style={{
          opacity: bg,
          background: "radial-gradient(ellipse at 50% 40%, #4a0f0a 0%, #12030a 55%, #050005 100%)",
        }}
      />
      <Embers count={24} tint="#ff7a2b" />
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center" }}>
        <Img
          src={staticFile("icono.png")}
          style={{
            width: 520,
            height: 520,
            borderRadius: 90,
            marginTop: -420,
            scale: String(interpolate(logo, [0, 1], [0.2, 1]) * pulse),
            boxShadow: `0 0 ${90 * glow + 30}px rgba(255,120,40,${glow})`,
            border: "6px solid #1a0500",
          }}
        />
      </AbsoluteFill>
      <Slam words={["Campana", "Maldita"]} size={170} y={1000} stagger={9} />
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: 1400,
          textAlign: "center",
          fontFamily: IMPACT,
          fontSize: 50,
          letterSpacing: 4,
          whiteSpace: "nowrap",
          color: GOLD,
          opacity: interpolate(sub, [0, 1], [0, 1]),
          translate: `0 ${interpolate(sub, [0, 1], [30, 0])}px`,
          textShadow: "0 5px 0 #000",
        }}
      >
        COOPERATIVO · ZOMBIS · HASTA 5 JUGADORES
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, top: 1500, display: "flex", justifyContent: "center" }}>
        <div
          style={{
            scale: String(interpolate(cta, [0, 1], [0.3, 1]) * (1 + Math.sin(frame / 6) * 0.025)),
            padding: "22px 48px",
            borderRadius: 24,
            background: "linear-gradient(180deg,#ffe08a,#ff9a2b)",
            border: "6px solid #1a0500",
            boxShadow: "0 12px 0 rgba(0,0,0,0.7)",
            fontFamily: IMPACT,
            fontSize: 66,
            letterSpacing: 4,
            whiteSpace: "nowrap",
            color: "#1a0500",
          }}
        >
          ▶ JUEGA GRATIS EN ROBLOX
        </div>
      </div>
    </AbsoluteFill>
  );
};
