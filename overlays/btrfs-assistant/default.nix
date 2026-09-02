_: _final: prev: {
  btrfs-assistant = prev.btrfs-assistant.overrideAttrs (old: {
    version = "2.3.1-rootless-polkit";

    src = prev.fetchFromGitLab {
      owner = "khaneliman";
      repo = "btrfs-assistant";
      rev = "4979691523d5cb2b2ee2c85490c6c0414f401074";
      hash = "sha256-jS18A9CHBhyxP8Evz5UgKKT7VPPIdb/2gKElKg8GNeA=";
    };

    patches = [ ];
    prePatch = "";
    postPatch = ''
      substituteInPlace src/main.cpp \
        --replace-fail \
          /usr/share/btrfs-assistant/translations \
          "$out/share/btrfs-assistant/translations"
    '';

    buildInputs = (old.buildInputs or [ ]) ++ [
      prev.diffutils
      prev.kdePackages.polkit-qt-1
      prev.systemd
    ];

    meta = old.meta // {
      mainProgram = "btrfs-assistant";
    };
  });
}
