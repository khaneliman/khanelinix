{ self, inputs, ... }:
{
  flake.templates = {
    default = {
      path = ../templates/simple;
      description = "A simple nix flake template for getting started with nixvim";
    };
    angular = {
      description = "Angular template";
      path = ../templates/angular;
    };
    c = {
      description = "C flake template.";
      path = ../templates/c;
    };
    container = {
      description = "Container template";
      path = ../templates/container;
    };
    cpp = {
      description = "CPP flake template";
      path = ../templates/cpp;
    };
    dotnetf = {
      description = "Dotnet FSharp template";
      path = ../templates/dotnetf;
    };
    flake-compat = {
      description = "Flake-compat shell and default files.";
      path = ../templates/flake-compat;
    };
    go = {
      description = "Go template";
      path = ../templates/go;
    };
    node = {
      description = "Node template";
      path = ../templates/node;
    };
    python = {
      description = "Python template";
      path = ../templates/python;
    };
    rust = {
      description = "Rust template";
      path = ../templates/rust;
    };
    rust-web-server = {
      description = "Rust web server template";
      path = ../templates/rust-web-server;
    };
    snowfall = {
      description = "Snowfall-lib template";
      path = ../templates/snowfall;
    };
  };

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

          templateFlakeOutputs = callFlake {
            inputs = {
              inherit (inputs) flake-parts nixpkgs;
              nixvim = self;
            };
            # Import and read the `outputs` field of the template flake.
            inherit (import ../templates/simple/flake.nix) outputs;
            sourceInfo = { };
          };

          templateChecks = templateFlakeOutputs.checks.${system};
        in
        lib.concatMapAttrs (checkName: check: { "template-${checkName}" = check; }) templateChecks;
    };
}
