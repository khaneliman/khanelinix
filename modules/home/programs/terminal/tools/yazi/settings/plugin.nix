{
  config,
  lib,
}:
let
  enabledPlugins = config.programs.yazi.plugins;
in
{
  plugin = {
    prepend_fetchers =
      lib.optionals (lib.hasAttr "git" enabledPlugins) [
        {
          group = "git";
          url = "*";
          run = "git";
        }
        {
          group = "git";
          url = "*/";
          run = "git";
        }
      ]
      ++ lib.optional (lib.hasAttr "mime-ext" enabledPlugins) {
        group = "mime";
        url = "*";
        run = "mime-ext";
        prio = "high";
      };

    prepend_preloaders = [
      {
        url = "/mnt/austinserver/**";
        run = "noop";
      }
      {
        url = "/mnt/disk/**";
        run = "noop";
      }
      {
        url = "/mnt/dropbox/**";
        run = "noop";
      }
    ];

    prepend_previewers =
      lib.optionals (lib.hasAttr "piper" enabledPlugins) [
        {
          url = "*.parquet";
          run = ''piper -- duckdb -c "SELECT * FROM read_parquet('$1') LIMIT 50"'';
        }
        {
          url = "*.xlsx";
          run = ''piper -- xlsx2csv "$1" | bat -p --color=always --file-name "$1.csv"'';
        }
        {
          url = "*.json";
          run = ''piper -- bat -p --color=always "$1"'';
        }
        {
          url = "*.sqlite";
          run = ''piper -- duckdb -c "SELECT * FROM sqlite_scan('$1') LIMIT 50"'';
        }
        {
          url = "*.db";
          run = ''piper -- duckdb -c "SELECT * FROM sqlite_scan('$1') LIMIT 50"'';
        }
      ]
      ++ lib.optionals (lib.hasAttr "ouch" enabledPlugins) (
        let
          mimeTypes = [
            "application/gzip"
            "application/x-7z-compressed"
            "application/x-bzip2"
            "application/x-compressed-tar"
            "application/x-gzip"
            "application/x-rar"
            "application/x-tar"
            "application/x-tar+gzip"
            "application/x-xz"
            "application/xz"
            "application/zip"
          ];
        in
        map (mime: {
          inherit mime;
          run = "ouch";
        }) mimeTypes
      )
      ++ lib.optionals (lib.hasAttr "piper" enabledPlugins) [
        {
          url = "*.tar*";
          run = ''piper --format=url -- tar tf "$1"'';
        }
        {
          url = "*.csv";
          run = ''piper -- bat -p --color=always "$1"'';
        }
        {
          url = "*.md";
          run = ''piper -- CLICOLOR_FORCE=1 glow -w=$w -s=dark "$1"'';
        }
        {
          url = "*/";
          run = ''piper -- eza -TL=3 --color=always --icons=always --group-directories-first --no-quotes "$1"'';
        }
      ];
  };
}
