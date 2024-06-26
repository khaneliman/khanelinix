{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  programs.nixvim = {
    plugins = {
      codesnap = {
        enable = true;
        package = pkgs.vimPlugins.codesnap-nvim;

        settings = {
          code_font_family = "MonaspiceNe Nerd Font";
          save_path = "${config.xdg.userDirs.pictures}/screenshots";
          mac_window_bar = true;
          title = "CodeSnap.nvim";
          watermark = "";
          breadcrumbs_separator = "/";
          has_breadcrumbs = true;
          has_line_number = false;
        };
      };

      which-key.registrations."<leader>c" = mkIf config.programs.nixvim.plugins.codesnap.enable {
        mode = "v";
        name = "󰄄 Codesnap";
      };
    };

    keymaps = lib.mkIf config.programs.nixvim.plugins.codesnap.enable [
      {
        mode = "v";
        key = "<leader>cs";
        action = ":CodeSnap<CR>";
        options = {
          desc = "Copy";
          silent = true;
        };
      }
      {
        mode = "v";
        key = "<leader>cS";
        action = ":CodeSnapSave<CR>";
        options = {
          desc = "Save";
          silent = true;
        };
      }
      {
        mode = "v";
        key = "<leader>ch";
        action = ":CodeSnapHighlight<CR>";
        options = {
          desc = "Highlight";
          silent = true;
        };
      }
      {
        mode = "v";
        key = "<leader>cH";
        action = ":CodeSnapSaveHighlight<CR>";
        options = {
          desc = "Save Highlight";
          silent = true;
        };
      }
    ];
  };
}
