{ self, inputs, ... }:
let
  templatesDir = ../templates;
  templates = builtins.attrNames (builtins.readDir templatesDir);
  generateTemplate = name: {
    description = "${name} template";
    path = "${templatesDir}/${name}";
  };
in
{
  flake.templates = builtins.listToAttrs (
    map (name: {
      name = name;
      value = generateTemplate name;
    }) templates
  );

  # The following adds the template flake's checks to the main (current) flake's checks.
  # It ensures that the template's own checks are successful.
  perSystem =
    {
      system,
      lib,
      ...
    }:
    {
      checks =
        let
          callFlake =
            args@{
              inputs,
              outputs,
            }:
            let
              result = {
                outputs = args.outputs (inputs // { self = result; });
              };
            in
            result;

          templateFlakeOutputs = map (
            template:
            callFlake {
              inputs = {
                inherit (inputs) flake-parts nixpkgs;
              };
              # Import and read the `outputs` field of the template flake.
              outputs = import (templatesDir + "/${template}/flake.nix");
              sourceInfo = { };
            }
          ) templates;

          templateChecks = lib.concatMap (
            templateOutput: templateOutput.checks.${system} or [ ]
          ) templateFlakeOutputs;
        in
        lib.listToAttrs (
          map (check: {
            name = "template-${check.name}";
            value = check;
          }) templateChecks
        );
    };
}
