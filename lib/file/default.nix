{
  inputs,
  self,
}:
let
  inherit (inputs.nixpkgs.lib)
    genAttrs
    filterAttrs
    hasPrefix
    hasSuffix
    filter
    foldl'
    ;

  getNixFiles' =
    path:
    let
      entries = builtins.readDir path;
    in
    filter (name: hasSuffix ".nix" name) (builtins.attrNames entries);

  mergeAttrs' = attrsList: foldl' (acc: attrs: acc // attrs) { } attrsList;
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

  # Get all .nix files from a directory
  # Returns a list of file names (without paths)
  # Usage: getNixFiles ./hooks
  getNixFiles = getNixFiles';

  # Merge a list of attribute sets into a single attribute set
  # Later values override earlier ones
  # Usage: mergeAttrs [ { a = 1; } { b = 2; } { a = 3; } ] => { a = 3; b = 2; }
  mergeAttrs = mergeAttrs';

  # Import all .nix files from a directory
  # Returns a list of imported values
  # Usage: importFiles ./hooks { inherit pkgs; }
  importFiles =
    path: args:
    let
      nixFiles = getNixFiles' path;
    in
    map (name: import (path + "/${name}") args) nixFiles;

  # Import all .nix files from a directory and merge them into a single attribute set
  # Convenience function combining importFiles and mergeAttrs
  # Usage: importDir ./hooks { inherit pkgs; }
  importDir =
    path: args:
    let
      nixFiles = getNixFiles' path;
      imported = map (name: import (path + "/${name}") args) nixFiles;
    in
    mergeAttrs' imported;

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
