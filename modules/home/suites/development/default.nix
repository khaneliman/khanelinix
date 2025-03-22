{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.${namespace}) enabled;
  inherit (inputs) snowfall-flake;

  tokenExports =
    lib.optionalString osConfig.${namespace}.security.sops.enable # Bash
      ''
        if [ -f ${config.sops.secrets.ANTHROPIC_API_KEY.path} ]; then
          ANTHROPIC_API_KEY="$(cat ${config.sops.secrets.ANTHROPIC_API_KEY.path})"
          export ANTHROPIC_API_KEY
        fi
        if [ -f ${config.sops.secrets.AZURE_OPENAI_API_KEY.path} ]; then
          AZURE_OPENAI_API_KEY="$(cat ${config.sops.secrets.AZURE_OPENAI_API_KEY.path})"
          export AZURE_OPENAI_API_KEY
        fi
        if [ -f ${config.sops.secrets.OPENAI_API_KEY.path} ]; then
          OPENAI_API_KEY="$(cat ${config.sops.secrets.OPENAI_API_KEY.path})"
          export OPENAI_API_KEY
        fi
      '';

  cfg = config.${namespace}.suites.development;
in
{
  options.${namespace}.suites.development = {
    enable = lib.mkEnableOption "common development configuration";
    azureEnable = lib.mkEnableOption "azure development configuration";
    dockerEnable = lib.mkEnableOption "docker development configuration";
    gameEnable = lib.mkEnableOption "game development configuration";
    goEnable = lib.mkEnableOption "go development configuration";
    kubernetesEnable = lib.mkEnableOption "kubernetes development configuration";
    nixEnable = lib.mkEnableOption "nix development configuration";
    sqlEnable = lib.mkEnableOption "sql development configuration";
    aiEnable = lib.mkEnableOption "ai development configuration";
  };

  config = mkIf cfg.enable {
    home = {
      packages =
        with pkgs;
        [
          jqp
          neovide
          onefetch
          postman
          bruno
          tree-sitter
          # FIXME: broken nixpkgs
          # (tree-sitter.override {
          #   webUISupport = true;
          # })
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          github-desktop
          qtcreator
        ]
        ++ lib.optionals cfg.nixEnable [
          hydra-check
          khanelinix.build-by-path
          nh
          nix-bisect
          nix-diff
          nix-fast-build
          nix-health
          nix-index
          nix-output-monitor
          nix-update
          nixpkgs-hammering
          nixpkgs-lint-community
          nixpkgs-review
          snowfall-flake.packages.${system}.flake
        ]
        ++ lib.optionals cfg.gameEnable [
          godot_4
          # NOTE: removed from nixpkgs
          # ue4
          unityhub
        ]
        ++ lib.optionals cfg.sqlEnable [
          dbeaver-bin
          # FIXME: broken nixpkgs dependency libiodbc
          # mysql-workbench
        ];

      shellAliases = {
        # Nixpkgs aliases
        prefetch-sri = "nix store prefetch-file $1";
        nrh = ''${lib.getExe pkgs.nixpkgs-review} rev HEAD'';
        nra = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "all"'';
        nrap = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "all" --post-result --num-parallel-evals 4'';
        nrd = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-darwin aarch64-darwin" --num-parallel-evals 2'';
        nrdp = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-darwin aarch64-darwin" --num-parallel-evals 2 --post-result'';
        nrl = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-linux aarch64-linux" --num-parallel-evals 2'';
        nrlp = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-linux aarch64-linux" --num-parallel-evals 2 --post-result'';
        nup = ''nix-update --commit -u $1'';
        num = ''nix-shell maintainers/scripts/update.nix --argstr maintainer $1'';
        # HM aliases
        hmd = ''nix build -L .#docs-html && ${
          if pkgs.stdenv.hostPlatform.isDarwin then
            "open -a /Applications/Firefox\\ Developer\\ Edition.app"
          else
            lib.getExe config.programs.firefox.package
        } result/share/doc/home-manager/index.xhtml'';
        hmt = ''f(){ nix-shell --pure tests -A "run.$1"; }; f'';
        hmts = ''f(){ nix build -L --reference-lock-file flake.lock "./tests#test-$1" && nix path-info -rSh ./result; }; f'';
      };
    };

    programs = {
      bash.initExtra = tokenExports;
      fish.shellInit = tokenExports;
      nix-your-shell = mkDefault enabled;
      vinegar.enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
      zsh.initContent = tokenExports;
    };

    khanelinix = {
      programs = {
        graphical = {
          editors = {
            vscode = mkDefault enabled;
          };
        };

        terminal = {
          editors = {
            # helix = enabled;
            neovim = {
              enable = mkDefault true;
              default = mkDefault true;
            };
          };

          tools = {
            act = mkDefault enabled;
            azure.enable = cfg.azureEnable;
            git-crypt = mkDefault enabled;
            go.enable = cfg.goEnable;
            jujutsu = mkDefault enabled;
            k9s.enable = cfg.kubernetesEnable;
            lazydocker.enable = cfg.dockerEnable;
            lazygit = mkDefault enabled;
            oh-my-posh = mkDefault enabled;
          };
        };
      };

      services.ollama.enable = mkDefault (cfg.aiEnable && pkgs.stdenv.hostPlatform.isDarwin);
    };

    sops.secrets = lib.mkIf osConfig.${namespace}.security.sops.enable {
      ANTHROPIC_API_KEY = {
        sopsFile = lib.snowfall.fs.get-file "secrets/CORE/default.yaml";
        path = "${config.home.homeDirectory}/.ANTHROPIC_API_KEY";
      };
      AZURE_OPENAI_API_KEY = {
        sopsFile = lib.snowfall.fs.get-file "secrets/CORE/default.yaml";
        path = "${config.home.homeDirectory}/.AZURE_OPENAI_API_KEY";
      };
      OPENAI_API_KEY = {
        sopsFile = lib.snowfall.fs.get-file "secrets/CORE/default.yaml";
        path = "${config.home.homeDirectory}/.OPENAI_API_KEY";
      };
    };
  };
}
