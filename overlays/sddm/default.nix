{ ... }: final: prev:
{
  # TODO: fix sddm build dependencies
  sddm = prev.sddm.overrideAttrs (oldAttrs: {
    src = prev.fetchFromGitHub {
      owner = "sddm";
      repo = "sddm";
      rev = "58a35178b75aada974088350f9b89db45f5c3800";
      sha256 = "lTfsMUnYu3E2L25FSrMDkh9gB5X2fC0a5rvpMnPph4k=";
    };
    patches = [ ];
  });
}
