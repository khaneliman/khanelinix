{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.programs.terminal.shell.nushell;
in
{
  options.khanelinix.programs.terminal.shell.nushell = {
    enable = mkEnableOption "nushell";
  };

  config = mkIf cfg.enable {
    programs = {
      nushell = {
        enable = true;

        shellAliases = lib.mkForce (
          lib.mapAttrs (
            _name: value:
            let
              isComplexScript =
                lib.hasInfix "\n" value && (lib.hasInfix "for " value || lib.hasInfix "if " value);
              hasPositionalParams =
                # Check for positional params but exclude awk field references like '{print $1}'
                let
                  hasBasicPositionalParams =
                    lib.hasInfix "$1" value || lib.hasInfix "$2" value || lib.hasInfix "$@" value;
                  isAwkFieldReference = lib.hasInfix "{print $1}" value || lib.hasInfix "'{print $1}'" value;
                in
                hasBasicPositionalParams && !isAwkFieldReference;
              hasMultipleCommands = lib.hasInfix "&&" value || lib.hasInfix "||" value || lib.hasInfix ";" value;

              transformedValue =
                if isComplexScript || hasPositionalParams || hasMultipleCommands then
                  # For complex scripts, wrap in bash -c and preserve original bash syntax
                  let
                    # Remove comment lines that start with # (they cause nushell parsing issues)
                    lines = lib.splitString "\n" value;
                    nonCommentLines = builtins.filter (
                      line:
                      let
                        trimmed = lib.trim line;
                      in
                      trimmed != "" && !lib.hasPrefix "#" trimmed
                    ) lines;
                    cleanScript = lib.concatStringsSep "\n" nonCommentLines;
                  in
                  if hasPositionalParams then
                    # For aliases with positional params, create a bash function wrapper
                    let
                      # Convert the command to a function that accepts arguments
                      functionScript = "f() { " + cleanScript + "; }; f \"$@\"";
                    in
                    "bash -c " + lib.escapeShellArg functionScript + " --"
                  else
                    # Use single quotes but escape any single quotes in the script
                    "bash -c '" + (lib.replaceStrings [ "'" ] [ "'\"'\"'" ] cleanScript) + "'"
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
                        transformedWords = builtins.map (
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
