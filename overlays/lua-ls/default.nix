_: _final: prev: {
  lua-language-server = prev.lua-language-server.overrideAttrs (_oldAttrs: rec {
    version = "3.9.1";

    src = prev.fetchFromGitHub {
      owner = "luals";
      repo = "lua-language-server";
      rev = version;
      hash = "sha256-M4eTrs5Ue2+b40TPdW4LZEACGYCE/J9dQodEk9d+gpY=";
      fetchSubmodules = true;
    };
  });
}
