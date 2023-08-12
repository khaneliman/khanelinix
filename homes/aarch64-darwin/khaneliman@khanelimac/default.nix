{ lib
, config
, ...
}:
with lib;
with lib.internal; {
  khanelinix = {
    user = {
      enable = true;
      inherit (config.snowfallorg.user) name;
    };

    apps = {
      vscode = mkForce disabled;
    };

    cli-apps = {
      home-manager = enabled;
    };

    tools = {
      git = enabled;
    };

    suites = {
      common = enabled;
      development = enabled;
    };
  };

  home.shellAliases = {
    nixcfg = "nvim ~/.config/.dotfiles/dots/nixos/flake.nix";
  };

  home.stateVersion = "21.11";
}
