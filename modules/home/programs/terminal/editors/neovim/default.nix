{
  config,
  lib,
  root,
  system,
  inputs,
  pkgs,
  khanelinix-lib,
  osConfig,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (khanelinix-lib) mkBoolOpt;
  inherit (inputs) khanelivim;

  cfg = config.khanelinix.programs.terminal.editors.neovim;
in
{
  options.khanelinix.programs.terminal.editors.neovim = {
    enable = mkEnableOption "neovim";
    default = mkBoolOpt true "Whether to set Neovim as the session EDITOR";
  };

  config = mkIf cfg.enable {
    home = {
      # file = mkIf pkgs.stdenv.isDarwin { "Library/Preferences/glow/glow.yml".text = config; };

      sessionVariables = {
        EDITOR = mkIf cfg.default "nvim";
      };
      packages = [
        (khanelivim.packages.${system}.default.extend {
          # FIXME: insane memory usage
          # plugins.lsp.servers.nixd.settings =
          #   let
          #     flake = ''(builtins.getFlake "${inputs.self}")'';
          #   in
          #   {
          #     options = rec {
          #       nix-darwin.expr = ''${flake}.darwinConfigurations.khanelimac.options'';
          #       nixos.expr = ''${flake}.nixosConfigurations.khanelinix.options'';
          #       home-manager.expr = ''${nixos.expr}.home-manager.users.type.getSubOptions [ ]'';
          #     };
          #   };
        })
        pkgs.nvrh
      ];
    };

    sops.secrets = lib.mkIf osConfig.khanelinix.security.sops.enable {
      wakatime = {
        sopsFile = root + "/secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.wakatime.cfg";
      };
    };

    # xdg.configFile = mkIf pkgs.stdenv.isLinux { "glow/glow.yml".text = config; };
  };
}
