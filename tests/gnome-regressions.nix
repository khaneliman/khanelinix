# Focused evaluation using the locked Home Manager dconf type and serializer.
{
  nixpkgs,
  homeManager,
  root ? ../.,
  gnomeModule ? root + "/modules/home/programs/graphical/desktop-environment/gnome/default.nix",
}:
let
  baseLib = import (nixpkgs + "/lib");
  lib = baseLib // {
    hm = import (homeManager + "/modules/lib") { inherit lib; };
    khanelinix = (import (root + "/lib/module") { inputs.nixpkgs.lib = baseLib; }) // {
      theme.wallpaperPath = _: "/fixture/wallpaper.png";
    };
  };
  eval =
    gnome: extras:
    let
      result = lib.evalModules {
        specialArgs = {
          inherit lib;
          pkgs.stdenv.hostPlatform.isDarwin = false;
        };
        modules = [
          gnomeModule
          (homeManager + "/modules/misc/dconf.nix")
          {
            options = {
              meta = lib.mkOption {
                type = lib.types.attrs;
                default = { };
              };
              home = lib.mkOption {
                type = lib.types.attrs;
                default = { };
              };
              xdg = lib.mkOption {
                type = lib.types.attrs;
                default = { };
              };
              khanelinix.theme = lib.mkOption {
                type = lib.types.attrsOf lib.types.anything;
                default.wallpaper = {
                  primary = "a";
                  secondary = "b";
                };
              };
              khanelinix.programs.graphical.addons.flameshot.enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
              };
            };
            config = {
              # Keep the native settings option but never generate activation.
              dconf.enable = false;
              khanelinix.programs.graphical.desktop-environment.gnome = {
                enable = true;
              }
              // gnome;
            };
          }
        ]
        ++ extras;
      };
    in
    {
      settings = lib.mapAttrs (
        _: lib.mapAttrs (_: value: toString (lib.hm.gvariant.mkValue value))
      ) result.config.dconf.settings;
      keybindings =
        result.config.khanelinix.programs.graphical.desktop-environment.gnome.desktop.wm.keybindings;
      theme = result.config.khanelinix.theme;
    };
  gtkContribution = {
    dconf.settings = lib.khanelinix.nested-default-attrs {
      "org/gnome/desktop/interface" = {
        font-name = "Fixture 12";
        cursor-size = 32;
        cursor-theme = "FixtureCursor";
        gtk-theme = "FixtureGTK";
        icon-theme = "FixtureIcons";
      };
      "org/gnome/shell".enabled-extensions = [ "user-theme@gnome-shell-extensions.gcampax.github.com" ];
    };
  };
  bruddy =
    (import (root + "/homes/x86_64-linux/bruddy@bruddynix/default.nix") {
      inherit lib;
      osConfig.khanelinix.programs.graphical.desktop-environment.gnome.enable = true;
    }).khanelinix.programs.graphical.desktop-environment.gnome;
in
{
  defaults = eval { } [ ];
  disabled = eval { enable = false; } [ ];
  toggles = lib.genList (
    n:
    eval {
      desktop.wm.keybindings = {
        enable-workspace-shortcuts = lib.mod n 2 == 1;
        enable-move-to-workspace-shortcuts = n >= 2;
      };
    } [ ]
  ) 4;
  override = eval {
    desktop.wm.keybindings = {
      move-to-workspace-1 = [ "<Super>F1" ];
      switch-to-workspace-2 = [ ];
      switch-to-application-1 = [ "<Super>F2" ];
      close = [ "<Super>q" ];
    };
  } [ ];
  explicitDisabled = eval {
    desktop.wm.keybindings = {
      enable-workspace-shortcuts = false;
      enable-move-to-workspace-shortcuts = false;
      move-to-workspace-1 = [ "<Super>F1" ];
      switch-to-workspace-2 = [ "<Super>F2" ];
    };
  } [ ];
  settingsOverride = eval {
    desktop.wm.keybindings.switch-to-application-1 = [ "<Super>F2" ];
    settings = {
      "org/gnome/desktop/wm/keybindings" = {
        move-to-workspace-1 = [ "<Super>F3" ];
        switch-to-workspace-left = [ ];
      };
      "org/gnome/shell/keybindings" = {
        switch-to-application-1 = [ "<Super>F4" ];
        toggle-overview = [ "<Super>F5" ];
      };
      "org/gnome/desktop/interface".color-scheme = "default";
    };
  } [ gtkContribution ];
  nativeOverride = eval { } [
    gtkContribution
    {
      dconf.settings = {
        "org/gnome/desktop/wm/keybindings".move-to-workspace-1 = [ "<Super>F6" ];
        "org/gnome/shell/keybindings".switch-to-application-1 = [ "<Super>F7" ];
      };
    }
  ];
  splitOverrides = eval { } [
    {
      khanelinix.programs.graphical.desktop-environment.gnome.desktop.wm.keybindings.close = [
        "<Super>q"
      ];
    }
    {
      khanelinix.programs.graphical.desktop-environment.gnome.desktop.wm.keybindings.move-to-workspace-1 =
        [ "<Super>F1" ];
    }
  ];
  counts = map (count: eval { desktop.wm.preferences.num-workspaces = count; } [ ]) [
    1
    3
    12
    13
  ];
  bruddy = eval bruddy [ gtkContribution ];
  invalidToggleAccepted =
    (builtins.tryEval (
      builtins.deepSeq (eval {
        desktop.wm.keybindings.enable-workspace-shortcuts = "false";
      } [ ]) true
    )).success;
}
