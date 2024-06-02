{ lib, pkgs, ... }:
{
  programs.nixvim = {
    plugins = {
      codeium-nvim = {
        enable = true;

        extraOptions = {
          enable_chat = true;
        };

        tools = {
          curl = lib.getExe pkgs.curl;
          gzip = lib.getExe pkgs.gzip;
          uname = lib.getExe' pkgs.coreutils "uname";
          uuidgen = lib.getExe' pkgs.util-linux "uuidgen";
        };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>uc";
        action = ":Codeium Chat<CR>";
        options = {
          desc = "Codeium Chat";
          silent = true;
        };
      }
    ];
  };
}
