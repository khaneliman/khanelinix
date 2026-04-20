{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  aliasCompat = import ../alias-compat.nix { inherit lib pkgs; };

  cfg = config.khanelinix.programs.terminal.shell.nushell;
in
{
  options.khanelinix.programs.terminal.shell.nushell = {
    enable = mkEnableOption "nushell";
  };

  config = mkIf cfg.enable {
    programs = {
      nushell = {
        # Nushell documentation
        # See: https://www.nushell.sh/book/
        enable = true;

        extraConfig = ''
          if (($env.NIXPKGS_REVIEW_ROOT? | default "") != "") {
            return
          }
          if (($env.IN_NIX_SHELL? | default "") != "") and (($env.PWD? | default "") | str starts-with $"(($env.XDG_CACHE_HOME? | default $"($env.HOME)/.cache"))/nixpkgs-review/") {
            return
          }
        '';

        shellAliases = lib.mkForce (
          lib.mapAttrs (
            _name: value:
            let
              transformedValue =
                if aliasCompat.isComplexAlias value then
                  aliasCompat.translatedAliasValue value
                else
                  # For simple single-command aliases, apply nushell transformations
                  let
                    # Handle commands that conflict with nushell builtins by prefixing with 'command'
                    # Only replace when these are standalone commands, not parts of paths
                    withCommandPrefix =
                      let
                        # Split on spaces to get words, then selectively replace
                        words = lib.splitString " " value;
                        conflictingCommands = [
                          "cut"
                          "find"
                          "grep"
                          "head"
                          "sort"
                          "tail"
                          "uniq"
                          "watch"
                          "wc"
                        ];
                        transformedWords = map (
                          word: if builtins.elem word conflictingCommands then "command " + word else word
                        ) words;
                      in
                      lib.concatStringsSep " " transformedWords;

                    # Handle environment variables (only for simple aliases)
                    parts = lib.splitString "$" withCommandPrefix;
                    withEnvVars = lib.concatStrings (
                      lib.imap0 (
                        i: part:
                        if i == 0 then
                          part # First part has no $
                        else if lib.hasPrefix "(" part then
                          "$" + part # Preserve $(command)
                        else if builtins.match "^[A-Za-z_][A-Za-z0-9_]*.*" part != null then
                          "$env." + part
                        else
                          "$" + part
                      ) parts
                    );
                  in
                  withEnvVars;
            in
            transformedValue
          ) config.home.shellAliases
        );
      };
    };
  };
}
