{
  config,
  lib,
  pkgs,
  osConfig ? { },

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.shell.fish;
  nixpkgsReviewGuard = /* fish */ ''
    if set -q NIXPKGS_REVIEW_ROOT
        return
    end
    if set -q IN_NIX_SHELL; and set -q XDG_CACHE_HOME; and string match -q "$XDG_CACHE_HOME/nixpkgs-review/*" -- "$PWD"
        return
    end
    if set -q IN_NIX_SHELL; and string match -q "$HOME/.cache/nixpkgs-review/*" -- "$PWD"
        return
    end
  '';
in
{
  options.khanelinix.programs.terminal.shell.fish = {
    enable = lib.mkEnableOption "fish";
  };

  config = mkIf cfg.enable {
    xdg.configFile."fish/functions" = {
      source = lib.cleanSourceWith { src = lib.cleanSource ./functions/.; };
      recursive = true;
    };

    programs.fish = {
      # Fish documentation
      # See: https://fishshell.com/docs/current/index.html
      enable = true;

      loginShellInit =
        let
          # This naive quoting is good enough in this case. There shouldn't be any
          # double quotes in the input string, and it needs to be double quoted in case
          # it contains a space (which is unlikely!)
          dquote = str: "\"" + str + "\"";

          makeBinPathList = map (pkgPath: pkgPath + "/bin");
        in
        lib.optionalString pkgs.stdenv.hostPlatform.isDarwin /* fish */ ''
          ${nixpkgsReviewGuard}

          export NIX_PATH="darwin-config=${config.home.homeDirectory}/.nixpkgs/darwin-configuration.nix:${config.home.homeDirectory}/.nix-defexpr/channels:$NIX_PATH"
          fish_add_path --move --prepend --path ${
            lib.concatMapStringsSep " " dquote (makeBinPathList (osConfig.environment.profiles or [ ]))
          }
          set fish_user_paths $fish_user_paths
        '';

      interactiveShellInit =
        /* fish */ ''
          ${nixpkgsReviewGuard}

          # 1password plugin
          if [ -f ${config.xdg.configHome}/op/plugins.sh ];
              source ${config.xdg.configHome}/op/plugins.sh
          end
        ''
        + lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
          # Nix
          if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish' ];
           source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
          end
          if [ -f '/nix/var/nix/profiles/default/etc/profile.d/nix.fish' ];
           source '/nix/var/nix/profiles/default/etc/profile.d/nix.fish'
          end
          # End Nix
        ''
        + ''
          # Disable greeting
          set fish_greeting

          ${lib.optionalString config.programs.fastfetch.enable "fastfetch"}
        '';

      plugins = [
        # Enable a plugin (here grc for colorized command output) from nixpkgs
        # { name = "grc"; src = pkgs.fishPlugins.grc.src; }
        {
          name = "autopair";
          inherit (pkgs.fishPlugins.autopair) src;
        }
        {
          name = "done";
          inherit (pkgs.fishPlugins.done) src;
        }
        {
          name = "fzf-fish";
          inherit (pkgs.fishPlugins.fzf-fish) src;
        }
        {
          name = "forgit";
          inherit (pkgs.fishPlugins.forgit) src;
        }
        {
          name = "tide";
          inherit (pkgs.fishPlugins.tide) src;
        }
        {
          name = "sponge";
          inherit (pkgs.fishPlugins.sponge) src;
        }
        {
          name = "wakatime";
          inherit (pkgs.fishPlugins.wakatime-fish) src;
        }
        {
          name = "z";
          inherit (pkgs.fishPlugins.z) src;
        }
      ];
    };
  };
}
