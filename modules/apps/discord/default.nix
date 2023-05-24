{ options
, config
, lib
, pkgs
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.discord;
  discord = lib.replugged.makeDiscordPlugged {
    inherit pkgs;

    # This is currently broken, but could speed up Discord startup in the future.
    withOpenAsar = false;

    plugins = {
      inherit (inputs) discord-tweaks;
    };

    themes = {
      inherit (inputs) discord-nord-theme;
    };
  };
in
{
  options.khanelinix.apps.discord = with types; {
    enable = mkBoolOpt false "Whether or not to enable Discord.";
    canary.enable = mkBoolOpt false "Whether or not to enable Discord Canary.";
    chromium.enable =
      mkBoolOpt false
        "Whether or not to enable the Chromium version of Discord.";
    firefox.enable =
      mkBoolOpt false
        "Whether or not to enable the Firefox version of Discord.";
    native.enable = mkBoolOpt false "Whether or not to enable the native version of Discord.";
  };

  config = mkIf (cfg.enable or cfg.chromium.enable) {
    khanelinix.home.configFile =
      {
        # TODO: replace with fetch from github catppuccin discord or inline css 
        "BetterDiscord/themes/catppuccin-macchiato.theme.css".text = ''
          /* macchiato */
          @import url("https://catppuccin.github.io/discord/dist/catppuccin-macchiato.theme.css");
        '';
        # "BetterDiscord/data/stable/settings.json".source = inputs.dotfiles.outPath + "/dots/shared/home/.config/BetterDiscord/data/stable/settings.json";
        # "BetterDiscord/data/stable/themes.json".source = inputs.dotfiles.outPath + "/dots/shared/home/.config/BetterDiscord/data/stable/themes.json";
      };

    environment.systemPackages =
      lib.optional cfg.enable discord
      ++ lib.optional cfg.canary.enable pkgs.khanelinix.discord
      ++ lib.optional cfg.chromium.enable pkgs.khanelinix.discord-chromium
      ++ lib.optional cfg.firefox.enable pkgs.khanelinix.discord-firefox
      ++ lib.optional cfg.native.enable pkgs.discord;

    system.userActivationScripts = {
      postInstall = ''
        echo "Running betterdiscord install"
        source ${config.system.build.setEnvironment}
        ${pkgs.betterdiscordctl}/bin/betterdiscordctl install || true 
      '';
    };
  };
}
