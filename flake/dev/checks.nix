{
  inputs,
  lib,
  self,
  ...
}:
{
  imports = lib.optional (inputs.git-hooks-nix ? flakeModule) inputs.git-hooks-nix.flakeModule;

  perSystem =
    { pkgs, system, ... }:
    {
      pre-commit = lib.mkIf (inputs.git-hooks-nix ? flakeModule) {
        check.enable = false;

        # Generated copies of canonical skills; hooks already check the
        # canonical tree and the marketplace validator enforces byte equality.
        settings.excludes = [ "^modules/common/ai-tools/marketplace/plugins/" ];

        settings.hooks = {
          check-merge-conflicts = {
            enable = true;
            args = [ "--assume-in-merge" ];
            excludes = [
              "modules/common/ai-tools/skills/jj-toolkit/references/conflict-resolution.md"
            ];
          };
          # Package C sources need their derivation's SDKs and generated inputs.
          # Only the standalone templates share a repository-level compile context.
          clang-tidy = {
            enable = true;
            files = "^templates/(c|cpp)/.*\\.(c|cpp)$";
            entry = lib.getExe (
              pkgs.writeShellScriptBin "clang-tidy-templates" ''
                exec ${pkgs.clang-tools}/bin/clang-tidy \
                  --checks='-*,clang-analyzer-*' --warnings-as-errors='*' "$@" --
              ''
            );
          };
          eslint =
            let
              eslintConfig = pkgs.writeText "eslint.config.mjs" ''
                import recommended from "${pkgs.eslint.src}/packages/js/src/configs/eslint-recommended.js";

                export default [
                  recommended,
                  {
                    languageOptions: {
                      globals: {
                        console: "readonly",
                        document: "readonly",
                        window: "readonly",
                        Event: "readonly",
                        setTimeout: "readonly",
                      },
                    },
                  },
                  {
                    files: ["modules/common/ai-tools/skills/develop-web-game/scripts/*.js"],
                    languageOptions: {
                      globals: { Buffer: "readonly", process: "readonly" },
                    },
                  },
                ];
              '';
            in
            {
              enable = true;
              entry = "${lib.getExe' pkgs.eslint "eslint"} --config ${eslintConfig}";
              package = pkgs.eslint;
            };
          luals = {
            enable = true;
            description = "LuaLS diagnostics";
            entry = "${lib.getExe pkgs.lua-language-server} --configpath=.luarc.json --check=. --check_format=pretty --checklevel=Warning";
            files = "\\.lua$";
            language = "system";
            pass_filenames = false;
          };
          okf-memory-conformance = {
            enable = true;
            description = "OKF bundle conformance + memory char budget";
            entry = "sh ${toString ../../modules/common/ai-tools/skills/okf-memory/scripts/check-bundle.sh}";
            files = "^\\.okf/.*\\.md$";
            language = "system";
            pass_filenames = false;
          };
          skill-tests = {
            enable = true;
            description = "Canonical skill and harness-adapter unit tests";
            entry = "${lib.getExe pkgs.python3} -B modules/common/ai-tools/skills/ai-tools-architect/scripts/run_skill_tests.py modules/common/ai-tools/skills";
            files = "^modules/(common/ai-tools/(skills/|planning-with-files/)|home/programs/terminal/tools/claude-code/hooks/planning-with-files\\.nix$)";
            language = "system";
            pass_filenames = false;
          };
          technical-writing-commit-message = {
            enable = true;
            name = "technical writing commit message";
            description = "Commit message structure and output style policy";
            always_run = true;
            entry = "${lib.getExe pkgs.python3} -B modules/common/ai-tools/skills/technical-writing/scripts/style_guard.py commit-message";
            language = "system";
            stages = [ "commit-msg" ];
          };
          technical-writing-policy = {
            enable = true;
            name = "technical writing policy";
            description = "Blocked output markers in shared writing policy";
            entry = "${lib.getExe pkgs.python3} -B modules/common/ai-tools/skills/technical-writing/scripts/style_guard.py scan";
            files = "^modules/common/ai-tools/(base\\.md|skills/technical-writing/(SKILL\\.md|references/rules\\.md))$";
            language = "system";
          };
          pre-commit-hook-ensure-sops.enable = true;
          # treefmt runs `statix fix`, which silently skips lints that have no
          # auto-fix (for example `repeated_keys`). Only `statix check` reports
          # them, matching the CI lint job.
          statix = {
            enable = true;
            package = pkgs.statix;
          };
          treefmt.enable = true;
          typos = {
            enable = true;
            settings.config = {
              default = {
                extend-words = {
                  # Package name
                  ue = "ue";
                  ue4 = "ue4";
                  # Option name
                  browseable = "browseable";
                  # Application name
                  shotcut = "shotcut";
                  Shotcut = "Shotcut";
                  # Plug and Play (citrix PnP settings keys)
                  Pn = "Pn";
                  # 15-byte /proc/PID/comm truncation of .Hyprland-wrapped
                  wrapp = "wrapp";
                };
                extend-identifiers = {
                  snd_hda_intel = "snd_hda_intel";
                  HSA_OVERRIDE_GFX_VERSION = "HSA_OVERRIDE_GFX_VERSION";
                  # ISO 639-2 code, file format, and copyright holder surname.
                  fre = "fre";
                  edn = "edn";
                  Zink = "Zink";
                };
                extend-ignore-re = [
                  # SSH public keys (ssh-rsa, ssh-ed25519, etc.)
                  "ssh-[a-z0-9]+ [A-Za-z0-9+/=]+"
                ];
              };
              files.extend-exclude = [
                "generated/*"
                "*.xsd"
                "*.svg"
                "*.yaml"
                "*.lock"
                "flake.lock"
                "package-lock.json"
                "*.png"
                "*.jpg"
                "*.jpeg"
                "*.gif"
                "*.ico"
                "*.webp"
                "**/nix/deps.nix"
                "*/ssh/hosts.nix"
                "custom.css"
              ];
            };
          };
        };
      };

      # `nix flake check` evaluates nixosConfigurations itself but ignores
      # darwinConfigurations. Check the Darwin systems native to the
      # checking system: nix-rosetta-builder is patched with applyPatches
      # and imported at eval time, which a Linux runner cannot realise.
      # Guard before filtering: reading cfg.pkgs already evaluates Darwin.
      # Home Manager is exercised through the systems that embed it.
      checks = {
        docs-html = self.packages.${system}.docs-html;
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin (
        lib.mapAttrs'
          (name: cfg: {
            name = "darwin-${name}";
            value = cfg.system;
          })
          (lib.filterAttrs (_: cfg: cfg.pkgs.stdenv.hostPlatform.system == system) self.darwinConfigurations)
      );
    };
}
