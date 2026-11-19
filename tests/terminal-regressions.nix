{
  source,
  repo,
  nixpkgs,
  gatewayEnabled ? false,
}:
let
  pkgs = import nixpkgs { system = builtins.currentSystem; };
  lib = pkgs.lib // {
    getFile = path: repo + "/${path}";
    khanelinix.mkOpt =
      type: default: description:
      pkgs.lib.mkOption { inherit type default description; };
  };
  config = {
    khanelinix = {
      programs.terminal = {
        tools = {
          codex.enable = true;
          opencode.enable = true;
          pi-coding-agent.enable = true;
        };
        emulators.alacritty = {
          enable = true;
          font = {
            normal = "normal";
            bold = "bold";
            italic = "italic";
            bold_italic = "bold_italic";
          };
        };
      };
      fonts = { };
      services.cliproxyapi.enable = gatewayEnabled;
    };
    services = {
      exo.enable = true;
      ollama.enable = true;
    };
    home = {
      homeDirectory = "/home/test";
      preferXdgDirectories = true;
    };
    xdg = {
      configHome = "/home/test/.config";
      cacheHome = "/home/test/.cache";
      dataHome = "/home/test/.local/share";
    };
    programs.gh.enable = false;
  };
  modelOptions = { config, ... }: {
    inherit
      (import (repo + "/modules/nixos/services/llm/llama-swap.nix") {
        inherit config lib pkgs;
      })
      options
      ;
  };
  localLlm =
    (lib.evalModules {
      modules = [
        modelOptions
        {
          options.khanelinix.services.llm.enable = lib.mkEnableOption "fixture LLM service";
          config.khanelinix.services.llm = {
            enable = true;
            llamaSwap = {
              enable = true;
              port = 18090;
              models = {
                qwen3-coder-30b = {
                  tag = "qwen3-coder:30b";
                  displayName = "Fixture coder";
                  contextSize = 65536;
                  parallelSlots = 2;
                  maxOutputTokens = 4096;
                };
                fixture-stream = {
                  backend = "colibri";
                  contextSize = 16384;
                };
              };
            };
          };
        }
      ];
    }).config.khanelinix.services.llm;
  args = {
    inherit config lib pkgs;
    inputs = { };
    osConfig.khanelinix.services.llm = localLlm;
  };
  codex = import (source + "/tools/codex") args;
  opencode = import (source + "/tools/opencode") args;
  renderLocalModels =
    osConfig:
    let
      clientArgs = args // {
        inherit osConfig;
      };
      provider = import (source + "/tools/opencode/provider.nix") (
        removeAttrs clientArgs [
          "inputs"
          "pkgs"
        ]
      );
      pi = import (source + "/tools/pi-coding-agent") clientArgs;
      opencodeAliases = (import (source + "/tools/opencode") clientArgs).config.content.home.shellAliases;
    in
    {
      opencode = provider.config.programs.opencode.settings.provider.llama-swap;
      pi = pi.config.content.programs.pi-coding-agent.models.content.providers.llama-swap or null;
      aliases = lib.filterAttrs (name: _: lib.hasPrefix "opencode-local-" name) opencodeAliases;
    };
  mockCurl = pkgs.writeShellScriptBin "curl" ''
    printf '%s\n' "$@" | ${lib.getExe pkgs.jq} -Rcs 'split("\n")[:-1]' >> "$HTTP_LOG"
    case "''${!#}" in
      "http://127.0.0.1:18090/running") printf '%s\n' "$SWAP_FIXTURE" ;;
      "http://[::1]:11435/api/ps") printf '%s\n' "$OLLAMA_FIXTURE" ;;
      "http://127.0.0.1:18090/api/models/unload" | "http://[::1]:11435/api/generate")
        exit "''${UNLOAD_STATUS:-0}"
        ;;
      *) exit 42 ;;
    esac
  '';
  gpuConfig =
    (import (repo + "/modules/nixos/services/llm/gpu-coordination.nix") {
      inherit lib;
      pkgs = pkgs // {
        curl = mockCurl;
      };
      config = {
        khanelinix.hardware.gpu.amd = {
          enable = true;
          enableRocmSupport = true;
        };
        khanelinix.services.llm = localLlm // {
          gpuCoordination.enable = true;
          llamaSwap = localLlm.llamaSwap // {
            host = "0.0.0.0";
          };
        };
        services.ollama = {
          enable = true;
          host = "[::]";
          port = 11435;
        };
      };
    }).config.content;
  gpuHelper =
    assert lib.all (entry: entry.assertion) gpuConfig.assertions;
    builtins.head gpuConfig.environment.systemPackages.content;
  notifier = pkgs.writeShellScriptBin "notify-send" ''
    printf '%s\n' "$@" > "$NOTIFY_LOG"
  '';
  testCodex = import (source + "/tools/codex") (
    args
    // {
      pkgs = pkgs // {
        libnotify = notifier;
      };
    }
  );
  testNotify = builtins.head testCodex.config.content.programs.codex.settings.notify;
  claudeNotify = import (source + "/tools/claude-code/notify.nix") {
    inherit config lib;
    pkgs = pkgs // {
      libnotify = notifier;
    };
  };
  subagentStop = import (source + "/tools/claude-code/hooks/subagent-stop.nix") {
    inherit claudeNotify lib pkgs;
  };
  testClaudeNotify = lib.getExe claudeNotify;
  testSubagentStop = (builtins.head (builtins.head subagentStop.SubagentStop).hooks).command;
  aliases = codex.config.content.home.shellAliases // opencode.config.content.home.shellAliases;
  compat = import (source + "/shells/alias-compat.nix") { inherit lib pkgs; };
  alacritty =
    platform:
    (import (source + "/emulators/alacritty") {
      inherit config lib;
      pkgs = pkgs // {
        stdenv.hostPlatform = {
          isLinux = platform == "linux";
          isDarwin = platform == "darwin";
        };
      };
    }).config.content.programs.alacritty.settings.window;
  kitty = (import (source + "/emulators/kitty") { inherit config lib pkgs; }).config.content.programs;
in
{
  inherit
    aliases
    testClaudeNotify
    testNotify
    testSubagentStop
    ;
  packages = [
    pkgs.fish
    pkgs.bash
    pkgs.git
    pkgs.perl
    pkgs.libnotify
    gpuHelper
  ];
  llmGpu = lib.getExe gpuHelper;
  localModels = {
    enabled = renderLocalModels args.osConfig;
    absent = renderLocalModels { };
    disabled = renderLocalModels {
      khanelinix.services.llm = localLlm // {
        enable = false;
      };
    };
    swapDisabled = renderLocalModels {
      khanelinix.services.llm = localLlm // {
        llamaSwap = localLlm.llamaSwap // {
          enable = false;
        };
      };
    };
    empty = renderLocalModels {
      khanelinix.services.llm = localLlm // {
        llamaSwap = localLlm.llamaSwap // {
          clientCatalog = { };
        };
      };
    };
  };
  notifyDrvs = map (path: builtins.head (builtins.attrNames (builtins.getContext path))) (
    codex.config.content.programs.codex.settings.notify
    ++ [
      testNotify
      testClaudeNotify
      testSubagentStop
    ]
  );
  wrapped = lib.filterAttrs (_: value: lib.hasPrefix "f(){" value) aliases;
  functions = compat.translateFishFunctions aliases;
  bashAliases = compat.translateAliasMap aliases;
  gitAliases =
    (import (source + "/tools/git/shell-aliases.nix") { inherit config lib pkgs; }).shellAliases;
  commandAliases = (import (source + "/tools/git/aliases.nix")).aliases;
  git = lib.getExe pkgs.git;
  perl = lib.getExe pkgs.perl;
  inherit (import (source + "/tools/git/ignores.nix")) ignores;
  windows = {
    linux = alacritty "linux";
    darwin = alacritty "darwin";
  };
  kittyHelpers = {
    bash = kitty.bash.initExtra.content;
    fish = kitty.fish.functions;
  };
  bash = lib.getExe pkgs.bash;
  fish = lib.getExe pkgs.fish;
  notify = codex.config.content.programs.codex.settings.notify;
  notifyExe = lib.getExe pkgs.libnotify;
}
