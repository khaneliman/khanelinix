{
  config,
  lib,
  pkgs,

  ...
}:
let

  cfg = config.khanelinix.programs.terminal.tools.eza;
in
{
  options.khanelinix.programs.terminal.tools.eza = {
    enable = lib.mkEnableOption "eza";
  };

  config = lib.mkIf cfg.enable {
    programs.eza =
      lib.khanelinix.shellIntegrations config [
        "bash"
        "fish"
        "zsh"
      ]
      // {
        # Eza documentation
        # See: https://github.com/eza-community/eza
        enable = true;
        package = pkgs.eza;

        extraOptions = [
          "--group-directories-first"
          "--header"
          "--hyperlink"
          "--follow-symlinks"
        ];

        git = true;
        icons = "auto";
      };

    home.shellAliases = {
      la = lib.mkDefault "eza -lah --tree";
      tree = lib.mkDefault "eza --tree --icons=always";
    };
  };
}
