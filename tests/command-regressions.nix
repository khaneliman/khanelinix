# Focused owner renders; nixpkgs and Home Manager must be the effective locked inputs.
{
  nixpkgs,
  homeManager,
  dataHome,
  root ? ../.,
}:
let
  pkgs = import nixpkgs { system = builtins.currentSystem; };
  inherit (pkgs) lib;
  terminal = root + "/modules/home/programs/terminal";
  config = {
    lib.shell = import (homeManager + "/modules/lib/shell.nix") { inherit lib; };
    khanelinix.programs.terminal = {
      tools = {
        zellij = {
          enable = true;
          resurrect.enable = false;
        };
        run-as-service.enable = true;
      };
      shells.nushell.enable = true;
    };
    xdg.configHome = "/fixture/config";
    home = {
      sessionPath = [ "$HOME/space directory" ];
      sessionVariables = {
        OMIT = null;
        ENABLED = true;
        DISABLED = false;
        COUNT = 3;
        EXPAND = "$HOME/expanded";
      };
      sessionVariablesExtra = "export EXTRA=present";
      shellAliases = {
        probe = "head -n 1";
        leading = "  head -n 1";
        argument = "printf '%s' head";
        complex = "printf one && printf two";
      };
    };
  };
  zellij = import (terminal + "/tools/zellij") { inherit config lib pkgs; };
  nushell = import (terminal + "/shells/nushell") { inherit config lib pkgs; };
  compat = import (terminal + "/shells/alias-compat.nix") { inherit lib pkgs; };
  launcher =
    builtins.head
      (import (terminal + "/tools/run-as-service") {
        inherit config lib;
        pkgs = pkgs // {
          writeShellScriptBin = name: text: (pkgs.writeShellScriptBin name text) // { script = text; };
        };
      }).config.content.home.packages;
  # Observe the owning module's emitted helper, rather than rebuild its exporter.
  environment = builtins.head (
    lib.splitString " " (builtins.elemAt (lib.splitString " run-as-service " launcher.script) 1)
  );
  cShell = import (root + "/flake/dev/shells/c.nix") {
    inherit lib pkgs;
    mkShell = args: args;
  };
  compilerHelper = builtins.head (builtins.filter (p: lib.getName p == "mk") cShell.packages);
  data = import ./terminal-data-regressions.nix { inherit nixpkgs root dataHome; };
  snowfallLib = lib // {
    khanelisnow = import (root + "/templates/snowfall/lib/module") { inherit lib; };
  };
  groups =
    path:
    let
      args = {
        lib = snowfallLib;
        inherit pkgs;
        namespace = "khanelisnow";
        config.khanelisnow = {
          system.networking = {
            enable = true;
            optimizeTcp = false;
            hosts = { };
          };
          services.tailscale.enable = false;
          virtualisation = {
            podman.enable = false;
            kvm.enable = false;
          };
        };
      };
      emitted = (import path args).config;
    in
    (lib.evalModules {
      modules = [
        {
          inherit ((import (root + "/templates/snowfall/modules/nixos/user") args)) options;
          # Validate group assignments against the real user interface; the
          # template's unrelated incomplete composition is outside this check.
          config = emitted // {
            content = lib.filterAttrs (name: _: name == args.namespace) emitted.content;
          };
        }
      ];
    }).config.khanelisnow.user.extraGroups;

in
{
  packages = [
    pkgs.fish
    pkgs.nushell
    pkgs.bash
    pkgs.coreutils
    launcher
    compilerHelper
  ];
  # SessionEnd is already a real derivation in the shared data-hook fixture.
  sessionDrv = builtins.head (builtins.attrNames (builtins.getContext data.rendered.sessionEnd));
  rendered = {
    inherit environment;
    sessionEnd = data.rendered.sessionEnd;
    zellijAliases = zellij.config.content.home.shellAliases;
    nuAliases = nushell.config.content.programs.nushell.shellAliases.content;
    complexBridge = compat.translatedAliasValue config.home.shellAliases.complex;
    fish = lib.getExe pkgs.fish;
    nu = lib.getExe pkgs.nushell;
    bash = lib.getExe pkgs.bash;
    coreutils = "${pkgs.coreutils}/bin";
    compilerHelper = lib.getExe compilerHelper;
    groups = {
      main = groups (root + "/templates/snowfall/modules/nixos/system/networking");
      manager = groups (root + "/templates/snowfall/modules/nixos/system/networking/networkmanager");
    };
  };
}
