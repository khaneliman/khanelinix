{
  lib,
  options,
  khanelivimConfiguration,
}:
let
  # Recursively unwrap mkIf/mkMerge/mkOverride module system wrappers
  # to extract actual package values from raw option definitions.
  collectPackages =
    val:
    if builtins.isList val then
      lib.concatMap collectPackages val
    else if (val._type or "") == "if" then
      if val.condition then collectPackages val.content else [ ]
    else if (val._type or "") == "merge" then
      lib.concatMap collectPackages val.contents
    else if (val._type or "") == "override" then
      collectPackages val.content
    else
      [ val ];

  # Avoid infinite recursion by filtering out the definition from this module
  installedPackageNames =
    let
      definitions = options.home.packages.definitionsWithLocations;
      relevantDefinitions = builtins.filter (
        def: !lib.hasSuffix "modules/home/programs/terminal/editors/neovim" (toString def.file)
      ) definitions;
      packages = lib.concatMap (d: collectPackages d.value) relevantDefinitions;
    in
    map lib.getName (builtins.filter lib.isDerivation packages);
in
{
  # For each nixvim dependency, resolve its actual package name and check
  # if it's already installed in home.packages (e.g., dependency key "gemini"
  # maps to package "gemini-cli").
  dependenciesToDisable =
    let
      deps = khanelivimConfiguration.config.dependencies;
    in
    builtins.filter (name: builtins.elem (lib.getName deps.${name}.package) installedPackageNames) (
      builtins.attrNames deps
    );
}
