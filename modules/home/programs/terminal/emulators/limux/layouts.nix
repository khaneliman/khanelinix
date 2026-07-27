{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.khanelinix) mkBoolOpt mkOpt;

  cfg = config.khanelinix.programs.terminal.emulators.limux;

  isSupported = lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.khanelinix.limux;

  tools = config.khanelinix.programs.terminal.tools;

  projectDirectory = "${config.home.homeDirectory}/khanelinix";

  # `label` is diagnostics only: Limux cannot title a scripted pane, so panes
  # keep the title it derives from the running program.
  pane = id: label: command: { inherit id label command; };

  # No `pane.resize`, and every split halves its parent, so chaining a column
  # would leave the last row at 1/2^n. Split each slot at its midpoint instead
  # and recurse: the half holding the existing pane keeps it, the other gets a
  # fresh one. Emitting a split before recursing keeps every `from` alive.
  splitColumn =
    holderId: entries:
    let
      count = lib.length entries;
      mid = (count + 1) / 2;
      top = lib.take mid entries;
      bottom = lib.drop mid entries;
      holderIndex = lib.lists.findFirstIndex (entry: entry.id == holderId) null entries;
      holderInTop = holderIndex < mid;
      spawned = if holderInTop then lib.head bottom else lib.head top;
      step = {
        inherit (spawned) id label command;
        from = holderId;
        direction = if holderInTop then "down" else "up";
      };
    in
    assert lib.assertMsg (holderIndex != null) "limux layouts: holder ${holderId} missing from column";
    lib.optionals (count > 1) (
      [ step ]
      ++ splitColumn (if holderInTop then holderId else spawned.id) top
      ++ splitColumn (if holderInTop then spawned.id else holderId) bottom
    );

  # No TERM=xterm-kitty wrapper for yazi: Limux is Ghostty-backed, so image
  # previews already work.
  toolPanes =
    lib.optional tools.lazygit.enable (pane "git" "Git" "lazygit")
    ++ lib.optional tools.jjui.enable (pane "jujutsu" "Jujutsu" "jjui")
    ++ lib.optional tools.yazi.enable (pane "files" "Files" "yazi");

  mkLayout =
    {
      cwd ? null,
      editorLabel,
    }:
    {
      inherit cwd;
      panes =
        # The editor splits first, while the initial pane still spans the full
        # width. Building the tool column first would confine it to one row.
        lib.optional config.khanelinix.programs.terminal.editors.neovim.enable {
          id = "editor";
          label = editorLabel;
          command = "nvim";
          from = "root";
          direction = "left";
        }
        # `root` is the workspace's initial surface, the one pane that cannot be
        # handed a command, so it becomes the shell.
        ++ splitColumn "root" (toolPanes ++ [ (pane "root" "Shell" null) ]);
    };

  layouts = {
    dev = mkLayout { editorLabel = "Project"; };

    # The zellij layout also had btop and musikcube tabs. A tab spanned the full
    # width; this grid's right column is 72 columns, and both refuse to draw
    # that narrow. Nothing widens it without pane.resize, so run them from the
    # shell pane instead.
    system = mkLayout {
      cwd = projectDirectory;
      editorLabel = "khanelinix";
    };
  };

  # Emitted as shell-quoted arrays rather than JSON the script parses back:
  # Limux reads no layout directory, so files on disk would be inert, and a jq
  # round-trip can fail silently at runtime rather than loudly at build time.
  paneTable =
    name: layout:
    let
      # Nix quotes the blob once, so commands keep their spaces and `&&`. The
      # command goes last because it is the only field that can be empty and
      # bash folds runs of tabs. No value may contain a tab or newline.
      row =
        step:
        lib.concatStringsSep "\t" [
          step.id
          step.from
          step.direction
          step.label
          (lib.optionalString (step.command != null) step.command)
        ];
    in
    ''
      layout_cwd[${lib.escapeShellArg name}]=${
        lib.escapeShellArg (lib.optionalString (layout.cwd != null) layout.cwd)
      }
      layout_panes[${lib.escapeShellArg name}]=${lib.escapeShellArg (lib.concatStringsSep "\n" (map row layout.panes))}
    '';

  limuxWorkspace = pkgs.writeShellApplication {
    name = "limux-workspace";
    runtimeInputs = with pkgs; [
      coreutils
      jq
    ];
    text = ''
      limux_cli="''${LIMUX_CLI:-limux}"
      layout_default=${lib.escapeShellArg cfg.layouts.default}
      declare -A layout_cwd layout_panes
      ${lib.concatStrings (lib.mapAttrsToList paneTable layouts)}
      ${builtins.readFile ./workspace.sh}
    '';
  };
in
{
  options.khanelinix.programs.terminal.emulators.limux.layouts = {
    enable = mkBoolOpt true "Whether to declare Limux workspace layouts";
    default = mkOpt (lib.types.enum (lib.attrNames layouts)) "dev" ''
      Layout built by `limux-workspace` when `--layout` is omitted.
    '';
  };

  config = lib.mkIf (cfg.enable && cfg.layouts.enable && isSupported) {
    home = {
      packages = [ limuxWorkspace ];

      # Limux binds only its built-in shortcut ids and exposes no action or
      # command surface in its config, so an alias is the only way to reach a
      # layout.
      shellAliases = {
        lx = "limux-workspace";
        lxs = "limux-workspace --layout system";
      };
    };
  };
}
