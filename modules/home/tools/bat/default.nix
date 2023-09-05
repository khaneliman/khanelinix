{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.tools.bat;
in
{
  options.khanelinix.tools.bat = with types; {
    enable = mkBoolOpt false "Whether or not to enable bat.";
  };

  config = mkIf cfg.enable {
    programs.bat = {
      enable = true;

      config = {
        theme = "catppuccin-macchiato";
        style = "auto,header-filesize";
      };

      extraPackages = with pkgs.bat-extras; [
        prettybat
        batwatch
        batpipe
        batman
        batgrep
        batdiff
      ];

      themes = {
        catppuccin-macchiato = builtins.readFile (pkgs.fetchFromGitHub
          {
            owner = "catppuccin";
            repo = "bat";
            rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
            hash = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
          }
        + "/Catppuccin-macchiato.tmTheme");
      };
    };

    home.shellAliases = {
      cat = "bat";
    };
  };
}
