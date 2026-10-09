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
