{ inputs, ... }:
builtins.mapAttrs (_: deployLib: deployLib.deployChecks inputs.self.deploy) inputs.deploy-rs.lib
