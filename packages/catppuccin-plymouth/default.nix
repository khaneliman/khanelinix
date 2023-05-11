{ lib
, stdenvNoCC
, fetchFromGitHub
,
}:
stdenvNoCC.mkDerivation {
  pname = "catppuccin-plymouth";
  version = "unstable-2023-4-27";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "plymouth";
    rev = "d4105cf336599653783c34c4a2d6ca8c93f9281c";
    hash = "sha256-quBSH8hx3gD7y1JNWAKQdTk3CmO4t1kVo4cOGbeWlNE=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/plymouth"
    sed -i 's/ImageDir=\/usr\/share/ImageDir=\/etc/' themes/catppuccin-frappe/catppuccin-frappe.plymouth
    sed -i 's/ImageDir=\/usr\/share/ImageDir=\/etc/' themes/catppuccin-latte/catppuccin-latte.plymouth
    sed -i 's/ImageDir=\/usr\/share/ImageDir=\/etc/' themes/catppuccin-macchiato/catppuccin-macchiato.plymouth
    sed -i 's/ImageDir=\/usr\/share/ImageDir=\/etc/' themes/catppuccin-mocha/catppuccin-mocha.plymouth
    cp -r themes/ "$out/share/plymouth/"
    runHook postInstall
  '';

  meta = {
    description = "Soothing pastel theme for Plymouth";
    homepage = "https://github.com/catppuccin/plymouth";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ fufexan khaneliman ];
    platforms = lib.platforms.linux;
  };
}
