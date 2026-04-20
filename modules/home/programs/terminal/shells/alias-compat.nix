{ lib, pkgs }:
let
  bashExe = lib.getExe pkgs.bash;

  inherit (lib) trim;
  positionalIndexes = [
    "1"
    "2"
    "3"
    "4"
    "5"
    "6"
    "7"
    "8"
    "9"
  ];

  hasPositionalParams =
    value:
    let
      trimmed = trim value;
    in
    lib.any (token: lib.hasInfix token trimmed) [
      "$@"
      "$*"
      "$1"
      "$2"
      "$3"
      "$4"
      "$5"
      "$6"
      "$7"
      "$8"
      "$9"
    ];

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

  hasLeadingEnvAssignment = value: builtins.match "^[A-Z_][A-Z0-9_]*=.*" (trim value) != null;

  hasSingleQuote = value: lib.hasInfix "'" (trim value);

  isComplexAlias =
    value:
    let
      trimmed = trim value;
    in
    lib.hasInfix "\n" trimmed
    || lib.hasInfix "$(" trimmed
    || lib.hasInfix "&&" trimmed
    || lib.hasInfix "||" trimmed
    || hasLeadingEnvAssignment trimmed
    || hasWrappedFunction trimmed
    || hasPositionalParams trimmed;

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
    else if lib.hasInfix "\n" trimmed || lib.hasInfix "&&" trimmed || lib.hasInfix "||" trimmed then
      trimmed
    else
      "${trimmed} \"$@\"";

  wrappedAliasValue = value: "${bashExe} -c ${lib.escapeShellArg (bashScriptForAlias value)} --";

  translatedAliasValue = value: if isComplexAlias value then wrappedAliasValue value else value;

  replaceFishArgs =
    value:
    let
      quotedArgs = [
        "\"$@\""
        "\"$*\""
      ];
      quotedArgv = [
        "$argv"
        "$argv"
      ];
      quotedPositionals = map (index: "\"$" + index + "\"") positionalIndexes;
      fishPositionals = map (index: "$argv[${index}]") positionalIndexes;
      bareArgs = [
        "$@"
        "$*"
      ];
      bareArgv = [
        "$argv"
        "$argv"
      ];
      barePositionals = map (index: "$" + index) positionalIndexes;
    in
    lib.replaceStrings (quotedArgs ++ quotedPositionals ++ bareArgs ++ barePositionals) (
      quotedArgv ++ fishPositionals ++ bareArgv ++ fishPositionals
    ) value;

  translateFishCommand =
    command:
    let
      translatedArgs = replaceFishArgs command;
      translatedSubs = lib.replaceStrings [ "$(" ] [ "(" ] translatedArgs;
      restoredAwkFields = lib.replaceStrings (map (index: "{print $argv[${index}]}") positionalIndexes) (
        map
        (index: "{print $" + index + "}")
        positionalIndexes
      ) translatedSubs;
    in
    lib.replaceStrings [ " && " " || " ] [ "\nand " "\nor " ] restoredAwkFields;

  translateFishLine =
    line:
    let
      trimmed = trim line;
      assignmentMatch = builtins.match "^([A-Za-z_][A-Za-z0-9_]*)=\\$\\((.*)\\)$" trimmed;
      forLoopMatch = builtins.match "^for ([A-Za-z_][A-Za-z0-9_]*) in \\$\\((.*)\\); do$" trimmed;
      nixConfigPrefix = "NIX_CONFIG=$'max-jobs = auto\\ncores = 0' ";
      envMatch = builtins.match "^([A-Z_][A-Z0-9_]*)=([^[:space:]]+) (.*)$" trimmed;
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
      "set ${variable} (" + translateFishCommand command + ")"
    else if forLoopMatch != null then
      let
        variable = builtins.elemAt forLoopMatch 0;
        command = builtins.elemAt forLoopMatch 1;
      in
      "for ${variable} in (" + translateFishCommand command + ")"
    else if trimmed == "done" then
      "end"
    else if lib.hasPrefix nixConfigPrefix trimmed then
      let
        command = lib.removePrefix nixConfigPrefix trimmed;
      in
      ''
        set -lx NIX_CONFIG "max-jobs = auto
        cores = 0"
        ${translateFishCommand command}
      ''
    else if envMatch != null then
      let
        variable = builtins.elemAt envMatch 0;
        value = builtins.elemAt envMatch 1;
        command = builtins.elemAt envMatch 2;
      in
      ''
        set -lx ${variable} ${value}
        ${translateFishCommand command}
      ''
    else
      translateFishCommand trimmed;

  fishBodyForAlias =
    name: value:
    let
      trimmed = trim value;
      body = if hasWrappedFunction trimmed then unwrapFunctionBody trimmed else trimmed;
      fishSessionVarsPath =
        lib.replaceStrings
          [ "__HM_ZSH_SESS_VARS_SOURCED=0 source " "hm-session-vars.sh" ]
          [ "" "hm-session-vars.fish" ]
          trimmed;
    in
    if name == "hmvar-reload" then
      ''
        if test -f ${fishSessionVarsPath}
          source ${fishSessionVarsPath}
        end
      ''
    else
      lib.concatMapStringsSep "\n" translateFishLine (lib.splitString "\n" body);

in
{
  inherit
    fishBodyForAlias
    isComplexAlias
    isFishFunctionAlias
    translatedAliasValue
    ;

  translateAliasMap = lib.mapAttrs (_: translatedAliasValue);
  translateFishAliasMap = aliases: lib.filterAttrs (_: value: !(isFishFunctionAlias value)) aliases;
  translateFishFunctions =
    aliases:
    lib.mapAttrs' (
      name: value:
      lib.nameValuePair name {
        body = fishBodyForAlias name value;
      }
    ) (lib.filterAttrs (_: isFishFunctionAlias) aliases);
}
