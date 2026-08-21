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
  zkCfg = config.khanelinix.programs.terminal.tools.zk;
  zkNotebookPath = "${config.home.homeDirectory}/${zkCfg.notebookDirectory}";
  opencodeCommand = "opencode --model ${lib.escapeShellArg cfg.opencodeModel} --port";

  profileNames = [
    "minimal"
    "basic"
    "standard"
    "full"
    "debug"
  ];

  mkBaseKhanelivimConfiguration =
    profile:
    if profile == "standard" then
      inputs.khanelivim.nixvimConfigurations.${system}.khanelivim
    else
      inputs.khanelivim.lib.mkNixvimConfig { inherit system profile; };

  mkNeovimLib =
    profile:
    import ./lib.nix {
      inherit lib options;
      khanelivimConfiguration = mkBaseKhanelivimConfiguration profile;
    };

  mkKhanelivimModules =
    profile:
    [
      {
        config = lib.mkMerge [
          {
            # Avoid evaluating/building Nixvim man docs unless explicitly enabled.
            enableMan = lib.mkForce false;

            # Automatically disable dependencies that are already in home.packages
            dependencies = lib.genAttrs (mkNeovimLib profile).dependenciesToDisable (_: disabled);

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
      (lib.mkIf zkCfg.enable {
        lsp.servers.zk = {
          enable = true;
          config = {
            cmd = [
              (lib.getExe pkgs.zk)
              "lsp"
            ];
            filetypes = [ "markdown" ];
            root_dir.__raw = ''
              function(bufnr, on_dir)
                local notebook = ${builtins.toJSON zkNotebookPath}
                local filename = vim.api.nvim_buf_get_name(bufnr)
                if filename == notebook or filename:sub(1, #notebook + 1) == notebook .. "/" then
                  on_dir(notebook)
                end
              end
            '';
          };
        };
      })
      (lib.mkIf (cfg.opencodeModel != null) {
        plugins = {
          opencode.settings.server.__raw = lib.mkForce ''
            (function()
              local opencode_cmd = ${builtins.toJSON opencodeCommand}
              local snacks_terminal_opts = {
                win = {
                  position = "right",
                  enter = true,
                  on_win = function(win)
                    require("opencode.terminal").setup(win.win)
                  end,
                },
              }

              return {
                start = function()
                  require("snacks.terminal").open(opencode_cmd, snacks_terminal_opts)
                end,
                stop = function()
                  local terminal = require("snacks.terminal").get(opencode_cmd, snacks_terminal_opts)
                  if terminal then
                    terminal:close()
                  end
                end,
                toggle = function()
                  require("snacks.terminal").toggle(opencode_cmd, snacks_terminal_opts)
                end,
              }
            end)()
          '';
          sidekick.settings.cli.tools.opencode.cmd = lib.mkForce [
            "opencode"
            "--model"
            cfg.opencodeModel
          ];
          sidekick.settings.cli.tools.opencode_yolo.cmd = lib.mkForce [
            "opencode"
            "run"
            "--model"
            cfg.opencodeModel
            "--interactive"
            "--dangerously-skip-permissions"
          ];
        };
      })
    ]
    ++ cfg.extraModules;

  mkKhanelivimConfiguration =
    profile:
    (mkBaseKhanelivimConfiguration profile).extendModules {
      modules = mkKhanelivimModules profile;
    };

  khanelivimConfiguration = mkKhanelivimConfiguration cfg.profile;

  khanelivim = khanelivimConfiguration.config.build.package;

  mkProfileWrapper =
    profile:
    pkgs.writeShellScriptBin "nvim-${profile}" ''
      exec ${lib.getExe (mkKhanelivimConfiguration profile).config.build.package} "$@"
    '';

  profileWrappers =
    let
      profiles = lib.unique (builtins.filter (profile: profile != cfg.profile) cfg.extraProfiles);
    in
    map mkProfileWrapper profiles;
in
{
  options.khanelinix.programs.terminal.editors.neovim = {
    enable = lib.mkEnableOption "neovim";
    default = mkBoolOpt true "Whether to set Neovim as the session EDITOR";
    profile = mkOption {
      type = types.enum profileNames;
      default = "standard";
      description = "Primary khanelivim profile installed as nvim";
    };
    extraProfiles = mkOption {
      type = types.listOf (types.enum profileNames);
      default = [ ];
      description = "Additional khanelivim profiles installed as nvim-<profile> wrappers";
    };
    extraModules = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      description = "Additional nixvim modules to extend the khanelivim configuration";
    };
    opencodeModel = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Model passed to OpenCode processes started from Neovim.
        Use provider/model to select an OpenCode endpoint.
        Null inherits the OpenCode default model.
      '';
      example = "ollama/qwen3-coder:30b";
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
      packages =
        let
          nvrEditor = pkgs.writeShellScriptBin "nvr-editor" ''
            if [ -n "$NVIM" ] || [ -n "$NVIM_LISTEN_ADDRESS" ]; then
              exec ${lib.getExe pkgs.neovim-remote} --remote-wait "$@"
            fi

            exec ${lib.getExe khanelivim} "$@"
          '';
        in
        [
          khanelivim
          nvrEditor
          pkgs.neovim-remote
          pkgs.nvrh
        ]
        ++ profileWrappers;
    };

    sops.secrets = lib.mkIf (config.khanelinix.services.sops.enable or false) {
      wakatime = {
        sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.wakatime.cfg";
      };
    };
  };
}
