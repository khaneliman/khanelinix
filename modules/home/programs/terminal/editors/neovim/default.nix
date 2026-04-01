{
  config,
  inputs,
  lib,
  options,
  pkgs,
  system,

  osConfig ? { },
  ...
}:
let
  inherit (lib.khanelinix) disabled mkBoolOpt;
  inherit (lib) mkOption types;

  cfg = config.khanelinix.programs.terminal.editors.neovim;

  khanelivimConfiguration = inputs.khanelivim.nixvimConfigurations.${system}.khanelivim;

  neovimLib = import ./lib.nix { inherit lib options khanelivimConfiguration; };

  nvrEditor = pkgs.writeShellScriptBin "nvr-editor" ''
    if [ -n "$NVIM" ] || [ -n "$NVIM_LISTEN_ADDRESS" ]; then
      exec ${lib.getExe pkgs.nvrh} --remote-wait "$@"
    fi

    exec ${lib.getExe khanelivim} "$@"
  '';

  khanelivimConfigurationExtended = khanelivimConfiguration.extendModules {
    modules = [
      {
        config = lib.mkMerge [
          {
            # Avoid evaluating/building Nixvim man docs unless explicitly enabled.
            enableMan = lib.mkDefault false;

            # Automatically disable dependencies that are already in home.packages
            dependencies = lib.genAttrs neovimLib.dependenciesToDisable (_: disabled);

            plugins.tmux-navigator = {
              autoLoad = true;
              inherit (config.khanelinix.programs.terminal.tools.tmux) enable;
              settings.preserve_zoom = 1;
            };

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
      (lib.mkIf (config.khanelinix.theme.catppuccin.enable or false) {
        khanelivim.ui.theme = "catppuccin";
      })
      (lib.mkIf (config.khanelinix.theme.nord.enable or false) {
        khanelivim.ui.theme = "nord";
      })
      (lib.mkIf (config.khanelinix.theme.tokyonight.enable or false) {
        khanelivim.ui.theme = "tokyonight";
      })
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
        VISUAL = lib.mkIf cfg.default "nvr-editor";
        GIT_EDITOR = lib.mkIf cfg.default "nvr-editor";
        MANPAGER = "nvim -c 'set ft=man bt=nowrite noswapfile nobk shada=\\\"NONE\\\" ro noma' +Man! -o -";
      };
      packages = [
        khanelivim
        pkgs.nvrh
        nvrEditor
      ];
    };

    sops.secrets = lib.mkIf (config.khanelinix.services.sops.enable or false) {
      wakatime = {
        sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.wakatime.cfg";
      };
    };
  };
}
