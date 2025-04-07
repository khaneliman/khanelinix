{
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
      "*.gitconfig"
      "*.git-blame-ignore-revs"
      "*.gitignore"
      "*.gitattributes"
      "*.luacheckrc"
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
      # TODO: formatters?
      "*.ac"
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
    ];

    formatter.ruff-format.options = [ "--isolated" ];
  };
}
