{
  config,
  lib,
  osConfig ? { },
  pkgs,

  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.khanelinix) enabled;

  tokenExports = lib.optionalString (osConfig.khanelinix.security.sops.enable or false) /* Bash */ ''
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

  cfg = config.khanelinix.suites.development;
  isWSL = osConfig.khanelinix.archetypes.wsl.enable or false;
in
{
  options.khanelinix.suites.development = {
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
          onefetch
          tree-sitter
          # NOTE: when web ui needed. not cached upstream though
          # (tree-sitter.override {
          #   webUISupport = true;
          # })
        ]
        ++ lib.optionals (!isWSL) [
          bruno
          neovide
          postman
        ]
        ++ lib.optionals (pkgs.stdenv.hostPlatform.isLinux && !isWSL) [
          github-desktop
          qtcreator
        ]
        ++ lib.optionals cfg.dockerEnable [
          podman
          podman-tui
        ]
        ++ lib.optionals cfg.nixEnable [
          hydra-check
          khanelinix.build-by-path
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
            unityhub
          ]
        )
        ++ lib.optionals cfg.sqlEnable [
          dbeaver-bin
          # NOTE: 1 GB closure addition
          # mysql-workbench
        ]
        ++ lib.optionals cfg.aiEnable [
          # NOTE: hard to get out of neovim
          # antigravity
          github-copilot-cli
        ];

      shellAliases = {
        # Nixpkgs
        prefetch-sri = "nix store prefetch-file $1";
        nrh = "nixpkgs-review rev HEAD";
        nra = ''nixpkgs-review pr $1 --systems "aarch64-darwin x86_64-linux aarch64-linux"'';
        nrap = ''nixpkgs-review pr $1 --systems "aarch64-darwin x86_64-linux aarch64-linux" --post-result --num-parallel-evals 3'';
        nrapa = ''nixpkgs-review pr $1 --systems "aarch64-darwin x86_64-linux aarch64-linux" --post-result --num-parallel-evals 3 --approve-pr'';
        nrd = ''nixpkgs-review pr $1 --systems "aarch64-darwin"'';
        nrdp = ''nixpkgs-review pr $1 --systems "aarch64-darwin" --post-result'';
        nrl = ''nixpkgs-review pr $1 --systems "x86_64-linux aarch64-linux" --num-parallel-evals 2'';
        nrlp = ''nixpkgs-review pr $1 --systems "x86_64-linux aarch64-linux" --num-parallel-evals 2 --post-result'';
        nup = "nix-update --commit -u $1";
        num = "nix-shell maintainers/scripts/update.nix --argstr maintainer $1";
        ncs = ''f(){ nix build "nixpkgs#$1" --no-link && nix path-info --recursive --closure-size --human-readable $(nix-build --no-out-link '<nixpkgs>' -A "$1"); }; f'';
        ncsnc = ''f(){ nix build ".#nixosConfigurations.$1.config.system.build.toplevel" --no-link && nix path-info --recursive --closure-size --human-readable $(nix eval --raw ".#nixosConfigurations.$1.config.system.build.toplevel.outPath"); }; f'';
        ncsdc = ''f(){ nix build ".#darwinConfigurations.$1.config.system.build.toplevel" --no-link && nix path-info --recursive --closure-size --human-readable $(nix eval --raw ".#darwinConfigurations.$1.config.system.build.toplevel.outPath"); }; f'';
        # NOTE: vim-add 'owner/repo'
        vim-add = "nix run nixpkgs#vimPluginsUpdater add";
        # NOTE: vim-update 'plugin-name'
        vim-update = "nix run nixpkgs#vimPluginsUpdater update";
        vim-update-all = "nix run nixpkgs#vimPluginsUpdater -- --github-token=$(echo $GITHUB_TOKEN)";
        tree-update-all = ''./pkgs/applications/editors/vim/plugins/utils/nvim-treesitter/update.py && git add ./pkgs/applications/editors/vim/plugins/nvim-treesitter/generated.nix && git commit -m "vimPlugins.nvim-treesitter: update grammars"'';
        tree-check = "nix build .#vimPlugins.nvim-treesitter.passthru.tests.check-queries";
        lua-update = "nix run nixpkgs#luarocks-packages-updater update";
        lua-update-all = "nix run nixpkgs#luarocks-packages-updater -- --github-token=$(echo $GITHUB_TOKEN)";
        yazi-update = "f(){ ./pkgs/by-name/ya/yazi/plugins/update.py --plugin $1 --commit }; f";
        yazi-update-all = "./pkgs/by-name/ya/yazi/plugins/update.py --all --commit";

        # Home-Manager
        hmd = "nix build -L .#docs-html && ${
          if pkgs.stdenv.hostPlatform.isDarwin then "open" else "xdg-open"
        } result/share/doc/home-manager/index.xhtml";
        hmt = ''f(){ nix-build -j auto --show-trace --pure --option allow-import-from-derivation false tests -A build."$1"; }; f'';
        hmtf = ''f(){ nix build -L --option allow-import-from-derivation false --reference-lock-file flake.lock "./tests#test-$1"; }; f'';
        hmts = ''f(){ nix build -L --option allow-import-from-derivation false --reference-lock-file flake.lock "./tests#test-$1" && nix path-info -rSh ./result; }; f'';
        hmt-repl = "nix repl --reference-lock-file flake.lock ./tests";
      };
    };

    programs = {
      bash.initExtra = tokenExports;
      fish.shellInit = tokenExports;
      nix-your-shell = mkDefault enabled;
      vinegar.enable = mkDefault (pkgs.stdenv.hostPlatform.isLinux && !isWSL);
      zsh.initContent = tokenExports;
    };

    khanelinix = {
      programs = {
        graphical = {
          editors = {
            vscode.enable = mkDefault (!isWSL);
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
            claude-code.enable = cfg.aiEnable;
            gemini-cli.enable = cfg.aiEnable;
            mcp.enable = cfg.aiEnable;
            opencode.enable = cfg.aiEnable;
            git-crypt = mkDefault enabled;
            go.enable = cfg.goEnable;
            gh = mkDefault enabled;
            jujutsu = mkDefault enabled;
            jjui = mkDefault enabled;
            k9s.enable = cfg.kubernetesEnable;
            lazydocker.enable = cfg.dockerEnable;
            lazygit = mkDefault enabled;
            oh-my-posh = mkDefault enabled;
          };
        };
      };

      services.ollama.enable = mkDefault (cfg.aiEnable && pkgs.stdenv.hostPlatform.isDarwin);
    };

    sops.secrets = lib.mkIf (osConfig.khanelinix.security.sops.enable or false) {
      ANTHROPIC_API_KEY = {
        sopsFile = lib.getFile "secrets/CORE/default.yaml";
        path = "${config.home.homeDirectory}/.ANTHROPIC_API_KEY";
      };
      AZURE_OPENAI_API_KEY = {
        sopsFile = lib.getFile "secrets/CORE/default.yaml";
        path = "${config.home.homeDirectory}/.AZURE_OPENAI_API_KEY";
      };
      OPENAI_API_KEY = {
        sopsFile = lib.getFile "secrets/CORE/default.yaml";
        path = "${config.home.homeDirectory}/.OPENAI_API_KEY";
      };
      TAVILY_API_KEY = {
        sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.TAVILY_API_KEY";
      };
    };
  };
}
