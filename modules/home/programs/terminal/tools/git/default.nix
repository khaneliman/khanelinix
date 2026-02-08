{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib)
    types
    mkEnableOption
    mkIf
    mkForce
    getExe'
    ;
  inherit (lib.khanelinix) mkOpt enabled;
  inherit (config.khanelinix) user;

  cfg = config.khanelinix.programs.terminal.tools.git;

  aliases = import ./aliases.nix;
  ignores = import ./ignores.nix;
  shell-aliases = import ./shell-aliases.nix { inherit config lib pkgs; };

  tokenExports = lib.optionalString (osConfig.khanelinix.security.sops.enable or false) /* Bash */ ''
    if [ -f ${config.sops.secrets."github/access-token".path} ]; then
      GITHUB_TOKEN="$(cat ${config.sops.secrets."github/access-token".path})"
      export GITHUB_TOKEN
      GH_TOKEN="$(cat ${config.sops.secrets."github/access-token".path})"
      export GH_TOKEN
      # For github-mcp-server
      GITHUB_PERSONAL_ACCESS_TOKEN="$(cat ${config.sops.secrets."github/access-token".path})"
      export GITHUB_PERSONAL_ACCESS_TOKEN
    fi
  '';
in
{
  options.khanelinix.programs.terminal.tools.git = {
    enable = mkEnableOption "Git";
    includes = mkOpt (types.listOf types.attrs) [ ] "Git includeIf paths and conditions.";
    signByDefault = mkOpt types.bool true "Whether to sign commits by default.";
    signingKey =
      mkOpt types.str "${config.home.homeDirectory}/.ssh/id_ed25519"
        "The key ID to sign commits with.";
    userName = mkOpt types.str user.fullName "The name to configure git with.";
    userEmail = mkOpt types.str user.email "The email to configure git with.";
    wslAgentBridge = lib.mkEnableOption "the wsl agent bridge";
    wslGitCredentialManagerPath =
      mkOpt types.str "/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe"
        "The windows git credential manager path.";
    _1password = lib.mkEnableOption "1Password integration";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      bfg-repo-cleaner
      git-absorb
      git-crypt
      git-filter-repo
      git-lfs
      gitflow
      gitleaks
      gitlint
      tig
    ];

    programs = {
      delta = {
        enable = true;
        enableGitIntegration = true;

        options = {
          dark = true;
          # FIXME: module should accept a mergeable list be composable
          features = mkForce "decorations side-by-side navigate catppuccin-macchiato";
          line-numbers = true;
          navigate = true;
          side-by-side = true;
        };
      };

      difftastic = {
        enable = !config.programs.kitty.enable && !config.programs.delta.enable;

        git = {
          enable = true;
          diffToolMode = !config.programs.kitty.enable && !config.programs.delta.enable;
        };

        options = {
          background = "dark";
          display = "inline";
        };
      };

      git = {
        enable = true;
        package = pkgs.gitFull;

        inherit (cfg) includes;
        inherit (ignores) ignores;

        maintenance.enable = true;

        settings = {
          alias = aliases.aliases;

          branch.sort = "-committerdate";

          credential = {
            helper =
              lib.optionalString cfg.wslAgentBridge cfg.wslGitCredentialManagerPath
              + lib.optionalString (!cfg.wslAgentBridge && pkgs.stdenv.hostPlatform.isLinux) (
                getExe' config.programs.git.package "git-credential-libsecret"
              )
              + lib.optionalString (!cfg.wslAgentBridge && pkgs.stdenv.hostPlatform.isDarwin) (
                getExe' config.programs.git.package "git-credential-osxkeychain"
              );

            useHttpPath = true;
          };

          fetch = {
            prune = true;
          };

          # TODO: verify still works
          "gpg \"ssh\"".program = mkIf cfg._1password (
            lib.optionalString pkgs.stdenv.hostPlatform.isLinux (getExe' pkgs._1password-gui "op-ssh-sign")
            + lib.optionalString pkgs.stdenv.hostPlatform.isDarwin "${pkgs._1password-gui}/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
          );

          init = {
            defaultBranch = "main";
          };

          lfs = enabled;

          pull = {
            rebase = true;
          };

          push = {
            autoSetupRemote = true;
            default = "current";
          };

          rerere = {
            enabled = true;
          };

          rebase = {
            autoStash = true;
          };

          safe = {
            directory = [
              "${config.home.homeDirectory}/khanelinix/"
              "/etc/nixos"
              "/etc/nix-darwin"
            ];
          };

          user = {
            name = cfg.userName;
            email = cfg.userEmail;
          };
        };

        hooks = {
          pre-commit = lib.getExe (
            pkgs.writeShellScriptBin "pre-commit" ''
              # Check only staged files for unambiguous conflict start/end markers.
              mapfile -t stagedFiles < <(
                git diff --cached --name-only --diff-filter=ACMR
              )

              if ((''${#stagedFiles[@]})) && \
                git grep --cached -I -qE "^(<<<<<<< |>>>>>>> )" -- "''${stagedFiles[@]}"; then
                echo "Error: You have leftover merge conflict markers."
                exit 1
              fi
            ''
          );
          prepare-commit-msg = lib.getExe (
            pkgs.writeShellScriptBin "prepare-commit-msg" ''
              echo "Signing off commit"
              ${lib.getExe config.programs.git.package} interpret-trailers --if-exists doNothing --trailer \
                "Signed-off-by: ${cfg.userName} <${cfg.userEmail}>" \
                --in-place "$1"
            ''
          );
        };

        signing = {
          key = cfg.signingKey;
          format = "ssh";
          inherit (cfg) signByDefault;
        };
      };

      # Merge helper
      mergiraf = enabled;

      bash.initExtra = tokenExports;
      fish.shellInit = tokenExports;
      zsh.initContent = tokenExports;
    };

    home = {
      inherit (shell-aliases) shellAliases;
    };

    sops.secrets = lib.mkIf (osConfig.khanelinix.security.sops.enable or false) {
      "github/access-token" = {
        sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.config/gh/access-token";
      };
    };
  };
}
