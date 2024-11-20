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
      pkgs,
      system,
      lib,
      ...
    }:
    {
      checks =
        let
          # Approximates https://github.com/NixOS/nix/blob/7cd08ae379746749506f2e33c3baeb49b58299b8/src/libexpr/flake/call-flake.nix#L46
          # s/flake.outputs/args.outputs/
          callFlake =
            args@{
              inputs,
              outputs,
              sourceInfo,
            }:
            let
              outputs = args.outputs (inputs // { self = result; });
              result =
                outputs
                // sourceInfo
                // {
                  inherit inputs outputs sourceInfo;
                  _type = "flake";
                };
            in
            result;

          templateFlakeOutputs = map (
            template:
            callFlake {
              inputs = {
                inherit (inputs) flake-parts nixpkgs;
                nixvim = self;
              };
              # Import and read the `outputs` field of the template flake.
              inherit (import (templatesDir + "/${template}/flake.nix")) outputs;
              sourceInfo = { };
            }
          ) templates;

          templateChecks = lib.concatMap (
            templateOutput: templateOutput.checks.${system}
          ) templateFlakeOutputs;
        in
        lib.concatMapAttrs (checkName: check: { "template-${checkName}" = check; }) templateChecks;
    };
}
