{
  inputs,
  self,
}:
let
  inherit (inputs.nixpkgs.lib)
    genAttrs
    filterAttrs
    hasPrefix
    foldl'
    ;
in
{
  # Read a file and return its contents
  readFile = path: builtins.readFile path;

  # Check if a file exists
  pathExists = path: builtins.pathExists path;

  # Import a nix file with error handling
  safeImport = path: default: if builtins.pathExists path then import path else default;

  # Scan a directory and return directory names
  scanDir = path: builtins.attrNames (builtins.readDir path);

  # Get a file path relative to the flake root (similar to Snowfall's get-file)
  getFile = relativePath: self + "/${relativePath}";

  # Recursively discover and import all Nix modules in a directory tree
  importModulesRecursive =
    path:
    let
      # Helper function to recursively walk directories
      walkDir =
        currentPath:
        let
          currentEntries = builtins.readDir currentPath;
          entryNames = builtins.attrNames currentEntries;

          # Get all directories that contain default.nix
          directoriesWithDefault = builtins.filter (
            name:
            currentEntries.${name} == "directory" && builtins.pathExists (currentPath + "/${name}/default.nix")
          ) entryNames;

          # Get ALL directories (to recurse into)
          allDirectories = builtins.filter (name: currentEntries.${name} == "directory") entryNames;

          # Import directories that have default.nix
          directoryImports = map (name: currentPath + "/${name}") directoriesWithDefault;

          # Recursively walk ALL subdirectories
          subDirImports = builtins.concatLists (map (dir: walkDir (currentPath + "/${dir}")) allDirectories);

        in
        directoryImports ++ subDirImports;

    in
    walkDir path;

  # Recursively parse systems directory structure
  parseSystemConfigurations =
    systemsPath:
    let
      systemArchs = builtins.attrNames (builtins.readDir systemsPath);

      generateSystemConfigs =
        system:
        let
          systemPath = systemsPath + "/${system}";
          hosts = builtins.attrNames (builtins.readDir systemPath);
        in
        genAttrs hosts (hostname: {
          inherit system hostname;
          path = systemPath + "/${hostname}";
        });
    in
    foldl' (acc: system: acc // generateSystemConfigs system) { } systemArchs;

  # Filter systems for NixOS (Linux)
  filterNixOSSystems =
    systems:
    filterAttrs (
      _name: { system, ... }: hasPrefix "x86_64-linux" system || hasPrefix "aarch64-linux" system
    ) systems;

  # Filter systems for Darwin (macOS)
  filterDarwinSystems =
    systems:
    filterAttrs (
      _name: { system, ... }: hasPrefix "aarch64-darwin" system || hasPrefix "x86_64-darwin" system
    ) systems;

  # Parse homes directory structure for home configurations
  parseHomeConfigurations =
    homesPath:
    let
      systemArchs = builtins.attrNames (builtins.readDir homesPath);

      generateHomeConfigs =
        system:
        let
          systemPath = homesPath + "/${system}";
          userAtHosts = builtins.attrNames (builtins.readDir systemPath);

          parseUserAtHost =
            userAtHost:
            let
              # Split "username@hostname" into parts
              parts = builtins.split "@" userAtHost;
              username = builtins.head parts;
              hostname = builtins.elemAt parts 2; # After split: [username, "@", hostname]
            in
            {
              inherit
                system
                username
                hostname
                userAtHost
                ;
              path = systemPath + "/${userAtHost}";
            };
        in
        genAttrs userAtHosts parseUserAtHost;
    in
    foldl' (acc: system: acc // generateHomeConfigs system) { } systemArchs;
}
