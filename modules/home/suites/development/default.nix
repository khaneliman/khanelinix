{
  config,
  lib,
  osConfig,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.${namespace}) enabled;

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
        if [ -f ${config.sops.secrets.TAVILY_API_KEY.path} ]; then
          TAVILY_API_KEY="$(cat ${config.sops.secrets.TAVILY_API_KEY.path})"
          export TAVILY_API_KEY
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
          # FIXME: build hangs
          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux bruno)
          tree-sitter
          # NOTE: when web ui needed. not cached upstream though
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
          nurl
        ]
        ++ lib.optionals cfg.gameEnable (
          [ gdevelop ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            godot
            # NOTE: removed from nixpkgs
            # ue4
            # FIXME: broken nixpkgs
            # unityhub
          ]
        )
        ++ lib.optionals cfg.sqlEnable [
          dbeaver-bin
          mysql-workbench
        ]
        ++ lib.optionals cfg.aiEnable [
          claude-code
        ];

      shellAliases = {
        # Nixpkgs
        prefetch-sri = "nix store prefetch-file $1";
        nrh = ''${lib.getExe pkgs.nixpkgs-review} rev HEAD'';
        nra = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "all"'';
        nrap = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "all" --post-result --num-parallel-evals 4'';
        nrapa = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "all" --post-result --num-parallel-evals 4 --approve-pr'';
        nrd = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-darwin aarch64-darwin" --num-parallel-evals 2'';
        nrdp = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-darwin aarch64-darwin" --num-parallel-evals 2 --post-result'';
        nrl = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-linux aarch64-linux" --num-parallel-evals 2'';
        nrlp = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-linux aarch64-linux" --num-parallel-evals 2 --post-result'';
        nup = ''nix-update --commit -u $1'';
        num = ''nix-shell maintainers/scripts/update.nix --argstr maintainer $1'';
        ncs = ''f(){ nix build "nixpkgs#$1" --no-link && nix path-info --recursive --closure-size --human-readable $(nix-build --no-out-link '<nixpkgs>' -A "$1"); }; f'';
        ncsnc = ''f(){ nix build ".#nixosConfigurations.$1.config.system.build.toplevel" --no-link && nix path-info --recursive --closure-size --human-readable $(nix eval --raw ".#nixosConfigurations.$1.config.system.build.toplevel.outPath"); }; f'';
        ncsdc = ''f(){ nix build ".#darwinConfigurations.$1.config.system.build.toplevel" --no-link && nix path-info --recursive --closure-size --human-readable $(nix eval --raw ".#darwinConfigurations.$1.config.system.build.toplevel.outPath"); }; f'';
        # NOTE: vim-add 'owner/repo'
        vim-add = ''nix run nixpkgs#vimPluginsUpdater add'';
        # NOTE: vim-update 'plugin-name'
        vim-update = ''nix run nixpkgs#vimPluginsUpdater update'';
        vim-update-all = ''nix run nixpkgs#vimPluginsUpdater -- --github-token=$(echo $GITHUB_TOKEN)'';
        lua-update-all = ''nix run nixpkgs#luarocks-packages-updater -- --github-token=$(echo $GITHUB_TOKEN)'';

        # Home-Manager
        hmd = ''nix build -L .#docs-html && ${
          if pkgs.stdenv.hostPlatform.isDarwin then
            "open -a ${config.programs.firefox.package}/Applications/Firefox\\ Developer\\ Edition.app"
          else
            lib.getExe config.programs.firefox.package
        } result/share/doc/home-manager/index.xhtml'';
        hmt = ''f(){ nix-build -j auto --show-trace --pure --option allow-import-from-derivation false tests -A build."$1"; }; f'';
        hmtf = ''f(){ nix build -L --option allow-import-from-derivation false --reference-lock-file flake.lock "./tests#test-$1"; }; f'';
        hmts = ''f(){ nix build -L --option allow-import-from-derivation false --reference-lock-file flake.lock "./tests#test-$1" && nix path-info -rSh ./result; }; f'';
        hmt-repl = ''nix repl --reference-lock-file flake.lock ./tests'';
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
            gh = mkDefault enabled;
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
      TAVILY_API_KEY = {
        sopsFile = lib.snowfall.fs.get-file "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.TAVILY_API_KEY";
      };
    };
  };
}
