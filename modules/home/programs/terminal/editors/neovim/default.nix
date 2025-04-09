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

  khanelivimConfiguration = inputs.khanelivim.nixvimConfigurations.${system}.khanelivim;
  khanelivimConfigurationExtended = khanelivimConfiguration.extendModules {
    modules = [
      {
        config = {
          plugins = {
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

            # NOTE: Conflicting package definitions, use the package from this flake.
            yazi.yaziPackage = null;
          };
        };
      }
    ];

  };
  khanelivim = khanelivimConfigurationExtended.config.build.package;

  cfg = config.${namespace}.programs.terminal.editors.neovim;
in
{
  options.${namespace}.programs.terminal.editors.neovim = {
    enable = lib.mkEnableOption "neovim";
    default = mkBoolOpt true "Whether to set Neovim as the session EDITOR";
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
