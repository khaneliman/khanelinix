{ lib
, stdenv
, fetchFromGitHub
, pkg-config
, cmake
, wayland
, wayland-protocols
, hyprlang
, sdbus-cpp
, systemd
}:

stdenv.mkDerivation rec {
  pname = "hypridle";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "hyprwm";
    repo = "hypridle";
    rev = "v${version}";
    hash = "sha256-0x5R6v82nKBualYf+TxAduMsvG80EZAl7gofTIYtpf4=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    wayland
    wayland-protocols
    hyprlang
    sdbus-cpp
    systemd
  ];

  meta = with lib; {
    description = "Hyprland's idle daemon";
    homepage = "https://github.com/hyprwm/hypridle";
    license = licenses.bsd3;
    maintainers = with maintainers; [ iogamaster ];
    mainProgram = "hypridle";
    inherit (wayland.meta) platforms;
  };
}
