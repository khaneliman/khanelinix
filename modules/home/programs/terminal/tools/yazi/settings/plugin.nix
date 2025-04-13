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

    prepend_preloaders = [
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
      ++ lib.optional (lib.hasAttr "glow" enabledPlugins) {
        name = "*.md";
        run = "glow";
      }
      ++ lib.optional (lib.hasAttr "miller" enabledPlugins) {
        mime = "*.csv";
        run = "miller";
      }
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
      ]
      ++ lib.optionals (lib.hasAttr "rich-preview" enabledPlugins) [
        {
          mime = "*.csv";
          run = "rich-preview";
        }
        {
          mime = "*.rst";
          run = "rich-preview";
        }
        (lib.mkIf (!lib.hasAttr "glow" enabledPlugins) {
          mime = "*.md";
          run = "rich-preview";
        })
        {
          mime = "*.json";
          run = "rich-preview";
        }
        {
          mime = "*.ipynb";
          run = "rich-preview";
        }
      ];
  };
}
