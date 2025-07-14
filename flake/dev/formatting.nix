{ inputs, lib, ... }:
{
  imports = lib.optional (inputs.treefmt-nix ? flakeModule) inputs.treefmt-nix.flakeModule;

  perSystem = _: {
    treefmt = lib.mkIf (inputs.treefmt-nix ? flakeModule) {
      flakeCheck = true;
      flakeFormatter = true;

      projectRootFile = "flake.nix";

      programs = {
        actionlint.enable = true;
        biome = {
          enable = true;
          settings.formatter.formatWithErrors = true;
        };
        clang-format.enable = true;
        deadnix = {
          enable = true;
        };
        deno = {
          enable = true;
          # Using biome for these
          excludes = [
            "*.ts"
            "*.js"
            "*.json"
            "*.jsonc"
          ];
        };
        fantomas.enable = true;
        fish_indent.enable = true;
        gofmt.enable = true;
        isort.enable = true;
        nixfmt.enable = true;
        nufmt.enable = true;
        ruff-check.enable = true;
        ruff-format.enable = true;
        rustfmt.enable = true;
        shfmt = {
          enable = true;
          indent_size = 4;
        };
        statix.enable = true;
        stylua.enable = true;
        taplo.enable = true;
        yamlfmt.enable = true;
      };

      settings = {
        global.excludes = [
          "*.editorconfig"
          "*.envrc"
          "*.gif"
          "*.git-blame-ignore-revs"
          "*.gitattributes"
          "*.gitconfig"
          "*.gitignore"
          "*.kdl"
          "*.luacheckrc"
          "*.png"
          "*.rasi"
          "*.svg"
          "*.zsh"
          "*CODEOWNERS"
          "*LICENSE"
          "*flake.lock"
          "assets/*"
          "justfile"
          # CSS files with template variables
          "**/waybar/**/style.css"
          "**/waybar/**/*.css"
          "**/anyrun/**/*.css"
          "**/caprine/**/*.css"
          "**/firefox/**/*.css"
          "**/wofi/**/*.css"
          "**/catppuccin/**/*.css"
        ];

        formatter.ruff-format.options = [ "--isolated" ];
      };
    };
  };
}
