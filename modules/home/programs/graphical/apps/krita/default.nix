{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.apps.krita;

  aiDiffusion = pkgs.stdenvNoCC.mkDerivation {
    pname = "krita-ai-diffusion";
    version = "1.53.0";

    src = pkgs.fetchzip {
      url = "https://github.com/Acly/krita-ai-diffusion/releases/download/v1.53.0/krita_ai_diffusion-1.53.0.zip";
      stripRoot = false;
      hash = "sha256-rzJmqjRP7Ns2jhG5L4e/OpHGrL5EagDIweQGR5by3+0=";
    };

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -r . "$out"
      chmod -R u+w "$out"

      substituteInPlace "$out/ai_diffusion/settings.py" \
        --replace-fail \
          '_("Enable Automatic Updates"), True,' \
          '_("Enable Automatic Updates"), False,'
      substituteInPlace "$out/ai_diffusion/model/updates.py" \
        --replace-fail \
          '    async def _run(self):' \
          $'    async def _run(self):\n        raise RuntimeError("Plugin updates are managed by Nix.")'

      runHook postInstall
    '';

    doInstallCheck = true;
    nativeInstallCheckInputs = [ pkgs.python3 ];
    installCheckPhase = ''
      runHook preInstallCheck

      python3 - "$out/ai_diffusion/model/updates.py" <<'PY'
      import ast
      import asyncio
      import sys
      from pathlib import Path
      from types import SimpleNamespace

      updates_path = Path(sys.argv[1])
      updates_tree = ast.parse(updates_path.read_text())
      auto_update = next(
          node
          for node in updates_tree.body
          if isinstance(node, ast.ClassDef) and node.name == "AutoUpdate"
      )
      update_method = next(
          node
          for node in auto_update.body
          if isinstance(node, ast.AsyncFunctionDef) and node.name == "_run"
      )
      exec(compile(ast.Module([update_method], []), str(updates_path), "exec"), globals())

      try:
          asyncio.run(_run(SimpleNamespace()))
      except RuntimeError as error:
          assert str(error) == "Plugin updates are managed by Nix."
      else:
          raise AssertionError("The Nix-managed plugin attempted a self-update")
      PY

      runHook postInstallCheck
    '';
  };
in
{
  options.khanelinix.programs.graphical.apps.krita = {
    enable = lib.mkEnableOption "Krita digital painting application";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.krita;
      description = "The Krita package to install.";
    };

    aiDiffusion = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to install and enable the AI Diffusion plugin for ComfyUI integration.";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = aiDiffusion;
        description = "The AI Diffusion plugin package containing ai_diffusion and ai_diffusion.desktop.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.dataFile = lib.mkIf cfg.aiDiffusion.enable {
      "krita/pykrita/ai_diffusion".source = "${cfg.aiDiffusion.package}/ai_diffusion";
      "krita/pykrita/ai_diffusion.desktop".source = "${cfg.aiDiffusion.package}/ai_diffusion.desktop";
    };
  };
}
