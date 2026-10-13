{
  source,
  repo,
  nixpkgs,
  gatewayEnabled ? false,
}:
let
  pkgs = import nixpkgs { system = builtins.currentSystem; };
  lib = pkgs.lib // {
    getFile = path: repo + "/${path}";
    khanelinix.mkOpt =
      type: default: description:
      pkgs.lib.mkOption { inherit type default description; };
  };
  config = {
    khanelinix = {
      programs.terminal = {
        tools = {
          codex.enable = true;
          opencode.enable = true;
        };
        emulators.alacritty = {
          enable = true;
          font = {
            normal = "normal";
            bold = "bold";
            italic = "italic";
            bold_italic = "bold_italic";
          };
        };
      };
      fonts = { };
      services.cliproxyapi.enable = gatewayEnabled;
    };
    services = {
      exo.enable = true;
      ollama.enable = true;
    };
    home = {
      homeDirectory = "/home/test";
      preferXdgDirectories = true;
    };
    xdg = {
      configHome = "/home/test/.config";
      cacheHome = "/home/test/.cache";
      dataHome = "/home/test/.local/share";
    };
    programs.gh.enable = false;
  };
  args = {
    inherit config lib pkgs;
    inputs = { };
    osConfig.khanelinix.services.llm.llamaSwap.enable = true;
  };
  codex = import (source + "/tools/codex") args;
  opencode = import (source + "/tools/opencode") args;
  notifier = pkgs.writeShellScriptBin "notify-send" ''
    printf '%s\n' "$@" > "$NOTIFY_LOG"
  '';
  testCodex = import (source + "/tools/codex") (
    args
    // {
      pkgs = pkgs // {
        libnotify = notifier;
      };
    }
  );
  testNotify = builtins.head testCodex.config.content.programs.codex.settings.notify;
  claudeNotify = import (source + "/tools/claude-code/notify.nix") {
    inherit config lib;
    pkgs = pkgs // {
      libnotify = notifier;
    };
  };
  subagentStop = import (source + "/tools/claude-code/hooks/subagent-stop.nix") {
    inherit claudeNotify lib pkgs;
  };
  testClaudeNotify = lib.getExe claudeNotify;
  testSubagentStop = (builtins.head (builtins.head subagentStop.SubagentStop).hooks).command;
  aliases = codex.config.content.home.shellAliases // opencode.config.content.home.shellAliases;
  compat = import (source + "/shells/alias-compat.nix") { inherit lib pkgs; };
  alacritty =
    platform:
    (import (source + "/emulators/alacritty") {
      inherit config lib;
      pkgs = pkgs // {
        stdenv.hostPlatform = {
          isLinux = platform == "linux";
          isDarwin = platform == "darwin";
        };
      };
    }).config.content.programs.alacritty.settings.window;
in
{
  inherit
    aliases
    testClaudeNotify
    testNotify
    testSubagentStop
    ;
  packages = [
    pkgs.fish
    pkgs.bash
    pkgs.git
    pkgs.perl
    pkgs.libnotify
  ];
  notifyDrvs = map (path: builtins.head (builtins.attrNames (builtins.getContext path))) (
    codex.config.content.programs.codex.settings.notify
    ++ [
      testNotify
      testClaudeNotify
      testSubagentStop
    ]
  );
  wrapped = lib.filterAttrs (_: value: lib.hasPrefix "f(){" value) aliases;
  functions = compat.translateFishFunctions aliases;
  bashAliases = compat.translateAliasMap aliases;
  gitAliases =
    (import (source + "/tools/git/shell-aliases.nix") { inherit config lib pkgs; }).shellAliases;
  commandAliases = (import (source + "/tools/git/aliases.nix")).aliases;
  git = lib.getExe pkgs.git;
  perl = lib.getExe pkgs.perl;
  inherit (import (source + "/tools/git/ignores.nix")) ignores;
  windows = {
    linux = alacritty "linux";
    darwin = alacritty "darwin";
  };
  fish = lib.getExe pkgs.fish;
  notify = codex.config.content.programs.codex.settings.notify;
  notifyExe = lib.getExe pkgs.libnotify;
}
