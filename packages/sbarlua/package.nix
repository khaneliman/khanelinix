{
  clang,
  fetchFromGitHub,
  gcc,
  readline,
  lua,
}:
lua.stdenv.mkDerivation rec {
  pname = "SBarLua";
  version = "0-unstable-2024-08-12";

  name = "lua${lua.luaversion}-" + pname + "-" + version;

  src = fetchFromGitHub {
    owner = "FelixKratz";
    repo = "SbarLua";
    rev = "437bd2031da38ccda75827cb7548e7baa4aa9978";
    hash = "sha256-F0UfNxHM389GhiPQ6/GFbeKQq5EvpiqQdvyf7ygzkPg=";
  };

  nativeBuildInputs = [
    clang
    gcc
  ];

  buildInputs = [ readline ];

  propagatedBuildInputs = [ lua ];

  makeFlags = [
    "PREFIX=$(out)"
    "LUA_INC=-I${lua}/include"
    "LUA_LIBDIR=$(out)/lib/lua/${lua.luaversion}"
    "LUA_VERSION=${lua.luaversion}"
  ];

  installPhase = ''
    mkdir -p $out/lib/lua/${lua.luaversion}/
    cp -r bin/* "$out/lib/lua/${lua.luaversion}/"
  '';
}
