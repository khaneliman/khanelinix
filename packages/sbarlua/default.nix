{
  clang,
  fetchFromGitHub,
  gcc,
  readline,
  lua,
}:
lua.stdenv.mkDerivation rec {
  pname = "SBarLua";
  version = "unstable-2024-07-15";

  name = "lua${lua.luaversion}-" + pname + "-" + version;

  src = fetchFromGitHub {
    owner = "FelixKratz";
    repo = "SbarLua";
    rev = "19ca262c39cc45f1841155697dffd649cc119d9c";
    hash = "sha256-nz8NAeoprQ7OeFfs+7ixd6EFJyJV35WZK4mAS5izn8k=";
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
