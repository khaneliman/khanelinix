# Focused owner renders; nixpkgs and Home Manager must be the effective locked inputs.
{
  nixpkgs,
  homeManager,
  dataHome,
  root ? ../.,
}:
let
  pkgs = import nixpkgs { system = builtins.currentSystem; };
  lib = pkgs.lib.extend (
    _: prev: {
      khanelinix = import (root + "/lib/module") { inputs.nixpkgs.lib = prev; };
    }
  );
  terminal = root + "/modules/home/programs/terminal";
  aliasFixture = {
    probe = "head -n 1";
    leading = "  head -n 1";
    argument = "printf '%s' head";
    complex = "printf one && printf two";
    literal = ''printf '%s\n' '$1 ; && || | > `word`' '';
    pipeline = ''printf '%s\n' "one" "two words" | grep -F'';
    redirect = ''printf '%s\n' > "$REDIRECT_FILE"'';
    sequence = ''printf '%s\n' one; printf '%s\n' two'';
    positional = ''printf '%s\n' "${"$"}{1}" "$@"'';
    assignment = ''alias_env="two words" printenv alias_env'';
    backticks = ''printf '%s\n' "`printf computed`"'';
    nativeOverride = "printf one && printf two";
  };
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
    };
  };
  zellij = import (terminal + "/tools/zellij") { inherit config lib pkgs; };
  compat = import (terminal + "/shells/alias-compat.nix") { inherit lib pkgs; };
  development = import (root + "/modules/home/suites/development") {
    inherit config lib pkgs;
  };
  shells = import (homeManager + "/modules") {
    inherit lib pkgs;
    configuration = {
      imports = [
        (terminal + "/shells/bash")
        (terminal + "/shells/fish")
        (terminal + "/shells/nushell")
        (terminal + "/shells/zsh")
        (terminal + "/tools/eza")
        ({ lib, ... }: {
          options.khanelinix.programs.terminal.tools.atuin.enable = lib.mkEnableOption "Atuin";
        })
      ];
      home = {
        username = "fixture";
        homeDirectory = dirOf dataHome;
        stateVersion = "26.05";
        shellAliases = aliasFixture // {
          inherit (development.config.content.home.shellAliases)
            lua-update-all
            npr-beast
            nras
            vim-update-all
            ;
        };
      };
      xdg.configHome = "${dirOf dataHome}/config space's";
      khanelinix.programs.terminal = {
        shells =
          lib.genAttrs
            [
              "bash"
              "fish"
              "nushell"
              "zsh"
            ]
            (_: {
              enable = true;
            });
        tools.eza.enable = true;
      };
      programs =
        lib.genAttrs
          [
            "bash"
            "fish"
            "nushell"
            "zsh"
          ]
          (
            name:
            {
              shellAliases.nativeOnly = "printf ${name}";
              shellAliases.nativeOverride = lib.mkForce "printf native";
            }
            // lib.optionalAttrs (name == "fish") {
              generateCompletions = false;
            }
          );
    };
  };
  abbrs =
    (shells.extendModules {
      modules = [
        {
          programs.fish.preferAbbrs = true;
          home.shellAliases.la = "printf user-la";
        }
      ];
    }).config.programs.fish;
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
  deploy = (import (root + "/flake/apps.nix") { }).perSystem {
    lib = lib // {
      getExe = app: app.text;
    };
    pkgs = pkgs // {
      writeShellApplication = app: app;
    };
  };
  data = import ./terminal-data-regressions.nix {
    inherit
      nixpkgs
      homeManager
      root
      dataHome
      ;
  };
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
    pkgs.zsh
    pkgs.coreutils
    pkgs.gawk
    pkgs.gnugrep
    launcher
    compilerHelper
  ];
  # SessionEnd is already a real derivation in the shared data-hook fixture.
  sessionDrv = builtins.head (builtins.attrNames (builtins.getContext data.rendered.sessionEnd));
  rendered = {
    inherit environment;
    deploy = deploy.apps.deploy.program;
    sessionEnd = data.rendered.sessionEnd;
    zellijAliases = zellij.config.content.home.shellAliases;
    zellijFishFunctions = compat.translateFishFunctions zellij.config.content.home.shellAliases;
    fishSubstitutions = compat.translateFishFunctions {
      quoted = ''printf '%s\n' "$(printf 'one two')"'';
      unquoted = ''printf '%s\n' $(printf 'one\ntwo\n')'';
      assignment = ''
        value=$(printf 'one two')
        printf '%s\n' "$value"
      '';
      loop = ''
        for value in $(printf 'one\ntwo\n'); do
          printf '%s\n' "$value"
        done
      '';
      awk = ''printf '%s\n' "$(printf 'one two' | ${lib.getExe pkgs.gawk} '{print $2}')"'';
      positional = ''printf '%s\n' "$1" "$(printf 'computed')" "$@"'';
      chained = ''printf 'one\n' && printf '%s\n' "$(printf 'two three')" || false'';
    };
    nuAliases = shells.config.programs.nushell.shellAliases;
    bashAliases = shells.config.programs.bash.shellAliases;
    zshAliases = shells.config.programs.zsh.shellAliases;
    fishAliases = shells.config.programs.fish.shellAliases;
    fishFunctions = shells.config.programs.fish.functions;
    fishAbbrs = abbrs.shellAbbrs;
    fishAbbrFunctions = abbrs.functions;
    fishInteractiveInit = shells.config.programs.fish.interactiveShellInit;
    zshCompletionInit = shells.config.programs.zsh.completionInit;
    complexAliases = lib.mapAttrs (_: compat.isComplexAlias) aliasFixture;
    fish = lib.getExe pkgs.fish;
    nu = lib.getExe pkgs.nushell;
    bash = lib.getExe pkgs.bash;
    zsh = lib.getExe pkgs.zsh;
    coreutils = "${pkgs.coreutils}/bin";
    grep = "${pkgs.gnugrep}/bin";
    compilerHelper = lib.getExe compilerHelper;
    groups = {
      main = groups (root + "/templates/snowfall/modules/nixos/system/networking");
      manager = groups (root + "/templates/snowfall/modules/nixos/system/networking/networkmanager");
    };
  };
}
