_: _final: prev: {
  btrfs-assistant = prev.btrfs-assistant.overrideAttrs (old: {
    version = "2.3.1-rootless-polkit";

    src = prev.fetchFromGitLab {
      owner = "khaneliman";
      repo = "btrfs-assistant";
      rev = "de03f8303db8a337b07a097bdef711fe4aac6cae";
      hash = "sha256-bXjcK+83E5Psap6H02HfWPlm9L+OV7xusv8tunjLOzE=";
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
