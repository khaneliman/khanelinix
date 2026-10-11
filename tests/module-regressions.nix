# Evaluate only the affected modules, using a supplied nixpkgs source tree.
{
  nixpkgs,
  root ? ../.,
}:
let
  baseLib = import (nixpkgs + "/lib");
  lib = baseLib // {
    khanelinix = import (root + "/lib/module") { inputs.nixpkgs.lib = baseLib; };
    getFile = path: root + "/${path}";
  };
  boolOption = lib.mkOption { type = lib.types.bool; };
  credentials =
    bits:
    (lib.evalModules {
      specialArgs = { inherit lib; };
      modules = [
        (root + "/homes/credentials.nix")
        {
          options = {
            khanelinix = lib.mkOption { type = lib.types.attrs; };
            home.homeDirectory = lib.mkOption { type = lib.types.str; };
            sops.secrets = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.submodule {
                  options = {
                    sopsFile = lib.mkOption { type = lib.types.path; };
                    path = lib.mkOption {
                      type = lib.types.str;
                      default = "/run/secrets/fixture";
                    };
                  };
                }
              );
              default = { };
            };
          };
          config = {
            home.homeDirectory = "/home/test";
            khanelinix = {
              services = {
                sops.enable = builtins.elemAt bits 0;
                vdirsyncer = {
                  enable = true;
                  google.enable = true;
                };
              };
              suites.development.enable = true;
              programs = {
                terminal = {
                  editors.neovim.enable = builtins.elemAt bits 1;
                  tools = {
                    git.enable = true;
                    atuin = {
                      enable = true;
                      sync.enable = true;
                    };
                    github-copilot-cli.enable = true;
                  };
                  social = {
                    slack-term.enable = true;
                    twitch-tui.enable = true;
                  };
                };
                graphical = {
                  editors.vscode.enable = builtins.elemAt bits 2;
                  bars = {
                    waybar.enable = builtins.elemAt bits 3;
                    ashell.enable = builtins.elemAt bits 4;
                    sketchybar.enable = builtins.elemAt bits 5;
                  };
                };
              };
            };
          };
        }
      ];
    }).config.sops.secrets;
  secret = name: path: {
    sopsFile = root + "/secrets/${name}/default.yaml";
    inherit path;
  };
  expectedCredentials =
    bits:
    lib.optionalAttrs (builtins.elemAt bits 0) (
      {
        "github/access-token" = secret "khaneliman" "/home/test/.config/gh/access-token";
        OPENAI_SECURA_KEY = secret "CORE" "/home/test/.OPENAI_SECURA_KEY";
        TAVILY_API_KEY = secret "khaneliman" "/home/test/.TAVILY_API_KEY";
        LUAROCKS_API_KEY = secret "khaneliman" "/home/test/.LUAROCKS_API_KEY";
        "atuin/key" = secret "khaneliman" "/run/secrets/fixture";
        "github/copilot-token" = secret "khaneliman" "/home/test/.config/copilot/token";
        slack-term = secret "khaneliman" "/home/test/.config/slack-term/config";
        twitch-tui = secret "khaneliman" "/home/test/.config/twt/config.toml";
        "calendar/google-client-id" = secret "khaneliman" "/run/secrets/fixture";
        "calendar/google-client-secret" = secret "khaneliman" "/run/secrets/fixture";
      }
      // lib.optionalAttrs (builtins.elemAt bits 1 || builtins.elemAt bits 2) {
        wakatime = secret "khaneliman" "/home/test/.wakatime.cfg";
      }
      // lib.optionalAttrs (lib.any (x: x) (lib.drop 3 bits)) {
        weather_config = secret "khaneliman" "/home/test/weather_config.json";
      }
    );
  capabilities = [
    {
      path = [
        "graphical"
        "apps"
        "codex-desktop"
        "enable"
      ];
      gate = "aiEnable";
    }
    {
      path = [
        "terminal"
        "tools"
        "azure"
        "developmentEnable"
      ];
      gate = "azureEnable";
    }
    {
      path = [
        "terminal"
        "tools"
        "go"
        "enable"
      ];
      gate = "goEnable";
    }
    {
      path = [
        "terminal"
        "tools"
        "k9s"
        "enable"
      ];
      gate = "kubernetesEnable";
    }
    {
      path = [
        "terminal"
        "tools"
        "lazydocker"
        "enable"
      ];
      gate = "dockerEnable";
    }
  ];
  suite =
    capability: gate: overrides: isWSL:
    lib.attrByPath
      (
        [
          "khanelinix"
          "programs"
        ]
        ++ capability.path
      )
      null
      (lib.evalModules {
        specialArgs = {
          inherit lib;
          pkgs = { };
          osConfig.khanelinix.archetypes.wsl.enable = isWSL;
        };
        modules = [
          (root + "/modules/home/suites/development")
          {
            # Unrelated package and service outputs are outside this schema.
            config._module.check = false;
            options = lib.setAttrByPath (
              [
                "khanelinix"
                "programs"
              ]
              ++ capability.path
            ) boolOption;
            config.khanelinix.suites.development = {
              enable = true;
              ${capability.gate} = gate;
            };
          }
        ]
        ++ map (value: {
          config = lib.setAttrByPath (
            [
              "khanelinix"
              "programs"
            ]
            ++ capability.path
          ) value;
        }) overrides;
      }).config;
  ssh =
    tailscale:
    let
      evaluated =
        (lib.evalModules {
          specialArgs = {
            inherit lib;
            pkgs = { };
          };
          modules = [
            (root + "/modules/common/programs/terminal/tools/ssh")
            (nixpkgs + "/nixos/modules/programs/ssh.nix")
            {
              options = {
                users = lib.mkOption { type = lib.types.attrs; };
                networking = lib.mkOption { type = lib.types.attrs; };
                khanelinix.user.name = lib.mkOption { type = lib.types.str; };
                khanelinix.services.tailscale.enable = boolOption;
                programs.gnupg.agent.enable = boolOption;
                environment.etc = lib.mkOption {
                  type = lib.types.attrsOf (
                    lib.types.submodule {
                      options.text = lib.mkOption { type = lib.types.lines; };
                    }
                  );
                };
              };
              config = {
                _module.check = false;
                users.users.test.uid = 1000;
                networking = {
                  hostName = "local";
                  enableIPv6 = true;
                };
                programs.ssh = {
                  systemd-ssh-proxy.enable = false;
                  setXAuthLocation = false;
                };
                programs.gnupg.agent.enable = true;
                khanelinix = {
                  user.name = "test";
                  services.tailscale.enable = tailscale;
                  programs.terminal.tools.ssh = {
                    enable = true;
                    magicDnsSuffix = "fleet.example";
                    hosts = {
                      local = {
                        hostname = "local.local";
                        username = "test";
                        system = "nixos";
                      };
                      linux = {
                        hostname = "linux.local";
                        username = "linux-user";
                        system = "nixos";
                        gpgAgent = true;
                        publicKey = "ssh-ed25519 fixture";
                      };
                      mac = {
                        hostname = "mac.local";
                        username = "mac-user";
                        system = "darwin";
                      };
                    };
                    extraConfig = ''
                      Host custom
                        Hostname custom.example
                        User custom-user
                        ForwardAgent yes
                        ConnectTimeout 17
                    '';
                  };
                };
              };
            }
          ];
        }).config;
    in
    {
      extraConfig = evaluated.environment.etc."ssh/ssh_config".text;
      knownHosts = evaluated.programs.ssh.knownHosts;
    };
  dolphin =
    enabled:
    let
      evaluated = import (nixpkgs + "/nixos/lib/eval-config.nix") {
        system = builtins.currentSystem;
        modules = [
          (root + "/modules/nixos/programs/graphical/file-managers/dolphin")
          {
            khanelinix.programs.graphical.file-managers.dolphin.enable = enabled;
            system.stateVersion = "26.11";
          }
        ];
      };
      inherit (evaluated) config;
      package = evaluated.pkgs.dolphin-emu;
    in
    {
      emulator = builtins.elem package config.environment.systemPackages;
      controllers = builtins.elem package config.services.udev.packages;
    };
  lightdm =
    cursor: icon:
    let
      pkgs = import nixpkgs { system = builtins.currentSystem; };
      greeter =
        (lib.evalModules {
          specialArgs = { inherit lib pkgs; };
          modules = [
            (root + "/modules/nixos/theme")
            (root + "/modules/nixos/theme/gtk")
            (root + "/modules/nixos/display-managers/lightdm")
            (nixpkgs + "/nixos/modules/services/x11/display-managers/lightdm-greeters/gtk.nix")
            {
              # The real greeter schema checks theme names and packages; other
              # display-manager outputs need a complete host to evaluate.
              config._module.check = false;
              config.khanelinix = {
                display-managers.lightdm.enable = true;
                theme =
                  lib.optionalAttrs cursor {
                    cursor = {
                      name = "Custom Cursor";
                      package = pkgs.emptyDirectory;
                    };
                  }
                  // lib.optionalAttrs icon {
                    icon = {
                      name = "Custom Icon";
                      package = pkgs.emptyDirectory;
                    };
                  };
              };
            }
          ];
        }).config.services.xserver.displayManager.lightdm.greeters.gtk;
    in
    {
      inherit (greeter) enable;
      cursor = greeter.cursorTheme.name;
      icon = greeter.iconTheme.name;
      cursorPackage = greeter.cursorTheme.package.outPath;
      iconPackage = greeter.iconTheme.package.outPath;
      defaultPackage = pkgs.adwaita-icon-theme.outPath;
      customPackage = pkgs.emptyDirectory.outPath;
    };
in
{
  credentials =
    map
      (
        bits:
        assert credentials bits == expectedCredentials bits;
        true
      )
      (
        lib.genList (
          n:
          map (bit: lib.mod (builtins.div n bit) 2 == 1) [
            1
            2
            4
            8
            16
            32
          ]
        ) 64
      );
  suite = lib.concatMap (
    capability:
    map
      (
        gate:
        assert suite capability gate [ ] false == gate;
        assert suite capability gate [ (!gate) ] false == !gate;
        true
      )
      [
        false
        true
      ]
  ) capabilities;
  wsl =
    assert !(suite (builtins.head capabilities) true [ ] true);
    true;
  ssh = {
    enabled = ssh true;
    disabled = ssh false;
  };
  lightdm = {
    default = lightdm false false;
    cursor = lightdm true false;
    icon = lightdm false true;
    custom = lightdm true true;
  };
  dolphin = {
    enabled = dolphin true;
    disabled = dolphin false;
  };
}
