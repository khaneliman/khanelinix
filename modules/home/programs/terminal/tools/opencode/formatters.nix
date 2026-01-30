# OpenCode formatters configuration module
# Defines code formatters for different programming languages
{ lib, pkgs, ... }:
{
  config = {
    programs.opencode.settings.formatter = {
      nixfmt = {
        command = [
          (lib.getExe pkgs.nixfmt)
          "$FILE"
        ];
        extensions = [ ".nix" ];
      };

      csharpier = {
        command = [
          (lib.getExe pkgs.csharpier)
          "$FILE"
        ];
        extensions = [
          ".cs"
        ];
      };

      rustfmt = {
        command = [
          (lib.getExe pkgs.rustfmt)
          "$FILE"
        ];
        extensions = [ ".rs" ];
      };
    };
  };
}
