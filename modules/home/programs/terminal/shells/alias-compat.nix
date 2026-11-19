{ lib, pkgs }:
let
  bashExe = lib.getExe pkgs.bash;

  inherit (lib) trim;

  aliasParts =
    value:
    let
      # Operators only count outside quotes; expansions also count inside double quotes.
      tokens = builtins.split ''(\\.)|(\$?'[^']*')|"((\\.|[^"\\])*)"'' value;
      doubleQuoted = lib.concatMap (
        token:
        lib.optionals (builtins.isList token && builtins.elemAt token 2 != null) (
          builtins.filter builtins.isString (builtins.split ''\\.'' (builtins.elemAt token 2))
        )
      ) tokens;
      bare = builtins.filter builtins.isString tokens;
    in
    {
      inherit bare;
      expandable = bare ++ doubleQuoted;
      ansiCQuote = lib.any (
        token:
        builtins.isList token
        && builtins.elemAt token 1 != null
        && lib.hasPrefix "$'" (builtins.elemAt token 1)
      ) tokens;
    };

  hasPositionalParams =
    value:
    lib.any (
      part: builtins.match ''.*\$([@*1-9]|[{]([@*]|[1-9][0-9]*)[}]).*'' part != null
    ) (aliasParts value).expandable;

  hasBareSyntax =
    pattern: value: lib.any (part: builtins.match pattern part != null) (aliasParts value).bare;

  hasChainedCommand = hasBareSyntax ".*(&&|[|][|]).*";
  hasCommandSequence = value: lib.hasInfix "\n" value || hasBareSyntax ".*(;|&&|[|][|]).*" value;

  hasBackticks = value: lib.any (lib.hasInfix "`") (aliasParts value).expandable;
  hasSubstitution = value: lib.any (lib.hasInfix "$(") (aliasParts value).expandable;

  hasWrappedFunction =
    value:
    let
      trimmed = trim value;
    in
    lib.hasPrefix "f(){" trimmed || lib.hasPrefix "f(){ " trimmed;

  unwrapFunctionBody =
    value:
    let
      trimmed = trim value;
      withoutPrefix =
        if lib.hasPrefix "f(){ " trimmed then
          lib.removePrefix "f(){ " trimmed
        else
          lib.removePrefix "f(){" trimmed;
      withoutSuffix =
        if lib.hasSuffix "; }; f" withoutPrefix then
          lib.removeSuffix "; }; f" withoutPrefix
        else if lib.hasSuffix "}; f" withoutPrefix then
          lib.removeSuffix "}; f" withoutPrefix
        else
          withoutPrefix;
    in
    trim withoutSuffix;

  hasLeadingEnvAssignment = value: builtins.match "^[A-Za-z_][A-Za-z0-9_]*=.*" (trim value) != null;

  hasSingleQuote = value: lib.hasInfix "'" (trim value);
  hasBracedExpansion = value: lib.any (lib.hasInfix "\${") (aliasParts value).expandable;
  hasAnsiCQuote = value: (aliasParts value).ansiCQuote;

  needsPosixWrapper =
    value:
    lib.hasInfix "\n" value
    || hasSubstitution value
    || hasChainedCommand value
    || hasLeadingEnvAssignment value
    || hasWrappedFunction value
    || hasPositionalParams value;

  isComplexAlias =
    value:
    let
      trimmed = trim value;
    in
    needsPosixWrapper trimmed
    || hasBackticks trimmed
    || hasAnsiCQuote trimmed
    || hasBracedExpansion trimmed
    || hasBareSyntax ".*[;&|<>].*" trimmed;

  isFishFunctionAlias = value: isComplexAlias value || hasSingleQuote value;

  bashScriptForAlias =
    value:
    let
      trimmed = trim value;
      body = if hasWrappedFunction trimmed then unwrapFunctionBody trimmed else trimmed;
    in
    if hasPositionalParams trimmed || hasWrappedFunction trimmed then
      ''
        f() {
          ${body}
        }
        f "$@"
      ''
    else if hasCommandSequence trimmed || lib.hasSuffix "&" trimmed then
      trimmed
    else
      "${trimmed} \"$@\"";

  wrappedAliasValue = value: "${bashExe} -c ${lib.escapeShellArg (bashScriptForAlias value)} --";

  translatedAliasValue = value: if isComplexAlias value then wrappedAliasValue value else value;

  adaptSharedAliases =
    transform: sharedAliases:
    # Home Manager already merged shared aliases with shell-local aliases.
    lib.mapAttrs (
      name: value: if (sharedAliases.${name} or null) == value then transform name value else value
    );

  adaptPosixAliases = adaptSharedAliases (
    _: value: if needsPosixWrapper (trim value) then wrappedAliasValue value else value
  );

  translateFishLine =
    line:
    let
      trimmed = trim line;
      assignmentMatch = builtins.match "^([A-Za-z_][A-Za-z0-9_]*)=\\$\\((.*)\\)$" trimmed;
      forLoopMatch = builtins.match "^for ([A-Za-z_][A-Za-z0-9_]*) in \\$\\((.*)\\); do$" trimmed;
    in
    if trimmed == "" then
      ""
    else if lib.hasPrefix "#" trimmed then
      trimmed
    else if assignmentMatch != null then
      let
        variable = builtins.elemAt assignmentMatch 0;
        command = builtins.elemAt assignmentMatch 1;
      in
      "set ${variable} (" + command + ")"
    else if forLoopMatch != null then
      let
        variable = builtins.elemAt forLoopMatch 0;
        command = builtins.elemAt forLoopMatch 1;
      in
      "for ${variable} in (" + command + ")"
    else if trimmed == "done" then
      "end"
    else
      trimmed;

  fishBodyForAlias =
    name: value:
    let
      trimmed = trim value;
      sessionVarsPathMatch = builtins.match ".*source \"([^\"]*hm-session-vars\\.sh)\".*" trimmed;
      fishSessionVarsPath =
        if sessionVarsPathMatch != null then
          lib.replaceStrings [ "hm-session-vars.sh" ] [ "hm-session-vars.fish" ] (
            builtins.elemAt sessionVarsPathMatch 0
          )
        else
          lib.replaceStrings
            [ "__HM_ZSH_SESS_VARS_SOURCED=0 source " "hm-session-vars.sh" ]
            [ "" "hm-session-vars.fish" ]
            trimmed;
    in
    if name == "hmvar-reload" then
      ''
        set -e __HM_SESS_VARS_SOURCED
        if test -f ${fishSessionVarsPath}
          source ${fishSessionVarsPath}
        end
      ''
    else if
      hasWrappedFunction trimmed
      || hasBackticks trimmed
      || hasPositionalParams trimmed
      || hasAnsiCQuote trimmed
      || hasBracedExpansion trimmed
    then
      "${wrappedAliasValue value} $argv"
    else
      lib.concatMapStringsSep "\n" translateFishLine (lib.splitString "\n" trimmed)
      + lib.optionalString (
        !hasCommandSequence trimmed && !hasSubstitution trimmed && !(lib.hasSuffix "&" trimmed)
      ) " $argv";

in
{
  inherit
    adaptPosixAliases
    adaptSharedAliases
    fishBodyForAlias
    isComplexAlias
    isFishFunctionAlias
    translatedAliasValue
    ;

  translateAliasMap = lib.mapAttrs (_: translatedAliasValue);
  translateNuComplexAlias = value: "${bashExe} -c ${builtins.toJSON (bashScriptForAlias value)} --";
  filterFishAliases =
    sharedAliases:
    lib.filterAttrs (
      name: value:
      (sharedAliases.${name} or null) != value || (name != "hmvar-reload" && !isFishFunctionAlias value)
    );
  translateFishFunctions =
    aliases:
    lib.mapAttrs' (
      name: value:
      lib.nameValuePair name {
        body = fishBodyForAlias name value;
      }
    ) (lib.filterAttrs (name: value: name == "hmvar-reload" || isFishFunctionAlias value) aliases);
}
