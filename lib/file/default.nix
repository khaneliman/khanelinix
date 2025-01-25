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

  getFile = path: "${root}/${path}";

  safeReadDirectory = path: if pathExists path then readDir path else { };

  getDirectories =
    path:
    let
      entries = safeReadDirectory path;
      filteredEntries = filterAttrs (name: kind: kind == "directory") entries;
    in
    mapAttrsToList (name: kind: "${path}/${name}") filteredEntries;

  getFiles =
    path:
    let
      entries = safeReadDirectory path;
      filteredEntries = filterAttrs (name: kind: kind == "regular") entries;
    in
    mapAttrsToList (name: kind: "${path}/${name}") filteredEntries;
  get-files-recursive =
    path:
    let
      entries = safeReadDirectory path;
      filtered-entries = filterAttrs (name: kind: (kind == "file") || (kind == "directory")) entries;
      map-file =
        name: kind:
        let
          path' = "${path}/${name}";
        in
        if kind == "directory" then get-files-recursive path' else path';
      files = lib.flatten (mapAttrsToList map-file filtered-entries);
    in
    files;

  getFilesRecursive =
    path:
    let
      entries = safeReadDirectory path;
      filteredEntries = filterAttrs (_: kind: (kind == "regular") || (kind == "directory")) entries;
      mapFile =
        name: kind:
        let
          path' = "${path}/${name}";
        in
        if kind == "directory" then getFilesRecursive path' else path';
    in
    lib.flatten (mapAttrsToList mapFile filteredEntries);

  getNixFiles = path: builtins.filter (hasFileExtension "nix") (getFiles path);

  getNixFilesRecursive = path: builtins.filter (hasFileExtension "nix") (getFilesRecursive path);

  getDefaultNixFiles =
    path: builtins.filter (name: builtins.baseNameOf name == "default.nix") (getFiles path);

  getDefaultNixFilesRecursive =
    path: builtins.filter (name: builtins.baseNameOf name == "default.nix") (getFilesRecursive path);
}
