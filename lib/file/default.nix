{
  inputs,
  self,
}:
let
  inherit (inputs.nixpkgs) lib;
  inherit (lib)
    genAttrs
    filterAttrs
    hasPrefix
    hasSuffix
    ;

  getNixFiles' =
    dirPath:
    let
      entries = builtins.readDir dirPath;
    in
    lib.filter (name: hasSuffix ".nix" name) (builtins.attrNames entries);

  mergeAttrs' = attrsList: lib.foldl' (acc: attrs: acc // attrs) { } attrsList;
in
{
  /**
    Read a file and return its contents.

    # Inputs

    `filePath`

    : 1\. Function argument
  */
  readFile = filePath: builtins.readFile filePath;

  /**
    Check if a file exists.

    # Inputs

    `filePath`

    : 1\. Function argument
  */
  pathExists = filePath: builtins.pathExists filePath;

  /**
    Import a nix file with error handling.

    # Inputs

    `filePath`

    : 1\. Function argument

    `default`

    : 2\. Function argument
  */
  safeImport = filePath: default: if builtins.pathExists filePath then import filePath else default;

  /**
    Scan a directory and return directory names.

    # Inputs

    `dirPath`

    : 1\. Function argument
  */
  scanDir = dirPath: builtins.attrNames (builtins.readDir dirPath);

  /**
    Get a file path relative to the flake root.

    # Inputs

    `relativePath`

    : 1\. Function argument
  */
  getFile = relativePath: self + "/${relativePath}";

  /**
    Get all .nix files from a directory.
    Returns a list of file names (without paths).

    # Inputs

    `dirPath`

    : 1\. Function argument
  */
  getNixFiles = getNixFiles';

  /**
    Merge a list of attribute sets into a single attribute set.
    Later values override earlier ones.

    # Inputs

    `attrsList`

    : 1\. Function argument
  */
  mergeAttrs = mergeAttrs';

  /**
    Import all .nix files from a directory.
    Returns a list of imported values.

    # Inputs

    `dirPath`

    : 1\. Function argument

    `args`

    : 2\. Function argument
  */
  importFiles =
    dirPath: args:
    let
      nixFiles = getNixFiles' dirPath;
    in
    map (name: import (dirPath + "/${name}") args) nixFiles;

  /**
    Import all .nix files from a directory and merge them into a single attribute set.
    Convenience function combining importFiles and mergeAttrs.

    # Inputs

    `dirPath`

    : 1\. Function argument

    `args`

    : 2\. Function argument
  */
  importDir =
    dirPath: args:
    let
      nixFiles = getNixFiles' dirPath;
      imported = map (name: import (dirPath + "/${name}") args) nixFiles;
    in
    mergeAttrs' imported;

  /**
    Import all .nix files from a directory without passing args.
    For files that are plain attribute sets (not functions).

    # Inputs

    `dirPath`

    : 1\. Function argument

    `exclude`

    : 2\. Function argument
  */
  importDirPlain =
    dirPath: exclude:
    let
      excludeList = if builtins.isList exclude then exclude else [ ];
      nixFiles = lib.filter (name: !(builtins.elem name excludeList)) (getNixFiles' dirPath);
    in
    mergeAttrs' (map (name: import (dirPath + "/${name}")) nixFiles);

  /**
    Import all .nix files from all subdirectories, merging results.
    Useful for organizing related files in subdirs.

    # Inputs

    `dirPath`

    : 1\. Function argument

    `exclude`

    : Optional exclude list

    `args`

    : Optional arguments to pass to imports
  */
  importSubdirs =
    dirPath:
    {
      exclude ? [ ],
      args ? null,
    }:
    let
      entries = builtins.readDir dirPath;
      subdirs = lib.filter (name: entries.${name} == "directory") (builtins.attrNames entries);
      importSubdir =
        dir:
        let
          subDirPath = dirPath + "/${dir}";
          files = lib.filter (f: !(builtins.elem f exclude)) (getNixFiles' subDirPath);
          importFile =
            f: if args == null then import (subDirPath + "/${f}") else import (subDirPath + "/${f}") args;
        in
        mergeAttrs' (map importFile files);
    in
    mergeAttrs' (map importSubdir subdirs);

  /**
    Recursively discover and import all Nix modules in a directory tree.

    # Inputs

    `dirPath`

    : 1\. Function argument
  */
  importModulesRecursive =
    dirPath:
    let
      # Helper function to recursively walk directories
      walkDir =
        currentPath:
        let
          currentEntries = builtins.readDir currentPath;
          entryNames = builtins.attrNames currentEntries;

          # Get all directories that contain default.nix
          directoriesWithDefault = lib.filter (
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
    walkDir dirPath;

  /**
    Recursively parse systems directory structure.

    # Inputs

    `systemsPath`

    : 1\. Function argument
  */
  parseSystemConfigurations =
    systemsPath:
    let
      entries = builtins.readDir systemsPath;
      systemArchs = lib.filter (name: entries.${name} == "directory") (builtins.attrNames entries);

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
    builtins.foldl' (acc: system: acc // generateSystemConfigs system) { } systemArchs;

  /**
    Filter systems for NixOS (Linux).

    # Inputs

    `systems`

    : 1\. Function argument
  */
  filterNixOSSystems =
    systems:
    filterAttrs (
      _name: { system, ... }: hasPrefix "x86_64-linux" system || hasPrefix "aarch64-linux" system
    ) systems;

  /**
    Filter systems for Darwin (macOS).

    # Inputs

    `systems`

    : 1\. Function argument
  */
  filterDarwinSystems =
    systems:
    filterAttrs (
      _name: { system, ... }: hasPrefix "aarch64-darwin" system || hasPrefix "x86_64-darwin" system
    ) systems;

  /**
    Parse homes directory structure for home configurations.

    # Inputs

    `homesPath`

    : 1\. Function argument
  */
  parseHomeConfigurations =
    homesPath:
    let
      entries = builtins.readDir homesPath;
      systemArchs = lib.filter (name: entries.${name} == "directory") (builtins.attrNames entries);

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
    builtins.foldl' (acc: system: acc // generateHomeConfigs system) { } systemArchs;
}
