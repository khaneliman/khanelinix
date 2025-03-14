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
  inherit (lib.${namespace}) mkBoolOpt enabled;
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
    enable = mkBoolOpt false "Whether or not to enable common development configuration.";
    azureEnable = mkBoolOpt false "Whether or not to enable azure development configuration.";
    dockerEnable = mkBoolOpt false "Whether or not to enable docker development configuration.";
    gameEnable = mkBoolOpt false "Whether or not to enable game development configuration.";
    goEnable = mkBoolOpt false "Whether or not to enable go development configuration.";
    kubernetesEnable = mkBoolOpt false "Whether or not to enable kubernetes development configuration.";
    nixEnable = mkBoolOpt false "Whether or not to enable nix development configuration.";
    sqlEnable = mkBoolOpt false "Whether or not to enable sql development configuration.";
    aiEnable = mkBoolOpt true "Whether or not to enable ai development configuration.";
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
          act
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
          nixpkgs-hammering
          nixpkgs-lint-community
          nixpkgs-review
          nix-update
          nix-output-monitor
          snowfall-flake.packages.${system}.flake
          khanelinix.build-by-path
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
        # TODO: remove once remote building to khanelinix works
        nrmp = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-darwin aarch64-darwin aarch64-linux" --num-parallel-evals 3 --post-result'';
        nup = ''nix-shell maintainers/scripts/update.nix --argstr package $1'';
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
      zsh.initExtra = tokenExports;
      vinegar.enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
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
            azure.enable = cfg.azureEnable;
            git-crypt = mkDefault enabled;
            go.enable = cfg.goEnable;
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
