{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.programs.terminal.tools.sesh;
in
{
  options.khanelinix.programs.terminal.tools.sesh = {
    enable = mkEnableOption "sesh";
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ pkgs.sesh ];

      shellAliases = {
        sl = "sesh list";
        tl = "sesh last";
        tr = ''sesh connect --root "$(pwd)"'';
        ts = ''sesh connect "$(sesh list | fzf)"'';
      };
    };

    xdg.configFile."sesh/sesh.toml".source =
      let
        seshFormat = pkgs.formats.toml { };
        seshWindowNames = [
          "git"
          "files"
          "shell"
        ];
        seshWindows = [
          {
            name = "git";
            startup_script = "lazygit";
          }
          {
            name = "files";
            startup_script = "yazi";
          }
          {
            name = "shell";
          }
        ];
        seshSessions = [
          {
            name = "khanelinix";
            path = "~/khanelinix";
            startup_command = "tmux rename-window editor && exec nvim";
            windows = seshWindowNames;
          }
        ]
        ++
          map
            (name: {
              inherit name;
              path = "~/github/${name}";
              startup_command = "tmux rename-window editor && exec nvim";
              windows = seshWindowNames;
            })
            [
              "khanelivim"
              "nixpkgs"
              "home-manager"
              "nixvim"
              "waybar"
            ];
        seshConfig = {
          blacklist = [ "scratch" ];
          dir_length = 2;
          sort_order = [
            "config"
            "tmux"
            "zoxide"
          ];
          default_session.preview_command = "eza --all --git --icons --color=always {}";
          session = seshSessions;
          wildcard = [
            {
              pattern = "~/github/*";
              preview_command = "eza --all --git --icons --color=always {}";
            }
            {
              pattern = "~/.local/share/worktrees/*";
              preview_command = "eza --all --git --icons --color=always {}";
            }
            {
              pattern = "~/.local/share/worktrees/*/*";
              preview_command = "eza --all --git --icons --color=always {}";
            }
          ];
          window = seshWindows;
        };
      in
      pkgs.writeText "sesh.toml" ''
        #:schema https://github.com/joshmedeski/sesh/raw/main/sesh.schema.json

        ${builtins.readFile (seshFormat.generate "sesh.toml" seshConfig)}
      '';
  };
}
