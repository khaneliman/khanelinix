{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.fonts;

  mkMonaspaceFamily = familyNoSpace: familyWithSpace: {
    static = mkOpt types.str (
      if pkgs.stdenv.hostPlatform.isDarwin then familyWithSpace else familyNoSpace
    ) "Monaspace ${familyWithSpace} family name";

    var = mkOpt types.str (
      if pkgs.stdenv.hostPlatform.isDarwin then "Monaspace ${familyWithSpace} Var" else familyNoSpace
    ) "Monaspace ${familyWithSpace} family name (variable)";

    nf = mkOpt types.str (
      if pkgs.stdenv.hostPlatform.isDarwin then
        "Monaspace ${familyWithSpace} NF"
      else
        "${familyNoSpace} NF"
    ) "Monaspace ${familyWithSpace} family name (Nerd Font)";

    frozen = mkOpt types.str (
      if pkgs.stdenv.hostPlatform.isDarwin then
        "Monaspace ${familyWithSpace} Frozen"
      else
        "${familyNoSpace} Frozen"
    ) "Monaspace ${familyWithSpace} family name (Frozen)";
  };

  monaspace = {
    neon = mkMonaspaceFamily "MonaspaceNeon" "Neon";
    krypton = mkMonaspaceFamily "MonaspaceKrypton" "Krypton";
    argon = mkMonaspaceFamily "MonaspaceArgon" "Argon";
    radon = mkMonaspaceFamily "MonaspaceRadon" "Radon";
    xenon = mkMonaspaceFamily "MonaspaceXenon" "Xenon";
  };

  # Helper for apps wanting a single best family string.
  # Defaults to Nerd Font static families for terminal usage.
  defaultMonaspaceNf = {
    neon = cfg.monaspace.neon.nf;
    krypton = cfg.monaspace.krypton.nf;
    argon = cfg.monaspace.argon.nf;
    radon = cfg.monaspace.radon.nf;
    xenon = cfg.monaspace.xenon.nf;
  };

  # Useful for apps that accept comma-separated font-family stacks.
  defaultStacks = {
    editor = lib.concatStringsSep ", " [
      cfg.monaspace.argon.nf
      cfg.monaspace.argon.static
      "CascadiaCode"
      "Consolas"
      "monospace"
      "Hack Nerd Font"
    ];

    ui = lib.concatStringsSep ", " [
      cfg.monaspace.neon.nf
      cfg.monaspace.neon.static
      "Liga SFMono Nerd Font"
      "CascadiaCode"
      "Consolas"
      "'Courier New'"
      "monospace"
      "Hack Nerd Font"
    ];

    terminal = lib.concatStringsSep ", " [
      cfg.monaspace.krypton.nf
      cfg.monaspace.krypton.static
      "JetBrainsMono Nerd Font Mono"
    ];
  };

in
{
  options.khanelinix.fonts = {
    monaspace = {
      # Each family provides { static, var, nf, frozen }
      inherit (monaspace)
        neon
        krypton
        argon
        radon
        xenon
        ;

      # Convenience attributes to match existing consumers.
      families = {
        neon = mkOpt types.str defaultMonaspaceNf.neon "Default Monaspace Neon family";
        krypton = mkOpt types.str defaultMonaspaceNf.krypton "Default Monaspace Krypton family";
        argon = mkOpt types.str defaultMonaspaceNf.argon "Default Monaspace Argon family";
        radon = mkOpt types.str defaultMonaspaceNf.radon "Default Monaspace Radon family";
        xenon = mkOpt types.str defaultMonaspaceNf.xenon "Default Monaspace Xenon family";

        neonVar = mkOpt types.str cfg.monaspace.neon.var "Monaspace Neon family (variable)";
        kryptonVar = mkOpt types.str cfg.monaspace.krypton.var "Monaspace Krypton family (variable)";
        radonVar = mkOpt types.str cfg.monaspace.radon.var "Monaspace Radon family (variable)";
        xenonVar = mkOpt types.str cfg.monaspace.xenon.var "Monaspace Xenon family (variable)";
      };

      stacks = {
        editor = mkOpt types.str defaultStacks.editor "Font-family stack for code editors";
        ui = mkOpt types.str defaultStacks.ui "Font-family stack for UI text";
        terminal = mkOpt types.str defaultStacks.terminal "Font-family stack for terminals";
      };
    };
  };
}
