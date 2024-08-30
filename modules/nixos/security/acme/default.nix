{
  config,
  lib,
  virtual,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.security.acme;
in
{
  options.${namespace}.security.acme = {
    enable = lib.mkEnableOption "default ACME configuration";
    email = mkOpt lib.types.str config.${namespace}.user.email "The email to use.";
    staging = mkOpt lib.types.bool virtual "Whether to use the staging server or not.";
  };

  config = lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;

      defaults = {
        inherit (cfg) email;

        group = lib.mkIf config.services.nginx.enable "nginx";
        # Reload nginx when certs change.
        reloadServices = lib.optional config.services.nginx.enable "nginx.service";
        server = lib.mkIf cfg.staging "https://acme-staging-v02.api.letsencrypt.org/directory";
      };
    };
  };
}
