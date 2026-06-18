{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.programs.graphical.browsers.firefox;
  extensionPackages = cfg.extensions.packages ++ cfg.extensions.extraPackages;
  globalExtensions = map (package: {
    inherit package;
    settings.updates_disabled = true;
  }) extensionPackages;
in
{
  options.khanelinix.programs.graphical.browsers.firefox = {
    extensions = {
      installMethod = mkOpt (lib.types.enum [
        "profile"
        "policy"
      ]) "profile" "How to install Firefox extensions.";

      packages = mkOpt (with lib.types; listOf package) (with pkgs.firefox-addons; [
        angular-devtools
        auto-tab-discard
        bitwarden
        # NOTE: annoying new page and permissions
        # bypass-paywalls-clean
        darkreader
        firefox-color
        firenvim
        # Replaced with tampermonkey script
        # frankerfacez
        gitako-github-file-tree
        github-file-icons
        github-issue-link-status
        onepassword-password-manager
        react-devtools
        reduxdevtools
        refined-github
        sponsorblock
        stylus
        tampermonkey
        ublock-origin
        user-agent-string-switcher
      ]) "Extensions to install";

      extraPackages = mkOpt (with lib.types; listOf package) [ ] "Additional extensions to install.";

      settings = mkOpt (with lib.types; attrsOf anything) {
      } "Settings to apply to the extensions.";

      policy = {
        installationMode = mkOpt (lib.types.enum [
          "force_installed"
          "normal_installed"
        ]) "force_installed" "Firefox ExtensionSettings installation mode.";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion =
              cfg.extensions.installMethod != "policy"
              || cfg.extensions.policy.installationMode == "force_installed";
            message = "Firefox native globalExtensions only supports force_installed policy installs.";
          }
        ];

        programs.firefox.profiles.${config.khanelinix.user.name}.extensions = {
          inherit (cfg.extensions) settings;
          force = cfg.extensions.settings != { };
        };
      }

      (lib.mkIf (cfg.extensions.installMethod == "profile") {
        programs.firefox.profiles.${config.khanelinix.user.name}.extensions = {
          packages = extensionPackages;
        };
      })

      (lib.mkIf (cfg.extensions.installMethod == "policy") {
        programs.firefox.globalExtensions = globalExtensions;
      })
    ]
  );
}
