{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.user;
in
{
  options.${namespace}.user = with types; {
    email = mkOpt str "khaneliman12@gmail.com" "The email of the user.";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
    extraOptions = mkOpt attrs { } "Extra options passed to <option>users.users.<name></option>.";
    fullName = mkOpt str "Austin Horstman" "The full name of the user.";
    initialPassword =
      mkOpt str "password"
        "The initial password to use when the user is first created.";
    name = mkOpt str "khaneliman" "The name to use for the user account.";
  };

  config = {
    users.users.${cfg.name} = {
      inherit (cfg) name initialPassword;

      extraGroups = [
        "wheel"
        "systemd-journal"
        "mpd"
        "audio"
        "video"
        "input"
        "plugdev"
        "lp"
        "tss"
        "power"
        "nix"
      ]
      ++ cfg.extraGroups;

      group = "users";
      home = "/home/${cfg.name}";
      isNormalUser = true;
      shell = pkgs.zsh;
      uid = 1000;
    }
    // cfg.extraOptions;
  };
}
