{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.programs.graphical.browsers.firefox;
  extensionSettings = builtins.listToAttrs (
    map (
      package:
      let
        inherit (package) addonId;
      in
      {
        name = addonId;
        value = {
          installation_mode = cfg.extensions.policy.installationMode;
          install_url = "file://${package}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${addonId}.xpi";
          updates_disabled = true;
        };
      }
    ) cfg.extensions.packages
  );
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

      settings = mkOpt (with lib.types; attrsOf anything) {
      } "Settings to apply to the extensions.";

      policy = {
        installationMode = mkOpt (lib.types.enum [
          "force_installed"
          "normal_installed"
        ]) "normal_installed" "Firefox ExtensionSettings installation mode.";
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
              || builtins.all (package: package ? addonId) cfg.extensions.packages;
            message = "Firefox ExtensionSettings installs require every extension package to expose addonId.";
          }
        ];

        programs.firefox.profiles.${config.khanelinix.user.name}.extensions = {
          inherit (cfg.extensions) settings;
          force = cfg.extensions.settings != { };
        };
      }

      (lib.mkIf (cfg.extensions.installMethod == "profile") {
        programs.firefox.profiles.${config.khanelinix.user.name}.extensions = {
          inherit (cfg.extensions) packages;
        };
      })

      (lib.mkIf (cfg.extensions.installMethod == "policy") {
        home.packages = cfg.extensions.packages;

        programs.firefox.policies.ExtensionSettings = extensionSettings;
      })
    ]
  );
}
