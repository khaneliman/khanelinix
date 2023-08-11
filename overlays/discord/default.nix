{ ... }: _final: prev: {
  khanelinix =
    (prev.khanelinix or { })
    // {
      discord-firefox = with prev;
        makeDesktopItem {
          name = "Discord (firefox)";
          desktopName = "Discord (firefox)";
          genericName = "All-in-one cross-platform voice and text chat for gamers";
          exec = ''
            ${firefox}/bin/firefox "https://discord.com/channels/@me?khanelinix.app=true"'';
          icon = "discord";
          type = "Application";
          categories = [ "Network" "InstantMessaging" ];
          terminal = false;
          mimeTypes = [ "x-scheme-handler/discord" ];
        };
    };
}
