import { Composition } from "remotion";
import { Trailer } from "./Composition";
import { TrailerMotion } from "./Motion";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="Trailer"
        component={Trailer}
        durationInFrames={1080}
        fps={30}
        width={1080}
        height={1920}
      />
      <Composition
        id="TrailerMotion"
        component={TrailerMotion}
        durationInFrames={1080}
        fps={30}
        width={1080}
        height={1920}
      />
    </>
  );
};
