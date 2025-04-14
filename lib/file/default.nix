{
  lib,
  root,
  ...
}:
let
  inherit (builtins) readDir pathExists;
  inherit (lib)
    filterAttrs
    mapAttrsToList
    ;

  fileNameRegex = "(.*)\\.(.*)$";
in
rec {
  fileWithText = file: text: ''
    ${builtins.readFile file}
    ${text}'';

  fileWithText' = file: text: ''
    ${text}
    ${builtins.readFile file}'';

  hasAnyFileExtension =
    file:
    let
      match = builtins.match fileNameRegex (toString file);
    in
    match != null;

  getFileExtension =
    file:
    if hasAnyFileExtension file then
      let
        match = builtins.match fileNameRegex (toString file);
      in
      lib.last match
    else
      "";

  hasFileExtension =
    extension: file: if hasAnyFileExtension file then extension == getFileExtension file else false;

  # Convert a store path back to a source path
  sourcePathFromStorePath =
    path:
    let
      pathStr = toString path;
      # Match the nix store path pattern and extract the path after the hash
      match = builtins.match "/nix/store/[a-z0-9]+-source(.*)" pathStr;
    in
    if match != null then builtins.head match else pathStr;

  # Convert a store path to a relative path by removing the root prefix
  makeRelative =
    path:
    let
      pathStr = toString path;
      rootStr = toString root;
      sourcePath = sourcePathFromStorePath pathStr;
    in
    if lib.hasPrefix rootStr sourcePath then lib.removePrefix "${rootStr}/" sourcePath else sourcePath;

  getFile = path: "${root}/${path}";

  # Function equivalent to snowfall-lib's get-files
  getFilesList =
    dir:
    let
      actualPath = if lib.hasPrefix "/" (toString dir) then toString dir else "${root}/${dir}";
      entries = safeReadDirectory actualPath;
      filteredEntries = filterAttrs (_name: kind: kind == "regular") entries;
    in
    mapAttrsToList (name: _kind: "${actualPath}/${name}") filteredEntries;

  safeReadDirectory = path: if pathExists path then readDir path else { };

  getDirectories =
    path:
    let
      entries = safeReadDirectory path;
      filteredEntries = filterAttrs (_name: kind: kind == "directory") entries;
    in
    mapAttrsToList (name: _kind: "${path}/${name}") filteredEntries;

  getFiles =
    path:
    let
      entries = safeReadDirectory path;
      filteredEntries = filterAttrs (_name: kind: kind == "regular") entries;
    in
    mapAttrsToList (name: _kind: makeRelative "${path}/${name}") filteredEntries;
  getFilesRecursive =
    path:
    let
      actualPath = sourcePathFromStorePath path;
      entries = safeReadDirectory actualPath;
      filteredEntries = filterAttrs (_: kind: (kind == "regular") || (kind == "directory")) entries;
      mapFile =
        name: kind:
        let
          path' = "${actualPath}/${name}";
        in
        if kind == "directory" then getFilesRecursive path' else makeRelative path';
    in
    lib.flatten (mapAttrsToList mapFile filteredEntries);

  getNixFiles = path: builtins.filter (hasFileExtension "nix") (getFiles path);

  getNixFilesRecursive = path: builtins.filter (hasFileExtension "nix") (getFilesRecursive path);

  getDefaultNixFiles =
    path: builtins.filter (name: builtins.baseNameOf name == "default.nix") (getFiles path);

  getDefaultNixFilesRecursive =
    path:
    let
      allFiles = getFilesRecursive path;
      # Ignore the top-level default.nix
      topLevelDefaultNix = "${makeRelative path}/default.nix";
    in
    builtins.filter (
      name: (builtins.baseNameOf name == "default.nix") && (name != topLevelDefaultNix)
    ) allFiles;
}
