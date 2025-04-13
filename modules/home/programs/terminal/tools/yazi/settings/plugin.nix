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
          id = "git";
          name = "*";
          run = "git";
        }
        {
          id = "git";
          name = "*/";
          run = "git";
        }
      ]
      ++ lib.optional (lib.hasAttr "mime-ext" enabledPlugins) {
        id = "mime";
        name = "*";
        run = "mime-ext";
        prio = "high";
      };

    prepend_preloaders =
      [
        {
          name = "/mnt/austinserver/**";
          run = "noop";
        }
        {
          name = "/mnt/disk/**";
          run = "noop";
        }
        {
          name = "/mnt/dropbox/**";
          run = "noop";
        }
      ]
      ++ lib.optionals (lib.hasAttr "duckdb" enabledPlugins) [
        {
          name = "*.csv";
          run = "duckdb";
          multi = false;
        }
        {
          name = "*.tsv";
          run = "duckdb";
          multi = false;
        }
        {
          name = "*.json";
          run = "duckdb";
          multi = false;
        }
        {
          name = "*.parquet";
          run = "duckdb";
          multi = false;
        }
        {
          name = "*.db";
          run = "duckdb";
        }
        {
          name = "*.duckdb";
          run = "duckdb";
        }
      ];

    preloaders = [
      # Image
      {
        mime = "image/vnd.djvu";
        run = "noop";
      }
      {
        mime = "image/*";
        run = "image";
      }
      # Video
      {
        mime = "video/*";
        run = "video";
      }
      # PDF
      {
        mime = "application/pdf";
        run = "pdf";
      }
    ];

    prepend_previewers =
      lib.optionals (lib.hasAttr "duckdb" enabledPlugins) [
        {
          name = "*.csv";
          run = "duckdb";
        }
        {
          name = "*.tsv";
          run = "duckdb";
        }
        {
          name = "*.json";
          run = "duckdb";
        }
        {
          name = "*.parquet";
          run = "duckdb";
        }
      ]
      ++ lib.optional (lib.hasAttr "glow" enabledPlugins) {
        name = "*.md";
        run = "glow";
      };

    previewers =
      [
        {
          name = "*/";
          run = "folder";
          sync = true;
        }
        # Code
        {
          mime = "text/*";
          run = "code";
        }
        {
          mime = "*/xml";
          run = "code";
        }
        {
          mime = "*/javascript";
          run = "code";
        }
        {
          mime = "*/wine-extension-ini";
          run = "code";
        }
        # JSON
        {
          mime = "application/json";
          run = "json";
        }
        # Image
        {
          mime = "image/vnd.djvu";
          run = "noop";
        }
        {
          mime = "image/*";
          run = "image";
        }
        # Video
        {
          mime = "video/*";
          run = "video";
        }
        # PDF
        {
          mime = "application/pdf";
          run = "pdf";
        }
        # Archive
        {
          mime = "application/gzip";
          run = "archive";
        }
        # Fallback
        {
          name = "*";
          run = "file";
        }
      ]
      ++ lib.optionals (lib.hasAttr "ouch" enabledPlugins) [
        {
          mime = "application/zip";
          run = "ouch";
        }
        {
          mime = "application/tar";
          run = "ouch";
        }
        {
          mime = "application/bzip";
          run = "ouch";
        }
        {
          mime = "application/bzip2";
          run = "ouch";
        }
        {
          mime = "application/7z-compressed";
          run = "ouch";
        }
        {
          mime = "application/rar";
          run = "ouch";
        }
        {
          mime = "application/xz";
          run = "ouch";
        }
      ];
  };
}
