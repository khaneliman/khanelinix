{ lib, ... }:
let
  templatesPath = ../../templates;

  scanTemplates =
    dirPath:
    let
      entries = builtins.readDir dirPath;
      templateDirs = lib.filterAttrs (_name: type: type == "directory") entries;
    in
    lib.mapAttrs (name: _: {
      path = dirPath + "/${name}";
      description = "${name} template";
    }) templateDirs;

  allTemplates = scanTemplates templatesPath;
in
{
  flake.templates = lib.mapAttrs (_name: template: {
    inherit (template) path description;
  }) allTemplates;
}
