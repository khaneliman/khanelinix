{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.programs.graphical.browsers.firefox;
in
{
  options.khanelinix.programs.graphical.browsers.firefox = {
    search = mkOpt lib.types.attrs {
      default = "ddg";
      privateDefault = "ddg";
      # Home-manager skip collision check
      force = true;

      engines = {
        "amazondotcom-us".metaData.hidden = true;
        "bing".metaData.hidden = true;
        "google".metaData.hidden = true;
        "ebay".metaData.hidden = true;
        "wikipedia".metaData.hidden = true;

        "NixOs Options" = {
          metaData.hideOneOffButton = true;
          urls = [
            {
              template = "https://search.nixos.org/options";
              params = [
                {
                  name = "channel";
                  value = "unstable";
                }
                {
                  name = "query";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@no" ];
        };

        "Nix Packages" = {
          metaData.hideOneOffButton = true;
          urls = [
            {
              template = "https://search.nixos.org/packages";
              params = [
                {
                  name = "type";
                  value = "packages";
                }
                {
                  name = "query";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@np" ];
        };

        "NixOS Wiki" = {
          metaData.hideOneOffButton = true;
          urls = [ { template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; } ];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@nw" ];
        };

        "Nixvim Options" = {
          metaData.hideOneOffButton = true;
          urls = [
            {
              template = "https://nix-community.github.io/nixvim/NeovimOptions/index.html";
              params = [
                {
                  name = "search";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@nv" ];
        };

        "Noogle" = {
          metaData.hideOneOffButton = true;
          urls = [
            {
              template = "https://noogle.dev/q";
              params = [
                {
                  name = "term";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@ng" ];
        };

        "NüschtOS" = {
          metaData.hideOneOffButton = true;
          urls = [
            {
              template = "https://search.xn--nschtos-n2a.de/";
              params = [
                {
                  name = "query";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@nos" ];
        };

        "Searchix" = {
          metaData.hideOneOffButton = true;
          urls = [
            {
              template = "https://searchix.alanpearce.eu/";
              params = [
                {
                  name = "query";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@sx" ];
        };

      };
    } "Search configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.firefox.profiles.${config.khanelinix.user.name} = {
      inherit (cfg) search;
    };
  };
}
