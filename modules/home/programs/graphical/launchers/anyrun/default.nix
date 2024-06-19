{
  config,
  inputs,
  pkgs,
  lib,
  namespace,
  system,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) compileSCSS mkBoolOpt;
  inherit (inputs) anyrun anyrun-nixos-options;

  cfg = config.${namespace}.programs.graphical.launchers.anyrun;
in
{
  options.${namespace}.programs.graphical.launchers.anyrun = {
    enable = mkBoolOpt false "Whether to enable anyrun in the desktop environment.";
  };

  config = mkIf cfg.enable {
    programs.anyrun = {
      enable = true;
      config = {
        plugins = with anyrun.packages.${system}; [
          applications
          dictionary
          rink
          shell
          symbols
          stdin
          translate
          websearch

          anyrun-nixos-options.packages.${system}.default
        ];

        # the x coordinate of the runner
        #x.relative = 800;
        # the y coordinate of the runner
        #y.absolute = 500.0;
        y.fraction = 2.0e-2;

        # Hide match and plugin info icons
        hideIcons = false;

        # ignore exclusive zones, i.e. Waybar
        ignoreExclusiveZones = false;

        # Layer shell layer: Background, Bottom, Top, Overlay
        layer = "overlay";

        # Hide the plugin info panel
        hidePluginInfo = false;

        # Close window when a click outside the main box is received
        closeOnClick = false;

        # Show search results immediately when Anyrun starts
        showResultsImmediately = false;

        # Limit amount of entries shown in total
        maxEntries = 10;
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
            nixos-options = osConfig.system.build.manual.optionsJSON + "/share/doc/nixos/options.json";
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
            max_entries: 5,
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

      # this compiles the SCSS file from the given path into CSS
      # by default, `-t expanded` as the args to the sass compiler
      extraCss = builtins.readFile (
        compileSCSS pkgs {
          name = "style-dark";
          source = ./styles/dark.scss;
        }
      );
    };
  };
}
