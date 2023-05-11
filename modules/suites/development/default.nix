{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.development;
  apps = {
    neovide = enabled;
    vscode = enabled;
    yubikey = enabled;
  };
  cli-apps = {
    helix = enabled;
    lazydocker = enabled;
    lazygit = enabled;
    neovim = enabled;
    onefetch = enabled;
    prisma = enabled;
    tmux = enabled;
    yubikey = enabled;
  };
in
{
  options.khanelinix.suites.development = with types; {
    enable =
      mkBoolOpt false
        "Whether or not to enable common development configuration.";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      12345
      3000
      3001
      8080
      8081
    ];

    khanelinix = {
      inherit apps cli-apps;

      tools = {
        clang = enabled;
        cmake = enabled;
        dotnet = enabled;
        fd = enabled;
        gcc = enabled;
        gxx = enabled;
        git = enabled;
        git-crypt = enabled;
        gnumake = enabled;
        go = enabled;
        http = enabled;
        k8s = enabled;
        llvm = enabled;
        meson = enabled;
        node = enabled;
        pkg-config = enabled;
        python = enabled;
        qmk = enabled;
        ripgrep = enabled;
        rust = enabled;
        tree-sitter = enabled;
      };

      virtualisation = { podman = enabled; };
    };
  };
}
