{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./credentials.nix
    ./fleet-ssh.nix
  ];
  khanelinix = {
    environments.home-network = {
      serverHostname = lib.mkDefault "austinserver.taild8431e.ts.net";
      serverLocalHostname = lib.mkDefault "austinserver.local";
    };
    programs.graphical.apps.thunderbird.extraCalendarAccounts = lib.mkOptionDefault {
      "Milwaukee Bucks" = {
        url = "https://apidata.googleusercontent.com/caldav/v2/jeb1pn12iqgftnq21ae2qjljetlr43cv%40import.calendar.google.com/events/";
        type = "caldav";
        color = "#05491C";
      };
      "US Holidays" = {
        url = "https://apidata.googleusercontent.com/caldav/v2/cln2stbjc4hmgrrcd5i62ua0ctp6utbg5pr2sor1dhimsp31e8n6errfctm6abj3dtmg%40virtual/events/";
        type = "caldav";
        color = "#92cfe1";
      };
      "Green Bay Packers" = {
        url = "https://sports.yahoo.com/nfl/teams/gnb/ical.ics";
        type = "http";
        color = "#F9BC12";
      };
    };
    user = {
      email = lib.mkDefault "khaneliman12@gmail.com";
      fullName = lib.mkDefault "Austin Horstman";
      icon = lib.mkDefault pkgs.khanelinix.user-icon;
    };
  };
  home.shellAliases.ghrck = lib.mkIf (
    config.programs.gh.enable && config.khanelinix.programs.terminal.tools.git.enable
  ) "gh repo clone khaneliman/";
}
