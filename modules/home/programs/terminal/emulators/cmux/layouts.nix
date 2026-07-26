{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.khanelinix) mkBoolOpt mkOpt;

  cfg = config.khanelinix.programs.terminal.emulators.cmux;

  isSupported = lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.cmux;
  jsonFormat = pkgs.formats.json { };

  layoutDirectory = "${config.xdg.configHome}/cmux/layouts";

  # `bin/cmux` is the GUI launcher; the socket CLI ships inside the bundle and is
  # only on PATH within cmux's own terminals.
  cmuxCli = "${pkgs.cmux}/Applications/cmux.app/Contents/Resources/bin/cmux";

  editors = config.khanelinix.programs.terminal.editors;
  tools = config.khanelinix.programs.terminal.tools;

  layoutTools =
    lib.optional editors.neovim.enable "nvim"
    ++ lib.optional tools.btop.enable "btop"
    ++ lib.optional tools.jjui.enable "jjui"
    ++ lib.optional tools.lazygit.enable "lazygit"
    ++ lib.optional tools.yazi.enable "yazi"
    ++ lib.optional config.khanelinix.suites.music.enable "musikcube";

  cmuxResumeTool = pkgs.writeShellApplication {
    name = "cmux-resume-tool";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      cmux_cli="''${CMUX_CLI:-${cmuxCli}}"
      allowed_tools=(${lib.escapeShellArgs layoutTools})
      ${builtins.readFile ./resume-tool.sh}
    '';
  };

  cmuxLayoutTool = pkgs.writeShellApplication {
    name = "cmux-layout-tool";
    runtimeInputs = [ cmuxResumeTool ];
    text = ''
      cmux_cli="''${CMUX_CLI:-${cmuxCli}}"
      allowed_tools=(${lib.escapeShellArgs layoutTools})
      ${builtins.readFile ./layout-tool.sh}
    '';
  };

  musicDirectory =
    if config.xdg.userDirs.enable then
      config.xdg.userDirs.music
    else
      "${config.home.homeDirectory}/Music";

  projectDirectory = "${config.home.homeDirectory}/khanelinix";

  terminal =
    name: attrs:
    {
      inherit name;
      type = "terminal";
    }
    // attrs;

  resumableTerminal =
    name: command: attrs:
    terminal name (
      {
        command = lib.escapeShellArgs [
          "cmux-layout-tool"
          command
        ];
      }
      // attrs
    );

  # cmux 0.64.x builds the first surface as the pane's initial tab, then inserts
  # every later surface directly after it, so a declared tail arrives reversed:
  # nvim/git/jj/yazi/shell lands as nvim/shell/yazi/jj/git. Upstream documents
  # array order as the tab order and has no changelog entry through 0.64.20, so
  # pre-reverse the tail here and drop this once creation appends in order.
  orderSurfaces = surfaces: lib.take 1 surfaces ++ lib.reverseList (lib.drop 1 surfaces);

  # cmux nests differently than zellij: a zellij tab is a cmux surface, so each
  # layout is one pane holding the tool tabs rather than one workspace per tool.
  toolSurfaces =
    {
      cwd ? null,
      editorName,
    }:
    let
      at = surfaceCwd: lib.optionalAttrs (surfaceCwd != null) { cwd = surfaceCwd; };
    in
    lib.optional editors.neovim.enable (
      resumableTerminal editorName "nvim" (
        {
          focus = true;
        }
        // at cwd
      )
    )
    ++ lib.optional tools.lazygit.enable (resumableTerminal "Git" "lazygit" (at cwd))
    ++ lib.optional tools.jjui.enable (resumableTerminal "Jujutsu" "jjui" (at cwd))
    ++ lib.optional tools.yazi.enable (resumableTerminal "Files" "yazi" (at cwd))
    ++ [ (terminal "Shell" (at cwd)) ];

  layouts = {
    dev = {
      title = "Dev";
      icon = "hammer.fill";
      shortcut = [
        "cmd+opt+w"
        "d"
      ];
      restart = "new";
      workspace = {
        name = "Dev";
        cwd = ".";
        layout.pane.surfaces = orderSurfaces (toolSurfaces {
          editorName = "Project";
        });
      };
    };

    system = {
      title = "System";
      icon = "gearshape.fill";
      shortcut = [
        "cmd+opt+w"
        "s"
      ];
      restart = "ignore";
      workspace = {
        name = "khanelinix";
        cwd = projectDirectory;
        layout.pane.surfaces = orderSurfaces (
          toolSurfaces { editorName = "khanelinix"; }
          ++ lib.optional tools.btop.enable (
            resumableTerminal "Processes" "btop" {
              cwd = config.home.homeDirectory;
            }
          )
          ++ lib.optional config.khanelinix.suites.music.enable (
            resumableTerminal "Media" "musikcube" {
              cwd = musicDirectory;
            }
          )
        );
      };
    };
  };
  cmuxWorkspace = pkgs.writeShellApplication {
    name = "cmux-workspace";
    runtimeInputs = with pkgs; [ coreutils ];
    text = ''
      cmux_cli="''${CMUX_CLI:-${cmuxCli}}"
      layout_dir=${lib.escapeShellArg layoutDirectory}
      layout_default=${lib.escapeShellArg cfg.layouts.default}
      ${builtins.readFile ./workspace.sh}
    '';
  };

  pickerAvailable = tools.fzf.enable && tools.zoxide.enable;

  cmuxPick = pkgs.writeShellApplication {
    name = "cmux-pick";
    runtimeInputs = with pkgs; [
      cmuxWorkspace
      coreutils
      findutils
      fzf
      gawk
      zoxide
    ];
    text = ''
      layout_project_roots=(${lib.escapeShellArgs cfg.layouts.projectRoots})
      ${builtins.readFile ./pick.sh}
    '';
  };
in
{
  options.khanelinix.programs.terminal.emulators.cmux.layouts = {
    enable = mkBoolOpt true "Whether to declare cmux workspace layouts";
    default = mkOpt (lib.types.enum (lib.attrNames layouts)) "dev" ''
      Layout run by plain New Workspace and by `cmux-workspace` without
      `--layout`.
    '';
    projectRoots = mkOpt (lib.types.listOf lib.types.str) [
      "${config.home.homeDirectory}/khanelinix"
      "${config.home.homeDirectory}/github"
    ] "Directories whose immediate children `cmux-pick` offers alongside zoxide";
  };

  config = lib.mkIf (cfg.enable && cfg.layouts.enable && isSupported) {
    home = {
      packages = [
        cmuxLayoutTool
        cmuxResumeTool
        cmuxWorkspace
      ]
      ++ lib.optional pickerAvailable cmuxPick;

      shellAliases = {
        cx = "cmux-workspace";
        cxs = "cmux-workspace --layout system";
      }
      // lib.optionalAttrs pickerAvailable {
        cxp = "cmux-pick";
      };
    };

    khanelinix.programs.terminal.emulators.cmux.settings = {
      actions =
        lib.mapAttrs (
          _: layout:
          {
            type = "workspace";
            icon = {
              type = "symbol";
              name = layout.icon;
            };
          }
          // lib.removeAttrs layout [ "icon" ]
        ) layouts
        // lib.optionalAttrs pickerAvailable {
          pick = {
            type = "command";
            title = "Open Project Workspace";
            command = "cmux-pick";
            target = "newTabInCurrentPane";
            icon = {
              type = "symbol";
              name = "folder.badge.plus";
            };
            shortcut = [
              "cmd+opt+w"
              "p"
            ];
          };
        };

      ui.newWorkspace.action = cfg.layouts.default;
    };

    # Consumed by `cmux-workspace`; keeping the trees on disk keeps the CLI and
    # the in-app actions on one definition.
    xdg.configFile = lib.mapAttrs' (
      name: layout:
      lib.nameValuePair "cmux/layouts/${name}.json" {
        source = jsonFormat.generate "cmux-layout-${name}.json" layout.workspace.layout;
      }
    ) layouts;
  };
}
