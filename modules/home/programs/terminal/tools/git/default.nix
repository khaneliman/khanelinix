{
  config,
  lib,
  pkgs,
  root,
  osConfig,
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
  inherit (flake.inputs.self.lib.khanelinix) mkOpt mkBoolOpt enabled;
  inherit (config.khanelinix) user;

  cfg = config.khanelinix.programs.terminal.tools.git;

  aliases = import ./aliases.nix { inherit lib pkgs; };
  ignores = import ./ignores.nix;

  tokenExports =
    lib.optionalString osConfig.khanelinix.security.sops.enable # Bash
      ''
        if [ -f ${config.sops.secrets."github/access-token".path} ]; then
          GITHUB_TOKEN="$(cat ${config.sops.secrets."github/access-token".path})"
          export GITHUB_TOKEN
          GH_TOKEN="$(cat ${config.sops.secrets."github/access-token".path})"
          export GH_TOKEN
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
    wslAgentBridge = mkBoolOpt false "Whether to enable the wsl agent bridge.";
    wslGitCredentialManagerPath =
      mkOpt types.str "/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe"
        "The windows git credential manager path.";
    _1password = mkBoolOpt false "Whether to enable 1Password integration.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      bfg-repo-cleaner
      git-crypt
      git-filter-repo
      git-lfs
      gitflow
      gitleaks
      gitlint
    ];

    programs = {
      git = {
        enable = true;
        package = pkgs.gitFull;
        inherit (cfg) includes userName userEmail;
        inherit (aliases) aliases;
        inherit (ignores) ignores;

        delta = {
          enable = true;

          options = {
            dark = true;
            features = mkForce "decorations side-by-side navigate";
            line-numbers = true;
            navigate = true;
            side-by-side = true;
          };
        };

        extraConfig = {
          credential = {
            helper =
              lib.optionalString cfg.wslAgentBridge cfg.wslGitCredentialManagerPath
              + lib.optionalString (!cfg.wslAgentBridge && pkgs.stdenv.isLinux) (
                getExe' config.programs.git.package "git-credential-libsecret"
              )
              + lib.optionalString (!cfg.wslAgentBridge && pkgs.stdenv.isDarwin) (
                getExe' config.programs.git.package "git-credential-osxkeychain"
              );

            useHttpPath = true;
          };

          fetch = {
            prune = true;
          };

          gpg.format = "ssh";
          # TODO: verify still works
          "gpg \"ssh\"".program = mkIf cfg._1password (
            lib.optionalString pkgs.stdenv.isLinux (getExe' pkgs._1password-gui "op-ssh-sign")
            + lib.optionalString pkgs.stdenv.isDarwin "${pkgs._1password-gui}/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
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

          rebase = {
            autoStash = true;
          };

          safe = {
            directory = [
              "~/khanelinix/"
              "/etc/nixos"
            ];
          };
        };

        signing = {
          key = cfg.signingKey;
          inherit (cfg) signByDefault;
        };
      };

      gh = {
        enable = true;

        extensions = with pkgs; [
          gh-dash # dashboard with pull requests and issues
          gh-eco # explore the ecosystem
          gh-cal # contributions calender terminal viewer
          gh-poi # clean up local branches safely
        ];

        gitCredentialHelper = {
          enable = true;
          hosts = [
            "https://github.com"
            "https://gist.github.com"
            "https://core-bts-02@dev.azure.com"
          ];
        };

        settings = {
          version = "1";
        };
      };

      bash.initExtra = tokenExports;
      fish.shellInit = tokenExports;
      zsh.initExtra = tokenExports;
    };

    home = {
      inherit (aliases) shellAliases;
    };

    sops.secrets = lib.mkIf osConfig.khanelinix.security.sops.enable {
      "github/access-token" = {
        sopsFile = root + "/secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.config/gh/access-token";
      };
    };
  };
}
