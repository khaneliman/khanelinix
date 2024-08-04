{
  clang,
  fetchFromGitHub,
  gcc,
  readline,
  lua,
}:
lua.stdenv.mkDerivation rec {
  pname = "SBarLua";
  version = "unstable-2024-02-28";

  name = "lua${lua.luaversion}-" + pname + "-" + version;

  src = fetchFromGitHub {
    owner = "FelixKratz";
    repo = "SbarLua";
    rev = "29395b1928835efa1b376d438216fbf39e0d0f83";
    hash = "sha256-C2tg1mypz/CdUmRJ4vloPckYfZrwHxc4v8hsEow4RZs=";
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
