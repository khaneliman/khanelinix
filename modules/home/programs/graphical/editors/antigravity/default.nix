{ lib, ... }:
{
  # Keep the separate Antigravity IDE opt-in; this legacy option targets the standalone app.
  imports = [
    (lib.mkRenamedOptionModule
      [
        "khanelinix"
        "programs"
        "graphical"
        "editors"
        "antigravity"
        "enable"
      ]
      [
        "khanelinix"
        "programs"
        "graphical"
        "apps"
        "antigravity"
        "enable"
      ]
    )
  ];
}
