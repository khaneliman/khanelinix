{
  config,
  inputs,
  lib,

  pkgs,
  system,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;
  inherit (inputs) anyrun-nixos-options;

  cfg = config.khanelinix.programs.graphical.launchers.anyrun;
in
{
  options.khanelinix.programs.graphical.launchers.anyrun = {
    enable = lib.mkEnableOption "anyrun in the desktop environment";
  };

  config = mkIf cfg.enable {
    programs.anyrun = {
      enable = true;
      package = pkgs.anyrun;
      config = {
        plugins = [
          "${config.programs.anyrun.package}/lib/libapplications.so"
          "${config.programs.anyrun.package}/lib/libdictionary.so"
          "${config.programs.anyrun.package}/lib/librink.so"
          "${config.programs.anyrun.package}/lib/libshell.so"
          "${config.programs.anyrun.package}/lib/libsymbols.so"
          "${config.programs.anyrun.package}/lib/libstdin.so"
          "${config.programs.anyrun.package}/lib/libtranslate.so"
          "${config.programs.anyrun.package}/lib/libwebsearch.so"

          anyrun-nixos-options.packages.${system}.default
        ];

        closeOnClick = false;
        hideIcons = false;
        hidePluginInfo = false;
        ignoreExclusiveZones = false;
        layer = "overlay";
        maxEntries = 10;
        showResultsImmediately = false;
        y.fraction = 2.0e-2;
      };

      extraConfigFiles = {
        "applications.ron".text = ''
          Config(
            // Also show the Desktop Actions defined in the desktop files, e.g. "New Window" from LibreWolf
            desktop_actions: true,
            max_entries: 10,
            // The terminal used for running terminal based desktop entries, if left as `None` a static list of terminals is used
            // to determine what terminal to use.
            terminal: Some("foot"),
          )
        '';

        "nixos-options.ron".text =
          let
            nixos-options =
              (osConfig.system.build.manual.optionsJSON or "/dev/null") + "/share/doc/nixos/options.json";
            options = builtins.toJSON { ":nix" = [ nixos-options ]; };
          in
          ''
            Config(
              options: ${options},
              min_score: 5,
              max_entries: Some(3),
            )
          '';

        "symbols.ron".text = ''
          Config(
            // The prefix that the search needs to begin with to yield symbol results
            prefix: ":sy",

            // Custom user defined symbols to be included along the unicode symbols
            symbols: {
              // "name": "text to be copied"
              "shrug": "¯\\_(ツ)_/¯",
            },

            // The number of entries to be displayed
            max_entries: 10,
          )
        '';

        # NOTE: usage information
        # <prefix><src lang><language_delimiter><target lang> <text to translate>
        # ie: ':trenglish>spanish test this out'
        # <prefix><target lang> <text to translate>
        # ie: ':trspanish test this out'
        "translate.ron".text = ''
          Config(
            prefix: ":tr",
            language_delimiter: ">",
            max_entries: 3,
          )
        '';

        "websearch.ron".text = ''
          Config(
            prefix: "?",
            engines: [DuckDuckGo]
          )
        '';
      };

      extraCss = builtins.readFile ./styles/dark.css;
    };
  };
}
