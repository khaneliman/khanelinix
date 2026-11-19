{ lib, pkgs, ... }:
{
  khanelinix.user = {
    email = lib.mkDefault "khaneliman12@gmail.com";
    fullName = lib.mkDefault "Austin Horstman";
    icon = lib.mkDefault pkgs.khanelinix.user-icon;
  };
}
