_: final: prev:
let
  disableChecks =
    pkg:
    pkg.overrideAttrs (old: {
      doCheck = final.stdenv.hostPlatform.isLinux;
      checkInputs = if final.stdenv.hostPlatform.isLinux then (old.checkInputs or [ ]) else [ ];
      nativeCheckInputs =
        if final.stdenv.hostPlatform.isLinux then (old.nativeCheckInputs or [ ]) else [ ];
    });
in
{
  # FIXME: broken nushell dependency darwin
  bat-extras = prev.bat-extras // {
    core = disableChecks prev.bat-extras.core;
    batdiff = disableChecks prev.bat-extras.batdiff;
    batgrep = disableChecks prev.bat-extras.batgrep;
    batman = disableChecks prev.bat-extras.batman;
    batpipe = disableChecks prev.bat-extras.batpipe;
    batwatch = disableChecks prev.bat-extras.batwatch;
    prettybat = disableChecks prev.bat-extras.prettybat;
  };
}
