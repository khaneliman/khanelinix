{ lib, ... }:
let
  inherit (lib) hasSuffix filter foldl';

  # Get all .md files from a directory
  getMarkdownFiles =
    dirPath:
    let
      entries = builtins.readDir dirPath;
    in
    filter (name: hasSuffix ".md" name) (builtins.attrNames entries);

  # Read markdown files from subdirectories and return as attrset
  readMarkdownSubdirs =
    dirPath:
    let
      entries = builtins.readDir dirPath;
      subdirs = filter (name: entries.${name} == "directory") (builtins.attrNames entries);

      readSubdir =
        dir:
        let
          subDirPath = dirPath + "/${dir}";
          files = getMarkdownFiles subDirPath;
          readFile =
            f:
            let
              # Remove .md extension for attribute name
              name = lib.removeSuffix ".md" f;
              content = builtins.readFile (subDirPath + "/${f}");
            in
            {
              ${name} = content;
            };
        in
        foldl' (acc: attrs: acc // attrs) { } (map readFile files);
    in
    foldl' (acc: attrs: acc // attrs) { } (map readSubdir subdirs);
in
readMarkdownSubdirs ./agents
