{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.apps.prismlauncher;
in
{
  options.khanelinix.programs.graphical.apps.prismlauncher = {
    enable = lib.mkEnableOption "prismlauncher";

    javaPackage = lib.mkPackageOption pkgs "jdk21" {
      extraDescription = "Default runtime for instances that do not override Java.";
    };

    maxMemoryMiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4096;
      description = "Default maximum JVM heap for new instances, in MiB.";
    };

    minMemoryMiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 512;
      description = "Default minimum JVM heap for new instances, in MiB.";
    };
  };

  config = mkIf cfg.enable {
    programs.prismlauncher = {
      # Prism Launcher documentation
      # See: https://prismlauncher.org/wiki/
      enable = true;

      # The first-run wizard asks for a Java runtime whenever JavaPath is
      # unset or the hostname changed, then asks again about automatic Java
      # handling. Answer all of it here so a fresh profile launches straight
      # into the instance list.
      settings = {
        JavaPath = lib.getExe' cfg.javaPackage "java";
        IgnoreJavaWizard = true;
        MaxMemAlloc = cfg.maxMemoryMiB;
        MinMemAlloc = cfg.minMemoryMiB;

        # Let Prism pick the matching bundled JDK per Minecraft version from
        # the wrapper's PRISMLAUNCHER_JAVA_PATHS instead of downloading one.
        AutomaticJavaSwitch = true;
        AutomaticJavaDownload = false;
        UserAskedAboutAutomaticJavaDownload = true;
      };
    };
  };
}
