{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib)
    types
    concatStringsSep
    mapAttrsToList
    mkOption
    mapAttrs
    ;

  pagerArgs = [
    "--RAW-CONTROL-CHARS" # Only allow colors.
    "--wheel-lines=5"
    "--LONG-PROMPT"
    "--no-vbell"
    " --wordwrap" # Wrap lines at spaces.
  ];

  cfg = config.${namespace}.system.env;
in
{
  options.${namespace}.system.env =
    with types;
    mkOption {
      apply = mapAttrs (_n: v: if isList v then concatMapStringsSep ":" toString v else (toString v));
      default = { };
      description = "A set of environment variables to set.";
      type = attrsOf (oneOf [
        str
        path
        (listOf (either str path))
      ]);
    };

  config = {
    environment = {
      sessionVariables = {
        XDG_BIN_HOME = "$HOME/.local/bin";
        XDG_CACHE_HOME = "$HOME/.cache";
        XDG_CONFIG_HOME = "$HOME/.config";
        XDG_DATA_HOME = "$HOME/.local/share";
        XDG_DESKTOP_DIR = "$HOME";
      };

      extraInit = concatStringsSep "\n" (
        mapAttrsToList (
          n: v: # bash
          ''
            export ${n}="${v}"
          '') cfg
      );

      pathsToLink = [
        "/share/zsh" # zsh completions
        "/share/bash-completion" # bash completions
        "/share/nix-direnv" # direnv completions
      ];

      variables = {
        # Make some programs "XDG" compliant.
        LESSHISTFILE = "$XDG_CACHE_HOME/less.history";
        WGETRC = "$XDG_CONFIG_HOME/wgetrc";

        MANPAGER = "nvim -c 'set ft=man bt=nowrite noswapfile nobk shada=\\\"NONE\\\" ro noma' +Man! -o -";
        SYSTEMD_PAGERSECURE = "true";
        PAGER = "less -FR";
        LESS = concatStringsSep " " pagerArgs;
        SYSTEMD_LESS = concatStringsSep " " (
          pagerArgs
          ++ [
            "--quit-if-one-screen"
            "--chop-long-lines"
            "--no-init" # Keep content after quit.
          ]
        );
      };
    };
  };
}
