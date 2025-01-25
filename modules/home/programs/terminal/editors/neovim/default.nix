{
  config,
  inputs,
  khanelinix-lib,
  lib,
  osConfig,
  pkgs,
  root,
  system,
  ...
}:
let
  inherit (khanelinix-lib) mkBoolOpt;

  khanelivimConfiguration = inputs.khanelivim.nixvimConfigurations.${system}.khanelivim;
  khanelivimConfigurationExtended = khanelivimConfiguration.extendModules {
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
  };
  khanelivim = khanelivimConfigurationExtended.config.build.package;

  cfg = config.khanelinix.programs.terminal.editors.neovim;
in
{
  options.khanelinix.programs.terminal.editors.neovim = {
    enable = lib.mkEnableOption "neovim";
    default = mkBoolOpt true "Whether to set Neovim as the session EDITOR";
  };

  config = lib.mkIf cfg.enable {
    home = {
      sessionVariables = {
        EDITOR = lib.mkIf cfg.default "nvim";
      };
      packages = [
        khanelivim
        pkgs.nvrh
      ];
    };

    sops.secrets = lib.mkIf osConfig.khanelinix.security.sops.enable {
      wakatime = {
        sopsFile = khanelinix-lib.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.wakatime.cfg";
      };
    };
  };
}
