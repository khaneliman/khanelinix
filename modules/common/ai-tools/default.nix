{ lib, ... }:

let
  inherit (lib) mapAttrs;

  aiCommands = import ./commands.nix { inherit lib; };
  aiAgents = import ./agents.nix { inherit lib; };
{
  claudeCode = {
    commands = aiCommands;
    agents = aiAgents;
  };
}
