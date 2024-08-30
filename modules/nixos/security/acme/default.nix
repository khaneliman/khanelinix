{
  config,
  lib,
  virtual,
  namespace,
  ...
}:
let
  inherit (lib)
    mkIf
    optional
    types
    ;
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.security.acme;
in
{
  options.${namespace}.security.acme = {
    enable = lib.mkEnableOption "default ACME configuration";
    email = mkOpt types.str config.${namespace}.user.email "The email to use.";
    staging = mkOpt types.bool virtual "Whether to use the staging server or not.";
  };

  config = mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;

      defaults = {
        inherit (cfg) email;

        group = mkIf config.services.nginx.enable "nginx";
        # Reload nginx when certs change.
        reloadServices = optional config.services.nginx.enable "nginx.service";
        server = mkIf cfg.staging "https://acme-staging-v02.api.letsencrypt.org/directory";
      };
    };
  };
}
