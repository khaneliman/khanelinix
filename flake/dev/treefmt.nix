{
  inputs,
  lib,
  ...
}:
{
  imports = lib.optional (inputs.treefmt-nix ? flakeModule) inputs.treefmt-nix.flakeModule;

  perSystem =
    { pkgs, ... }:
    {
      treefmt = lib.mkIf (inputs.treefmt-nix ? flakeModule) {
        flakeCheck = true;
        flakeFormatter = true;

        projectRootFile = "flake.nix";

        programs = {
          actionlint.enable = true;
          biome = {
            enable = true;
            excludes = [
              "*.html"
              "*.scss"
            ];
            settings.formatter.formatWithErrors = true;
          };
          clang-format.enable = true;
          deadnix = {
            enable = true;
            no-lambda-arg = true;
          };
          deno = {
            enable = true;
            # Using biome for these
            excludes = [
              "*.html"
              "*.scss"
              "*.ts"
              "*.js"
              "*.json"
              "*.jsonc"
              "*.yaml"
              "*.yml"
            ];
          };
          fantomas.enable = true;
          fish_indent.enable = true;
          gofmt.enable = true;
          isort.enable = true;
          nixf-diagnose = {
            enable = true;
            priority = -1;
            package = pkgs.nixf-diagnose;
          };
          nixfmt = {
            enable = true;
            package = pkgs.nixfmt;
          };
          prettier = {
            enable = true;
            includes = [
              "*.html"
              "*.scss"
            ];
          };
          ruff-check.enable = true;
          ruff-format.enable = true;
          rustfmt.enable = true;
          shfmt = {
            enable = true;
            indent_size = 4;
          };
          statix = {
            enable = true;
            priority = -2;
          };
          stylua.enable = true;
          taplo.enable = true;
          yamlfmt.enable = true;
        };

        settings =
          let
            fileLib = inputs.self.lib.file;
            repoRoot = ../..;

            licenseMarkers = [
              "LICENSE"
              "LICENSE.md"
              "LICENSE.txt"
            ];
            rootPrefix = "${toString repoRoot}/";

            findLicensedDirectories =
              dir:
              let
                subdirectories = map (name: dir + "/${name}") (fileLib.listDirectories dir);
                nestedDirectories = lib.concatMap findLicensedDirectories subdirectories;
                relativeDirectory = lib.removePrefix rootPrefix (toString dir);
              in
              lib.optional (builtins.any (
                marker: builtins.pathExists (dir + "/${marker}")
              ) licenseMarkers) "${relativeDirectory}/**"
              ++ nestedDirectories;

            licensedDirectoryExcludes = findLicensedDirectories repoRoot;
          in
          {
            global.excludes = [
              "*.editorconfig"
              "*.envrc"
              "*.gitconfig"
              "*.git-blame-ignore-revs"
              "*.gitignore"
              "*.gitattributes"
              "*CODEOWNERS"
              "*LICENSE"
              "*flake.lock"
              "*.conf"
              "*.gif"
              "*.ico"
              "*.ini"
              "*.micro"
              "*.png"
              "*.svg"
              "*.tmux"
              "*/config"
              # Excludes for formatter inputs that break template/style assumptions
              "*.ac"
              "*.css" # Exclude CSS files from formatting since we use Nix template variables
              "*.csproj"
              "*.fsproj"
              "*.in"
              "*.kdl"
              "*.kvconfig"
              "*.rasi"
              "*.sln"
              "*.xml"
              "*.zsh"
              "*Makefile"
              "*makefile"

              # Unique files
              "homes/x86_64-linux/nixos@CORE-PW0D2M1A/git/windows-compat-config"
              "lib/base64/ascii"
              "modules/darwin/desktop/wms/yabai/extraConfig"
              "modules/home/programs/graphical/bars/sketchybar/dynamic-island-sketchybar/helper/islandhelper"
              "modules/home/programs/graphical/bars/sketchybar/dynamic-island-sketchybar/scripts/islands/music/get_artwork.scpt"
              "modules/home/programs/graphical/bars/sketchybar/dynamic-island-sketchybar/scripts/islands/volume/data/cache"
              "modules/home/programs/graphical/bars/sketchybar/dynamic-island-sketchybar/sketchybarrc"
              "systems/x86_64-linux/khanelinix/hyprlandOutput"
              "systems/x86_64-linux/khanelinix/swayOutput"
            ]
            ++ licensedDirectoryExcludes;

            formatter.ruff-format.options = [ "--isolated" ];
            formatter.nixf-diagnose.options = [
              "--ignore=sema-unused-def-lambda-witharg-formal"
            ];
          };
      };
    };
}
