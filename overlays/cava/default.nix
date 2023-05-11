{ ... }: final: prev:
{
  cava = prev.cava.overrideAttrs (oldAttrs: {
    version = "0.8.4";

    src = prev.fetchFromGitHub {
      owner = "LukashonakV";
      repo = "cava";
      rev = "0.8.4";
      hash = "sha256-66uc0CEriV9XOjSjFTt+bxghEXY1OGrpjd+7d6piJUI=";
    };
  });
}
