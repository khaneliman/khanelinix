{
  plugin = {
    prepend_fetchers = [
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
      {
        id = "mime";
        name = "*";
        run = "mime-ext";
        prio = "high";
      }
    ];

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

    previewers = [
      {
        name = "*.md";
        run = "glow";
      }
      {
        mime = "text/csv";
        run = "miller";
      }
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
        mime = "application/zip";
        run = "ouch";
      }
      {
        mime = "application/gzip";
        run = "archive";
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
      # Fallback
      {
        name = "*";
        run = "file";
      }
    ];
  };
}
