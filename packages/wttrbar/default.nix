{ lib
, fetchFromGitHub
, rustPlatform
,
}:
rustPlatform.buildRustPackage rec {
  pname = "wttrbar";
  version = "0.3.2";

  src = fetchFromGitHub {
    owner = "bjesus";
    repo = pname;
    rev = version;
    hash = "sha256-RQeRDu8x6OQAD7VYT7FwBfj8gxn1nj6hP60oCIiuAgg=";
  };

  cargoHash = "sha256-hJCEA6m/iZuSjWRbbaoJ5ryG0z5U/IWhbEvNAohFyjg=";

  meta = with lib; {
    description = "A simple but detailed weather indicator for Waybar using wttr.in.";
    homepage = "https://github.com/bjesus/wttrbar";
    license = licenses.mit;
    maintainers = [ "khaneliman" ];
  };
}
