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
          url = "local://*";
          run = "git";
        }
        {
          group = "git";
          url = "local://*/";
          run = "git";
        }
      ]
      ++ lib.optional (lib.hasAttr "mime-ext" enabledPlugins) {
        group = "mime";
        url = "local://*";
        run = "mime-ext";
        prio = "high";
      };

    prepend_preloaders = [
      {
        url = "local:///mnt/austinserver/**";
        run = "noop";
      }
      {
        url = "local:///Volumes/austinserver/**";
        run = "noop";
      }
      {
        url = "local:///mnt/disk/**";
        run = "noop";
      }
      {
        url = "local:///mnt/dropbox/**";
        run = "noop";
      }
    ]
    ++ lib.optional (lib.hasAttr "duckdb" enabledPlugins) {
      url = "local://*.{csv,tsv,parquet}";
      run = "duckdb";
    };

    prepend_previewers =
      lib.optionals (lib.hasAttr "piper" enabledPlugins) [
        {
          url = "local://*";
          mime = "application/sqlite3";
          run = ''piper -- sqlite3 -readonly -init /dev/null "$1" '.schema --indent' | bat -p --color=always -l sql'';
        }
        {
          url = "local://*.{sqlite,sqlite3}";
          run = ''piper -- sqlite3 -readonly -init /dev/null "$1" '.schema --indent' | bat -p --color=always -l sql'';
        }
        {
          url = "local://*.xlsx";
          run = ''piper -- xlsx2csv "$1" | bat -p --color=always --file-name "$1.csv"'';
        }
        {
          url = "local://*.md";
          run = ''piper -- CLICOLOR_FORCE=1 glow -w="$w" -s="$t" "$1"'';
        }
      ]
      ++ lib.optional (lib.hasAttr "duckdb" enabledPlugins) {
        url = "local://*.{csv,tsv,parquet,duckdb,db}";
        run = "duckdb";
      };
  };
}
