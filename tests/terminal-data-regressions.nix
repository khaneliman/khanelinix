# Render just the affected commands; no host or flake evaluation.
{
  nixpkgs,
  dataHome,
  root ? ../.,
}:
let
  pkgs = import nixpkgs { system = builtins.currentSystem; };
  lib = pkgs.lib // {
    getExe = package: package;
  };
  args = {
    inherit lib pkgs;
    config.xdg.dataHome = dataHome;
  };
  hooks = root + "/modules/home/programs/terminal/tools/claude-code/hooks";
  pre =
    (builtins.head (builtins.head (import (hooks + "/pre-compact.nix") args).PreCompact).hooks).command;
  post =
    (builtins.head (builtins.head (import (hooks + "/post-compact.nix") args).PostCompact).hooks)
    .command;
  sessionEnd =
    (builtins.head (builtins.head (import (hooks + "/session-end.nix") args).SessionEnd).hooks).command;
  commands = import (root + "/modules/home/programs/terminal/tools/lazygit/custom-commands.nix");
in
{
  scripts = [
    pre
    post
    sessionEnd
  ];
  rendered = {
    pre = "${pre}/bin/claude-pre-compact-backup";
    post = "${post}/bin/claude-post-compact-capture";
    sessionEnd = "${sessionEnd}/bin/claude-session-end-log";
    commit =
      (builtins.head (
        builtins.filter (command: command.description == "Create conventional commit") commands
      )).command;
    go = pkgs.lib.getExe pkgs.go;
    lazygitSource = toString pkgs.lazygit.src;
  };
  dependencies = [
    pkgs.go
    pkgs.lazygit.src
  ];
}
