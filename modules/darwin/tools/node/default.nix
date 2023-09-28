{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.tools.node;
in
{
  options.khanelinix.tools.node = with types; {
    enable = mkBoolOpt false "Whether or not to install and configure git";
    flyctl = {
      enable = mkBoolOpt true "Whether or not to install flyctl";
      pkg = mkOpt package pkgs.flyctl "The flyctl package to use";
    };
    pkg = mkOpt package pkgs.nodejs-18_x "The NodeJS package to use";
    pnpm = {
      enable = mkBoolOpt true "Whether or not to install Pnpm";
      pkg = mkOpt package pkgs.nodePackages.pnpm "The NodeJS package to use";
    };
    prettier = {
      enable = mkBoolOpt true "Whether or not to install Prettier";
      pkg =
        mkOpt package pkgs.nodePackages.prettier "The NodeJS package to use";
    };
    yarn = {
      enable = mkBoolOpt true "Whether or not to install Yarn";
      pkg = mkOpt package pkgs.nodePackages.yarn "The NodeJS package to use";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      [ cfg.pkg ]
      ++ (lib.optional cfg.flyctl.enable cfg.flyctl.pkg)
      ++ (lib.optional cfg.pnpm.enable cfg.pnpm.pkg)
      ++ (lib.optional cfg.prettier.enable cfg.prettier.pkg)
      ++ (lib.optional cfg.yarn.enable cfg.yarn.pkg);
  };
}
