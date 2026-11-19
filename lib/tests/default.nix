{
  self,
  lib,
}:
let
  inherit (self.lib)
    base64
    file
    module
    theme
    ;

  boundModule = ./fixtures/modules/bound;
  evaluateBoundModules =
    extraModules:
    (lib.evalModules {
      specialArgs = {
        token = "consumer";
        inputs.marker = "consumer";
        callerValue = "caller";
      };
      modules = [
        {
          options = {
            boundValues = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
            nestedValues = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          };
        }
      ]
      ++ self.lib.system.common.bindModules {
        inherit lib;
        token = "owner";
        inputs.marker = "owner";
      } ([ boundModule ] ++ extraModules);
    }).config;
in
{
  testHmUserConfig = {
    expr =
      let
        homes = {
          "".home.username = "";
          alice.home.username = "alice";
        };
        lookup =
          name:
          module.hmUserConfig {
            khanelinix.user = { inherit name; };
            home-manager.users = homes;
          };
      in
      {
        unnamed = lookup null;
        missingUser = lookup "bob";
        missingHomeManager = module.hmUserConfig { khanelinix.user.name = "alice"; };
        missingUserOption = module.hmUserConfig { home-manager.users = homes; };
        named = lookup "alice";
      };
    expected = {
      unnamed = { };
      missingUser = { };
      missingHomeManager = { };
      missingUserOption = { };
      named.home.username = "alice";
    };
  };

  testShellIntegrations = {
    expr =
      let
        integrationDefaults =
          module.shellIntegrations
            {
              programs = {
                bash.enable = true;
                fish.enable = false;
                nushell.enable = true;
                zsh.enable = true;
              };
              home.shell = {
                enableBashIntegration = true;
                enableNushellIntegration = false;
                enableZshIntegration = true;
              };
            }
            [
              "bash"
              "fish"
              "nushell"
              "zsh"
            ];
      in
      (lib.evalModules {
        modules = [
          { options = lib.mapAttrs (_: _: lib.mkEnableOption "test integration") integrationDefaults; }
          { config = integrationDefaults; }
          { enableZshIntegration = false; }
        ];
      }).config;
    expected = {
      enableBashIntegration = true;
      enableFishIntegration = false;
      enableNushellIntegration = false;
      enableZshIntegration = false;
    };
  };

  testPatchedFlakeRetainsInputs = {
    expr =
      let
        patched = self.lib.system.common.mkPatchedFlake {
          pkgs = { };
          inputName = "fixture";
          input.outPath = ./fixtures/flake;
          force = true;
          flakeInputs.marker = "owner";
        };
      in
      {
        type = patched._type;
        evaluated = patched.marker;
        retained = patched.inputs.marker;
        source = patched.sourceInfo.outPath == patched.outPath;
      };
    expected = {
      type = "flake";
      evaluated = "owner";
      retained = "owner";
      source = true;
    };
  };

  testPatchedInputsPropagateToFollowers = {
    expr =
      let
        source = ./fixtures/flake;
        system = "x86_64-linux";
        lockedInput = {
          outPath = source;
          inputs = {
            marker = "kept";
            nixpkgs.marker = "locked";
          };
          followedMarker = "locked";
        };
        common = import ../system/common.nix {
          inputs = {
            nixpkgs = {
              inherit lib;
              outPath = source;
              inputs.marker = "main";
            };
            nixpkgs-unstable = {
              outPath = source;
              inputs.marker = "unstable";
              legacyPackages.${system}.applyPatches = _: source;
            };
            stylix = lockedInput;
            sops-nix = lockedInput;
          };
        };
        extraInputPatches = {
          nixpkgs = [ source ];
          nixpkgs-unstable = [ source ];
        };
        patched = common.mkPatchedInputs { inherit system extraInputPatches; };
        limited = common.mkPatchedInputs {
          inherit system extraInputPatches;
          patchableInputs = [
            "stylix"
            "sops-nix"
          ];
        };
      in
      {
        stylixFollow = patched.stylix.followedMarker;
        sopsFollow = patched.sops-nix.followedMarker;
        stylixOtherInput = patched.stylix.inputs.marker;
        limitedStylixFollow = limited.stylix.followedMarker;
        limitedSopsFollow = limited.sops-nix.followedMarker;
      };
    expected = {
      stylixFollow = "main";
      sopsFollow = "unstable";
      stylixOtherInput = "kept";
      limitedStylixFollow = "locked";
      limitedSopsFollow = "locked";
    };
  };

  testBoundModuleArguments = {
    expr = evaluateBoundModules [ ];
    expected = {
      boundValues = [
        "owner"
        "owner"
        "caller"
      ];
      nestedValues = [ "owner" ];
    };
  };

  testBoundModuleDeduplication = {
    expr = evaluateBoundModules [ boundModule ];
    expected = {
      boundValues = [
        "owner"
        "owner"
        "caller"
      ];
      nestedValues = [ "owner" ];
    };
  };

  testBoundModuleDisabledByPath = {
    expr = evaluateBoundModules [ { disabledModules = [ boundModule ]; } ];
    expected = {
      boundValues = [ ];
      nestedValues = [ ];
    };
  };

  testBoundNestedModuleDisabledByPath = {
    expr = evaluateBoundModules [ { disabledModules = [ (boundModule + "/nested.nix") ]; } ];
    expected = {
      boundValues = [
        "owner"
        "owner"
        "caller"
      ];
      nestedValues = [ ];
    };
  };

  testBindingLeavesCallerModulesUntouched = {
    expr = evaluateBoundModules [ ({ token, ... }: { nestedValues = [ token ]; }) ];
    expected = {
      boundValues = [
        "owner"
        "owner"
        "caller"
      ];
      nestedValues = [
        "owner"
        "consumer"
      ];
    };
  };

  # base64.decode
  testBase64DecodeHello = {
    expr = base64.decode "aGVsbG8=";
    expected = "hello";
  };

  testBase64DecodeNoPadding = {
    expr = base64.decode "Zm9vYmFy";
    expected = "foobar";
  };

  testBase64DecodeOnePad = {
    expr = base64.decode "Zm9vYmE=";
    expected = "fooba";
  };

  testBase64DecodeTwoPad = {
    expr = base64.decode "Zm9vYg==";
    expected = "foob";
  };

  # module.capitalize
  testCapitalizeWord = {
    expr = module.capitalize "hello";
    expected = "Hello";
  };

  testCapitalizeSingle = {
    expr = module.capitalize "a";
    expected = "A";
  };

  testCapitalizeEmpty = {
    expr = module.capitalize "";
    expected = "";
  };

  # module.boolToNum
  testBoolToNumTrue = {
    expr = module.boolToNum true;
    expected = 1;
  };

  testBoolToNumFalse = {
    expr = module.boolToNum false;
    expected = 0;
  };

  testProfileIncludesStandardCore = {
    expr = module.profileIncludes "standard" "core";
    expected = true;
  };

  testProfileIncludesStandardMaximal = {
    expr = module.profileIncludes "standard" "maximal";
    expected = false;
  };

  testProfileIncludesMaximalStandard = {
    expr = module.profileIncludes "maximal" "standard";
    expected = true;
  };

  testResolvePackageProfileDefault = {
    expr = module.resolvePackageProfile "standard" null;
    expected = "standard";
  };

  testResolvePackageProfileOverride = {
    expr = module.resolvePackageProfile "standard" "maximal";
    expected = "maximal";
  };

  testSuiteProfileIncludesDefault = {
    expr =
      module.suiteProfileIncludes
        {
          khanelinix.packageProfile = "standard";
        }
        {
          packageProfile = null;
        }
        "maximal";
    expected = false;
  };

  testSuiteProfileIncludesOverride = {
    expr =
      module.suiteProfileIncludes
        {
          khanelinix.packageProfile = "standard";
        }
        {
          packageProfile = "maximal";
        }
        "maximal";
    expected = true;
  };

  # module.enabled / module.disabled
  testEnabled = {
    expr = module.enabled;
    expected = {
      enable = true;
    };
  };

  testDisabled = {
    expr = module.disabled;
    expected = {
      enable = false;
    };
  };

  # module.enableForSystem keeps modules with no `systems` or a matching one.
  testEnableForSystem = {
    expr = module.enableForSystem "x86_64-linux" [
      { name = "any"; }
      {
        name = "darwin-only";
        systems = [ "aarch64-darwin" ];
      }
      {
        name = "linux-only";
        systems = [ "x86_64-linux" ];
      }
    ];
    expected = [
      { name = "any"; }
      {
        name = "linux-only";
        systems = [ "x86_64-linux" ];
      }
    ];
  };

  # module.mkOpt / module.mkBoolOpt resolve to module-system options.
  testMkOptDefault = {
    expr = (module.mkOpt' lib.types.int 5).default;
    expected = 5;
  };

  testMkBoolOptDefault = {
    expr = (module.mkBoolOpt' true).default;
    expected = true;
  };

  # module.default-attrs / module.force-attrs wrap values with merge priorities.
  testDefaultAttrsContent = {
    expr = (module.default-attrs { a = 1; }).a.content;
    expected = 1;
  };

  testDefaultAttrsPriority = {
    expr = (module.default-attrs { a = 1; }).a.priority;
    expected = 1000;
  };

  testForceAttrsPriority = {
    expr = (module.force-attrs { a = 1; }).a.priority;
    expected = 50;
  };

  # file.mergeAttrs (later sets win)
  testMergeAttrs = {
    expr = file.mergeAttrs [
      {
        a = 1;
        b = 1;
      }
      {
        b = 2;
        c = 3;
      }
    ];
    expected = {
      a = 1;
      b = 2;
      c = 3;
    };
  };

  testMergeAttrsEmpty = {
    expr = file.mergeAttrs [ ];
    expected = { };
  };

  # lib.extend also rebinds nixpkgs' internal references, so a shadowed name
  # breaks upstream code such as mergeDefaultOption, not just callers.
  testOverlayKeepsStockLibNames = {
    expr = builtins.attrNames (builtins.intersectAttrs lib (self.lib.overlay lib lib));
    expected = [ ];
  };

  # theme helpers
  testThemeMkColorScheme = {
    expr = theme.mkColorScheme "test" { bg = "#000000"; };
    expected = {
      name = "test";
      colors = {
        bg = "#000000";
      };
      type = "colorScheme";
    };
  };

  testThemeGetColors = {
    expr = theme.getColors {
      colors = {
        fg = "#ffffff";
      };
    };
    expected = {
      fg = "#ffffff";
    };
  };

  testThemeGetColorsMissing = {
    expr = theme.getColors { };
    expected = { };
  };

  testThemeVariants = {
    expr = theme.variants;
    expected = {
      light = "light";
      dark = "dark";
    };
  };

  # module.userDir
  testUserDirEnabled = {
    expr = module.userDir {
      xdg.userDirs = {
        enable = true;
        pictures = "/custom/pictures";
      };
    } "pictures" "Pictures";
    expected = "/custom/pictures";
  };

  testUserDirDisabled = {
    expr = module.userDir {
      home.homeDirectory = "/home/testuser";
      xdg.userDirs.enable = false;
    } "pictures" "Pictures";
    expected = "/home/testuser/Pictures";
  };

  # module.uwsmApp
  testUwsmAppDisabled = {
    expr = module.uwsmApp { } "firefox";
    expected = "run-as-service firefox";
  };

  testUwsmAppEnabled = {
    expr = module.uwsmApp { programs.uwsm.enable = true; } "firefox";
    expected = "uwsm app -p TimeoutStopSec=15s -- firefox";
  };

  testUwsmAppSlice = {
    expr = module.uwsmApp { programs.uwsm.enable = true; } { slice = "b"; } "vesktop";
    expected = "uwsm app -s b -p TimeoutStopSec=10s -- vesktop";
  };

  testUwsmAppCustomTimeout = {
    expr = module.uwsmApp { programs.uwsm.enable = true; } {
      slice = "b";
      timeoutStopSec = "20s";
    } "vesktop";
    expected = "uwsm app -s b -p TimeoutStopSec=20s -- vesktop";
  };

  testUwsmAppPrefixOnly = {
    expr = module.uwsmApp { programs.uwsm.enable = true; } "";
    expected = "uwsm app -p TimeoutStopSec=15s --";
  };

  testUwsmAppPrefixOnlyDisabled = {
    expr = module.uwsmApp { } "";
    expected = "run-as-service";
  };
  testInputPackageSetConfig = {
    expr =
      let
        packageSets = self.lib.system.common.mkInputPackageSets {
          flake = self;
          system = "x86_64-linux";
        };
      in
      lib.mapAttrs (_: getPkgs: {
        default = (getPkgs "x86_64-linux" { }).config.allowUnfree;
        sameSystem = (getPkgs "x86_64-linux" { config.allowUnfree = false; }).config.allowUnfree;
        otherSystem = (getPkgs "aarch64-linux" { config.allowUnfree = false; }).config.allowUnfree;
      }) packageSets;
    expected =
      let
        config = {
          default = true;
          sameSystem = false;
          otherSystem = false;
        };
      in
      {
        getPkgsMaster = config;
        getPkgsUnstable = config;
      };
  };

  testDarwinHomeManagerUsername = {
    expr =
      let
        homeModule = self.lib.system.common.mkHomeManagerConfig {
          inherit (self) inputs;
          extendedLib = lib;
          system = "aarch64-darwin";
          hostname = "fixture";
          matchingHomes.fixture = {
            username = "alice";
            path = { };
          };
          inputPackageSets = { };
          sharedHomeModules = [ ];
          isNixOS = false;
        };
        user = (homeModule { config = { }; }).home-manager.users.alice;
      in
      user._module.args.username or null;
    expected = "alice";
  };

  testQualifiedSystemDiscovery = {
    expr = builtins.attrNames (file.parseSystemConfigurations ./fixtures/systems);
    expected = [
      "aarch64-linux/shared"
      "x86_64-linux/shared"
    ];
  };
  testDiscoveryCollisionRejected = {
    expr =
      (builtins.tryEval (
        file.publicConfigurations "hostname" (file.parseSystemConfigurations ./fixtures/systems)
      )).success;
    expected = false;
  };
  testPublicNamePreserved = {
    expr = builtins.attrNames (
      file.publicConfigurations "hostname" {
        "x86_64-linux/host" = {
          hostname = "host";
        };
      }
    );
    expected = [ "host" ];
  };
  testQualifiedHomeDiscovery = {
    expr = builtins.attrNames (file.parseHomeConfigurations ./fixtures/homes);
    expected = [
      "aarch64-linux/neutral@shared"
      "x86_64-linux/neutral@shared"
    ];
  };
  testHomeCollisionRejected = {
    expr =
      (builtins.tryEval (
        file.publicConfigurations "userAtHost" (file.parseHomeConfigurations ./fixtures/homes)
      )).success;
    expected = false;
  };
}
