{
  config,
  inputs,
  lib,

  osConfig ? { },
  pkgs,
  system,
  ...
}:
let
  inherit (lib.khanelinix) mkBoolOpt;
  inherit (lib) mkOption types;

  cfg = config.khanelinix.programs.terminal.editors.neovim;

  khanelivimConfiguration = inputs.khanelivim.nixvimConfigurations.${system}.khanelivim;
  khanelivimConfigurationExtended = khanelivimConfiguration.extendModules {
    modules = [
      {
        config = lib.mkMerge [
          {
            # NOTE: Conflicting package definitions, use the package from this flake.
            dependencies.yazi.enable = false;
          }
          (lib.mkIf (config.programs.claude-code.enable or false) {
            # Use wrapped version of the package
            dependencies.claude-code.package = config.programs.claude-code.finalPackage;
          })
          {
            # FIXME: insane memory usage
            # lsp.servers.nixd.settings.settings.nixd =
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
          }
        ];
      }
      (lib.mkIf (osConfig.khanelinix.archetypes.wsl.enable or false) {
        # FIXME: upstream dependency has LONG build time and transient failures
        # Usually crashes WSL
        lsp.servers.roslyn_ls = {
          enable = lib.mkForce false;
        };

        plugins = {
          yanky = {
            enable = lib.mkForce false;
            settings.ring.permanent_wrapper.__raw = ''require("yanky.wrappers").remove_carriage_return'';
          };
        };

        extraConfigLuaPost = ''
          in_wsl = os.getenv('WSL_DISTRO_NAME') ~= nil

          if in_wsl then
              vim.g.clipboard = {
                  name = 'wsl clipboard',
                  copy =  { ["+"] = { "clip.exe" },   ["*"] = { "clip.exe" } },
                  paste = { ["+"] = { "win32yank.exe -o --lf" }, ["*"] = { "win32yank.exe -o --lf" } },
                  cache_enabled = true
              }
          end
        '';
      })
    ]
    ++ cfg.extraModules;
  };
  khanelivim = khanelivimConfigurationExtended.config.build.package;
in
{
  options.khanelinix.programs.terminal.editors.neovim = {
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

    sops.secrets = lib.mkIf (osConfig.khanelinix.security.sops.enable or false) {
      wakatime = {
        sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.wakatime.cfg";
      };
    };
  };
}
