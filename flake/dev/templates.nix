{ lib, ... }:
let
  templatesPath = ../../templates;

  scanTemplates =
    path:
    let
      entries = builtins.readDir path;
      templateDirs = lib.filterAttrs (_name: type: type == "directory") entries;
    in
    lib.mapAttrs (name: _: {
      path = path + "/${name}";
      description = "${name} template";
    }) templateDirs;

  allTemplates = scanTemplates templatesPath;
in
{
  flake.templates = lib.mapAttrs (_name: template: {
    inherit (template) path description;
  }) allTemplates;
}
