{ lib
, options
, pkgs
, ...
}:
let
  inherit (lib) types;
  inherit (lib.internal) mkBoolOpt mkOpt;
in
{
  options.khanelinix.system.fonts = with types; {
    enable = mkBoolOpt false "Whether or not to manage fonts.";
    fonts = with pkgs;
      mkOpt (listOf package) [
        (nerdfonts.override { fonts = [ "CascadiaCode" "Monaspace" ]; })
      ] "Custom font packages to install.";
    default = mkOpt types.str "MonaspiceNe Nerd Font" "Default font name";
  };
}
