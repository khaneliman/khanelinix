{ config
, lib
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.apps.thunderbird;
in
{
  options.khanelinix.apps.thunderbird = {
    enable = mkEnableOption "thunderbird";
  };

  config = mkIf cfg.enable {
    # TODO: set up accounts
    accounts.email.accounts = {
      "austin.m.horstman@gmail.com" = {
        address = "austin.m.horstman@gmail.com";
        realName = config.khanelinix.user.fullName;
        flavor = "gmail.com";
      };
    };
  };
}
