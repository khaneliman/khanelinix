{
  config,
  lib,
  pkgs,
  osConfig,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.shell.fish;
in
{
  options.${namespace}.programs.terminal.shell.fish = {
    enable = mkBoolOpt false "Whether to enable fish.";
  };

  config = mkIf cfg.enable {
    xdg.configFile."fish/functions" = {
      source = lib.cleanSourceWith { src = lib.cleanSource ./functions/.; };
      recursive = true;
    };

    xdg.configFile."fish/themes" = {
      source = lib.cleanSourceWith { src = lib.cleanSource ./themes/.; };
      recursive = true;
    };

    programs.fish = {
      enable = true;

      loginShellInit =
        let
          # This naive quoting is good enough in this case. There shouldn't be any
          # double quotes in the input string, and it needs to be double quoted in case
          # it contains a space (which is unlikely!)
          dquote = str: "\"" + str + "\"";

          makeBinPathList = map (path: path + "/bin");
        in
        lib.optionalString pkgs.stdenv.isDarwin # fish
          ''
            export NIX_PATH="darwin-config=$HOME/.nixpkgs/darwin-configuration.nix:$HOME/.nix-defexpr/channels:$NIX_PATH"
            fish_add_path --move --prepend --path ${
              lib.concatMapStringsSep " " dquote (makeBinPathList osConfig.environment.profiles)
            }
            set fish_user_paths $fish_user_paths
          '';

      interactiveShellInit =
        lib.optionalString pkgs.stdenv.isDarwin # fish
          ''
            # 1password plugin
            if [ -f ~/.config/op/plugins.sh ];
                source ~/.config/op/plugins.sh
            end

            # Brew environment
            if [ -f /opt/homebrew/bin/brew ];
            	eval "$("/opt/homebrew/bin/brew" shellenv)"
            end

            # Nix
            if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish' ];
             source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
            end
            if [ -f '/nix/var/nix/profiles/default/etc/profile.d/nix.fish' ];
             source '/nix/var/nix/profiles/default/etc/profile.d/nix.fish'
            end
            # End Nix

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
