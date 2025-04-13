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
        run = "plugin sudo --args='paste'";
        desc = "sudo paste";
      }
      {
        on = [
          "R"
          "P"
        ];
        run = "plugin sudo --args='paste -f'";
        desc = "sudo paste (force)";
      }
      {
        on = [
          "R"
          "r"
        ];
        run = "plugin sudo --args='rename'";
        desc = "sudo rename";
      }
      {
        on = [
          "R"
          "p"
          "l"
        ];
        run = "plugin sudo --args='link'";
        desc = "sudo link (absolute path)";
      }
      {
        on = [
          "R"
          "p"
          "L"
        ];
        run = "plugin sudo --args='link -r'";
        desc = "sudo link (relative path)";
      }
      {
        on = [
          "R"
          "a"
        ];
        run = "plugin sudo --args='create'";
        desc = "sudo create (file or directory)";
      }
      {
        on = [
          "R"
          "d"
        ];
        run = "plugin sudo --args='remove'";
        desc = "sudo trash";
      }
      {
        on = [
          "R"
          "D"
        ];
        run = "plugin sudo --args='remove -P'";
        desc = "sudo delete (permanent)";
      }
    ]
    ++ lib.optional (lib.hasAttr "restore" enabledPlugins) {
      on = "u";
      run = "plugin restore";
      desc = "Restore last deleted files/folders";
    };
}
