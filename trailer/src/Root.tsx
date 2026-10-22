import { Composition } from "remotion";
import { Trailer } from "./Composition";

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
    </>
  );
};
