{ pkgs, lib, ... }:
let
  inherit (lib) getExe mkIf generators;

  stylePkg = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "glamour";
    rev = "66d7b09325af67b1c5cdb063343e829c04ad7d5f";
    hash = "sha256-f3JFgqL3K/u8U/UzmBohJLDBPlT446bosRQDca9+4oA=";
  };

  # TODO: use theme module
  style = "${stylePkg.outPath}/themes/catppuccin-macchiato.json";

  config = generators.toYAML { } {
    inherit style;
    mouse = true;
    pager = true;
    width = 80;
  };
in
{
  home.file = mkIf pkgs.stdenv.isDarwin { "Library/Preferences/glow/glow.yml".text = config; };

  xdg.configFile = mkIf pkgs.stdenv.isLinux { "glow/glow.yml".text = config; };

  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [ glow-nvim ];

    extraConfigLuaPre = # lua
      ''
        require('glow').setup({
          border = "single";
          glow_path = "${getExe pkgs.glow}";
          style = "${style}";
        });
      '';

    keymaps = [
      {
        mode = "n";
        key = "<leader>pm";
        action = ":Glow<CR>";
        options = {
          desc = "Preview Markdown";
          silent = true;
        };
      }
    ];

    plugins.which-key.registrations."<leader>p" = {
      mode = "v";
      name = " Preview";
    };
  };
}
