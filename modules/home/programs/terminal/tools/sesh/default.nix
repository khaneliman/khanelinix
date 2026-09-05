{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.programs.terminal.tools.sesh;

  githubRoot = if pkgs.stdenv.hostPlatform.isLinux then "~/Documents/github" else "~/github";
  previewCommand = "eza --all --git --icons --color=always {}";
  seshWindowNames = [
    "git"
    "files"
    "shell"
  ];
  editorSession = name: path: {
    inherit name path;
    startup_command = "tmux rename-window editor && exec nvim";
    windows = seshWindowNames;
  };
in
{
  options.khanelinix.programs.terminal.tools.sesh = {
    enable = mkEnableOption "sesh";
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      sl = "sesh list";
      tl = "sesh last";
      troot = ''sesh connect --root "$(pwd)"'';
      ts = ''sesh connect "$(sesh list | fzf)"'';
    };

    programs.sesh = {
      enable = true;
      # The tmux module owns the sesh key bindings alongside its other binds.
      enableTmuxIntegration = false;

      settings = {
        blacklist = [ "scratch" ];
        dir_length = 2;
        sort_order = [
          "config"
          "tmux"
          "zoxide"
        ];
        default_session.preview_command = previewCommand;
        session = [
          (editorSession "khanelinix" "~/khanelinix")
        ]
        ++ map (name: editorSession name "${githubRoot}/${name}") [
          "khanelivim"
          "nixpkgs"
          "home-manager"
          "nixvim"
          "waybar"
        ];
        wildcard =
          map
            (pattern: {
              inherit pattern;
              preview_command = previewCommand;
            })
            [
              "${githubRoot}/*"
              "~/.local/share/worktrees/*"
              "~/.local/share/worktrees/*/*"
            ];
        window = [
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
      };
    };
  };
}
