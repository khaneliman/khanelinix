{ config, lib, ... }:
let
  enabledPlugins = config.programs.yazi.plugins;
in
{
  prepend_keymap =
    lib.optionals (lib.hasAttr "sudo" enabledPlugins) [
      {
        on = [
          "R"
          "p"
          "p"
        ];
        run = "plugin sudo -- paste";
        desc = "sudo paste";
      }
      {
        on = [
          "R"
          "P"
        ];
        run = "plugin sudo -- paste --force";
        desc = "sudo paste (force)";
      }
      {
        on = [
          "R"
          "r"
        ];
        run = "plugin sudo -- rename";
        desc = "sudo rename";
      }
      {
        on = [
          "R"
          "p"
          "l"
        ];
        run = "plugin sudo -- link";
        desc = "sudo link (absolute path)";
      }
      {
        on = [
          "R"
          "p"
          "L"
        ];
        run = "plugin sudo -- link --relative";
        desc = "sudo link (relative path)";
      }
      {
        on = [
          "R"
          "a"
        ];
        run = "plugin sudo -- create";
        desc = "sudo create (file or directory)";
      }
      {
        on = [
          "R"
          "d"
        ];
        run = "plugin sudo -- remove";
        desc = "sudo trash";
      }
      {
        on = [
          "R"
          "D"
        ];
        run = "plugin sudo -- remove --permanently";
        desc = "sudo delete (permanent)";
      }
    ]
    ++ lib.optionals (lib.hasAttr "duckdb" enabledPlugins) [
      {
        on = "<C-h>";
        run = "plugin duckdb -1";
        desc = "Scroll data columns left";
      }
      {
        on = "<C-l>";
        run = "plugin duckdb +1";
        desc = "Scroll data columns right";
      }
    ]
    ++ lib.optional (lib.hasAttr "restore" enabledPlugins) {
      on = "u";
      run = "plugin restore";
      desc = "Restore last deleted files/folders";
    };
}
