{
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkForce getExe getExe';
  inherit (lib.${namespace}) enabled;

  gpgConf = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/drduh/config/master/gpg.conf";
    sha256 = "0va62sgnah8rjgp4m6zygs4z9gbpmqvq9m3x4byywk1dha6nvvaj";
  };
  gpgAgentConf = ''
    pinentry-program ${getExe' pkgs.pinentry-curses "pinentry-curses"}
  '';
  guide = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/drduh/YubiKey-Guide/master/README.md";
    sha256 = "164pyqm3yjybxlvwxzfb9mpp38zs9rb2fycngr6jv20n3vr1dipj";
  };
  theme = pkgs.fetchFromGitHub {
    owner = "jez";
    repo = "pandoc-markdown-css-theme";
    rev = "019a4829242937761949274916022e9861ed0627";
    sha256 = "1h48yqffpaz437f3c9hfryf23r95rr319lrb3y79kxpxbc9hihxb";
  };
  guideHTML = pkgs.runCommand "yubikey-guide" { } ''
    ${getExe pkgs.pandoc} \
      --standalone \
      --metadata title="Yubikey Guide" \
      --from markdown \
      --to html5+smart \
      --toc \
      --template ${theme}/template.html5 \
      --css ${theme}/docs/css/theme.css \
      --css ${theme}/docs/css/skylighting-solarized-theme.css \
      -o $out \
      ${guide}
  '';
in
{
  environment.systemPackages = with pkgs; [
    cryptsetup
    git
    gnupg
    pinentry-curses
    pinentry-qt
    paperkey
    wget
    pciutils
    file
  ];

  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  khanelinix = {
    nix = enabled;

    desktop = {
      gnome = {
        enable = true;
      };
    };

    apps = {
      firefox = enabled;
    };

    cli-apps = {
      neovim = enabled;
    };

    home = {
      file = {
        "guide.md".source = guide;
        "guide.html".source = guideHTML;
        "gpg.conf".source = gpgConf;
        "gpg-agent.conf".text = gpgAgentConf;

        ".gnupg/gpg.conf".source = gpgConf;
        ".gnupg/gpg-agent.conf".text = gpgAgentConf;
      };
    };

    security = {
      doas = enabled;
    };

    system = {
      fonts = enabled;
      locale = enabled;
      time = enabled;
      xkb = enabled;
      networking = {
        # Networking is explicitly disabled in this environment.
        enable = mkForce false;
      };
    };
  };

  services = {
    pcscd.enable = true;
    udev.packages = with pkgs; [ yubikey-personalization ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
