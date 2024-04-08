_: final: prev: {
  khanelinix = (prev.khanelinix or { }) // {
    yt-music = prev.makeDesktopItem {
      name = "YT Music";
      desktopName = "YT Music";
      genericName = "Music, from YouTube.";
      exec = ''${prev.lib.getExe final.firefox} "https://music.youtube.com/?khanelinix.app=true"'';
      icon = ./icon.svg;
      type = "Application";
      categories = [
        "AudioVideo"
        "Audio"
        "Player"
      ];
      terminal = false;
    };
  };
}
