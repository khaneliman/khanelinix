# Isolated owners and real Home Manager serializers, without host evaluation.
{
  nixpkgs,
  homeManager,
  root ? ../.,
  fixture,
  sync ? false,
  darwin ? false,
  system ? builtins.currentSystem,
  helixRecorder ? false,
  weztermWithSettings ? false,
}:
let
  pkgs = import nixpkgs {
    inherit system;
    config.allowAliases = false;
  };
  lib = pkgs.lib // {
    khanelinix = import (root + "/lib/module") { inputs.nixpkgs.lib = pkgs.lib; };
  };
  tools = root + "/modules/home/programs/terminal/tools";
  home = {
    username = "fixture";
    homeDirectory = "${fixture}/home space";
    stateVersion = "26.05";
  };
  evaluate =
    modules: configuration:
    (import (homeManager + "/modules") {
      inherit pkgs;
      lib = pkgs.lib.extend (
        _: _: {
          getFile = path: root + "/${path}";
        }
      );
      configuration = {
        inherit home;
        imports = modules;
      }
      // configuration;
    }).config;
  atuin = evaluate [ (tools + "/atuin") ] {
    khanelinix.programs.terminal.tools.atuin = {
      enable = true;
      sync.enable = sync;
    };
  };
  helix = evaluate [ (root + "/modules/home/programs/terminal/editors/helix") ] {
    khanelinix.programs.terminal.editors.helix.enable = true;
    programs.helix.languages.language-server = lib.mkIf helixRecorder {
      clangd.command = lib.mkForce "${fixture}/clangd-recorder";
      clangd-cpp.command = lib.mkForce "${fixture}/clangd-cpp-recorder";
    };
  };
  wezterm =
    evaluate
      [
        (root + "/modules/home/programs/terminal/emulators/wezterm")
        # Only font-family inputs are fixture-owned; HM owns its option types and Lua.
        ({ lib, ... }: {
          options.khanelinix.fonts = lib.mkOption {
            type = lib.types.attrs;
            default.monaspace.families = {
              kryptonVar = "Monaspace Krypton Var";
              neonVar = "Monaspace Neon Var";
              radonVar = "Monaspace Radon Var";
              xenonVar = "Monaspace Xenon Var";
            };
          };
        })
      ]
      {
        khanelinix.programs.terminal.emulators.wezterm.enable = true;
        programs.wezterm.settings = lib.optionalAttrs weztermWithSettings {
          color_scheme = "Fixture User";
          color_schemes."Fixture User" = {
            background = "#112233";
            foreground = "#aabbcc";
          };
          colors.cursor_bg = "#445566";
        };
      };
  baseline = evaluate [ ] { };
  disabled =
    evaluate
      [
        (tools + "/atuin")
        (tools + "/yazi")
      ]
      {
        khanelinix.programs.terminal.tools = {
          atuin = {
            enable = false;
            sync.enable = sync;
          };
          yazi.enable = false;
        };
      };
  # Compare all wrapper-owned output namespaces against upstream defaults.
  outputs = config: {
    atuin = config.programs.atuin;
    yazi = config.programs.yazi;
    aliases = config.home.shellAliases;
    packages = map toString config.home.packages;
    files = builtins.attrNames config.home.file;
    xdgFiles = builtins.attrNames config.xdg.configFile;
    services = builtins.attrNames config.systemd.user.services;
    agents = builtins.attrNames config.launchd.agents;
  };
  keymap = import (tools + "/yazi/keymap/manager/goto.nix") {
    inherit lib;
    config = {
      home.homeDirectory = home.homeDirectory;
      xdg = {
        configHome = "${fixture}/config space";
        dataHome = "${fixture}/data space";
        stateHome = "${fixture}/state space";
        userDirs.enable = false;
      };
      khanelinix.user = {
        name = "fixture";
        email = "fixture@example.invalid";
      };
    };
    pkgs.stdenv.hostPlatform = {
      isDarwin = darwin;
      isLinux = !darwin;
    };
  };
in
{
  packages = [
    pkgs.atuin
    pkgs.yazi-unwrapped
    pkgs.helix-unwrapped
    pkgs.clang-tools
    pkgs.coreutils
    pkgs.wezterm
  ];
  binaries = {
    atuin = lib.getExe pkgs.atuin;
    yazi = lib.getExe pkgs.yazi-unwrapped;
    helix = lib.getExe pkgs.helix-unwrapped;
    clangd = lib.getExe' pkgs.clang-tools "clangd";
    coreutils = "${pkgs.coreutils}/bin";
    wezterm = lib.getExe pkgs.wezterm;
  };
  gates =
    assert outputs disabled == outputs baseline;
    true;
  atuin = {
    settings = atuin.programs.atuin.settings;
    generated = atuin.xdg.configFile."atuin/config.toml".source;
  };
  helix = {
    settings = helix.programs.helix.settings;
    generated = helix.xdg.configFile."helix/config.toml".source;
    languages = helix.xdg.configFile."helix/languages.toml".source;
    snapshot = {
      inherit (helix.programs.helix) settings languages extraPackages;
      package = toString helix.programs.helix.package;
      wrapperArgs = helix.programs.helix.package.makeWrapperArgs;
      packages = map toString helix.home.packages;
    };
  };
  yazi = {
    inherit keymap;
    generated = (pkgs.formats.toml { }).generate "goto-keymap.toml" { mgr = keymap; };
  };
  wezterm = {
    settings = wezterm.programs.wezterm.settings;
    generated = wezterm.xdg.configFile."wezterm/wezterm.lua".source;
  };

}
