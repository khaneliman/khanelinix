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
      ++ lib.optionals (lib.hasAttr "duckdb" enabledPlugins) (
        let
          multiFileTypes = [
            "csv"
            "tsv"
            "json"
            "parquet"
          ];
          regularFileTypes = [
            "db"
            "duckdb"
          ];
        in
        (map (ext: {
          name = "*.${ext}";
          run = "duckdb";
          multi = false;
        }) multiFileTypes)
        ++ (map (ext: {
          name = "*.${ext}";
          run = "duckdb";
        }) regularFileTypes)
      );

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
      lib.optionals (lib.hasAttr "duckdb" enabledPlugins) (
        let
          fileTypes = [
            "csv"
            "tsv"
            "json"
            "parquet"
          ];
        in
        map (ext: {
          name = "*.${ext}";
          run = "duckdb";
        }) fileTypes
      )
      ++ lib.optional (lib.hasAttr "glow" enabledPlugins) {
        name = "*.md";
        run = "glow";
      }
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
      );

    previewers = [
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
    ];
  };
}
