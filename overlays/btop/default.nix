_: self: super: {
  # TODO: remove once fix makes it to nixos-unstable
  btop = super.btop.overrideAttrs (oldAttrs: {
    version = "1.3.0";

    src = super.fetchFromGitHub {
      owner = "aristocratos";
      repo = "btop";
      rev = "v1.3.0";
      hash = "sha256-QQM2/LO/EHovhj+S+4x3ro/aOVrtuxteVVvYAd6feTk=";
    };

    nativeBuildInputs = with super.pkgs; [
      cmake
    ];

    env.ADDFLAGS = '''';
  });
}
