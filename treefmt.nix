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
      "*.svg"
      "*.png"
      "*.gif"
      "*.ico"
      # TODO: formatters?
      "*Makefile"
      "*makefile"
      "*.xml"
      "*.zsh"
      "*.rasi"
      "*.kdl"

      # TODO: exceptions
      # WARN no formatter for path: homes/x86_64-linux/nixos@CORE-PW00LM92/git/windows-compat-config
      # WARN no formatter for path: modules/darwin/desktop/wms/yabai/extraConfig
      # WARN no formatter for path: modules/home/programs/graphical/addons/electron-support/electron-flags.conf
      # WARN no formatter for path: modules/home/programs/graphical/addons/kanshi/config
      # WARN no formatter for path: modules/home/programs/graphical/addons/mako/config
      # WARN no formatter for path: modules/home/programs/graphical/addons/swappy/config
      # WARN no formatter for path: modules/home/programs/graphical/bars/sketchybar/dynamic-island-sketchybar/helper/islandhelper
      # WARN no formatter for path: modules/home/programs/graphical/bars/sketchybar/dynamic-island-sketchybar/scripts/islands/music/cava.conf
      # WARN no formatter for path: modules/home/programs/graphical/bars/sketchybar/dynamic-island-sketchybar/scripts/islands/music/get_artwork.scpt
      # WARN no formatter for path: modules/home/programs/graphical/bars/sketchybar/dynamic-island-sketchybar/scripts/islands/volume/data/cache
      # WARN no formatter for path: modules/home/programs/graphical/bars/sketchybar/dynamic-island-sketchybar/sketchybarrc
      # WARN no formatter for path: modules/home/programs/graphical/launchers/wofi/config
      # WARN no formatter for path: modules/home/programs/terminal/editors/micro/catppuccin-macchiato.micro
      # WARN no formatter for path: modules/home/programs/terminal/tools/tmux/config/general.tmux
      # WARN no formatter for path: modules/home/theme/qt/Kvantum/Catppuccin-Macchiato-Blue/Catppuccin-Macchiato-Blue.kvconfig
      # WARN no formatter for path: modules/home/theme/qt/Kvantum/kvantum.kvconfig
      # WARN no formatter for path: modules/nixos/programs/graphical/addons/looking-glass-client/client.ini
      # WARN no formatter for path: systems/x86_64-linux/khanelinix/hyprlandOutput
      # WARN no formatter for path: systems/x86_64-linux/khanelinix/swayOutput
      # WARN no formatter for path: templates/c/Makefile.in
      # WARN no formatter for path: templates/c/configure.ac
      # WARN no formatter for path: templates/dotnetf/HelloWorld.Test/HelloWorld.Test.fsproj
      # WARN no formatter for path: templates/dotnetf/HelloWorld.sln
      # WARN no formatter for path: templates/dotnetf/HelloWorld/HelloWorld.fsproj
    ];

    formatter.ruff-format.options = [ "--isolated" ];
  };
}
