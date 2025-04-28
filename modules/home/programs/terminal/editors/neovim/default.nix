{
  config,
  inputs,
  lib,
  namespace,
  osConfig,
  pkgs,
  system,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (lib) mkOption types;

  cfg = config.${namespace}.programs.terminal.editors.neovim;

  khanelivimConfiguration = inputs.khanelivim.nixvimConfigurations.${system}.khanelivim;
  khanelivimConfigurationExtended = khanelivimConfiguration.extendModules {
    modules = [
      {
        config = {
          # NOTE: Conflicting package definitions, use the package from this flake.
          dependencies.yazi.enable = false;
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
      }
    ] ++ cfg.extraModules;
  };
  khanelivim = khanelivimConfigurationExtended.config.build.package;
in
{
  options.${namespace}.programs.terminal.editors.neovim = {
    enable = lib.mkEnableOption "neovim";
    default = mkBoolOpt true "Whether to set Neovim as the session EDITOR";
    extraModules = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      description = "Additional nixvim modules to extend the khanelivim configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      sessionVariables = {
        EDITOR = lib.mkIf cfg.default "nvim";
        MANPAGER = "nvim -c 'set ft=man bt=nowrite noswapfile nobk shada=\\\"NONE\\\" ro noma' +Man! -o -";
      };
      packages = [
        khanelivim
        pkgs.nvrh
      ];
    };

    sops.secrets = lib.mkIf osConfig.${namespace}.security.sops.enable {
      wakatime = {
        sopsFile = lib.snowfall.fs.get-file "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.wakatime.cfg";
      };
    };
  };
}
