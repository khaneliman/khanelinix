{
  config,
  isWSL,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

  businessAnnotationsEnabled =
    config.khanelinix.suites.business.enable
    && config.khanelinix.suites.business.annotationEnable
    && !isWSL;

  annotationOpeners =
    lib.optional (isLinux && config.khanelinix.programs.graphical.addons.satty.enable) {
      run = "satty --filename %s1";
      desc = "Annotate with Satty";
      orphan = true;
    }
    ++ lib.optional (isLinux && config.khanelinix.programs.graphical.addons.swappy.enable) {
      run = "swappy -f %s1";
      desc = "Annotate with Swappy";
      orphan = true;
    }
    ++ lib.optional (isLinux && businessAnnotationsEnabled) {
      run = "ksnip --edit %s1";
      desc = "Annotate with Ksnip";
      orphan = true;
    }
    ++ lib.optionals (isDarwin && businessAnnotationsEnabled) [
      {
        run = "open -a Shottr %s1";
        desc = "Annotate with Shottr";
        orphan = true;
      }
      {
        run = "open -a macshot %s1";
        desc = "Annotate with macshot";
        orphan = true;
      }
    ];
in
lib.mkIf (annotationOpeners != [ ]) {
  opener.annotate = annotationOpeners;

  open.prepend_rules = [
    {
      mime = "image/*";
      use = [
        "open"
        "annotate"
        "reveal"
      ];
    }
  ];
}
