{ lib, ... }:
{
  imports = [ ../../common/home ];

  options.khanelinix.home.homeConfig =
    lib.khanelinix.mkOpt lib.types.attrs { }
      "Final config for home-manager.";

}
