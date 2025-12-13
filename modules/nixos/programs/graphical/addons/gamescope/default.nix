{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.programs.graphical.addons.gamescope;
in
{
  options.khanelinix.programs.graphical.addons.gamescope = {
    enable = lib.mkEnableOption "gamescope";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      gamescope = {
        enable = true;
        package = pkgs.gamescope;

        # NOTE: breaks running WITHIN steam
        # just instantly crashes with failed to inherit capabilities: Operation not permitted
        # capSysNice = true;

        args = [
          # Use real-time scheduling
          "--rt"
          # Support Wayland clients
          "--expose-wayland"
        ];
      };
      steam.gamescopeSession.enable = true;
    };
  };
}

# Usage: Add to Steam game launch options
#
# ═══════════════════════════════════════════════════════════════
# TESTED & WORKING CONFIGURATIONS
# ═══════════════════════════════════════════════════════════════
#
# Recommended: Native Resolution Gamescope (Best Quality)
#   gamemoderun gamescope -W 5120 -H 1440 -r 120 -f -- mangohud %command%
#   ✅ HDR support, frame pacing, Alt-Tab safety, multi-monitor fixes
#   ✅ Best for single-player/AAA games
#   ⚠️  Tiny input latency (avoid for competitive shooters)
#
# Alternative: No Gamescope (Maximum Performance)
#   gamemoderun mangohud %command%
#   ✅ Lowest latency, simplest setup
#   ✅ Best for competitive multiplayer
#   ❌ No HDR, no Alt-Tab protection, worse frame pacing
#
# Virtual Super Resolution (4K -> Ultrawide, Max Quality AA)
#   gamemoderun gamescope -w 3840 -h 2160 -W 5120 -H 1440 -r 120 -f -- mangohud %command%
#   ✅ Best anti-aliasing possible (supersampling)
#   ⚠️  Heavy GPU load - 7900 XTX can handle it but expect lower FPS
#
# ═══════════════════════════════════════════════════════════════
# HDR GAMING (Samsung Odyssey G9 - HDR1000)
# ═══════════════════════════════════════════════════════════════
#
# HDR-Native Games (Cyberpunk, Elden Ring, etc.):
#   gamemoderun gamescope -W 5120 -H 1440 -r 120 -f --hdr-enabled --hdr-sdr-content-nits 400 -- mangohud %command%
#   ✅ Proper HDR tone mapping and metadata passthrough
#   ✅ Target: 1000 nits (HDR1000 monitor)
#
# SDR Games with HDR Conversion (Most games):
#   gamemoderun gamescope -W 5120 -H 1440 -r 120 -f --hdr-enabled --hdr-itm-enable --hdr-itm-target-nits 1000 -- mangohud %command%
#   ✅ Converts SDR to HDR using inverse tone mapping
#   ✅ Makes SDR games look better on HDR display
#   ⚠️  Experimental - some games may look oversaturated
#
# Notes:
#   • HDR requires Wayland (you're on Hyprland ✅)
#   • Enable HDR in monitor OSD first
#   • --hdr-itm-target-nits: 1000 for HDR1000, 400-600 for HDR400/600
#   • Press HDR button on monitor to verify HDR mode activates
#
# ═══════════════════════════════════════════════════════════════
# EXPERIMENTAL: Upscaling Options (Known Issues)
# ═══════════════════════════════════════════════════════════════
#
# FSR Upscaling Issues Discovered:
#   • FSR + fullscreen (-f) = black screen
#   • FSR + aspect ratio mismatch = graphical glitches
#   • Upscaling doesn't work properly in nested Wayland mode
#   • Output resolution (-W/-H) not honored - shows input res with black bars
#
# ═══════════════════════════════════════════════════════════════
# Window Management Options (No Upscaling)
# ═══════════════════════════════════════════════════════════════
#
# For games that don't support 32:9 ultrawide:
#
#   21:9 ultrawide:
#   gamemoderun gamescope -W 3440 -H 1440 -r 120 -f -- mangohud %command%
#
#   16:9 standard:
#   gamemoderun gamescope -W 2560 -H 1440 -r 120 -f -- mangohud %command%
#
# Without MangoHud overlay:
#   Just remove 'mangohud' from any command above
#
# FSR Sharpness:
#   --fsr-sharpness 0-20 (0 = sharpest, 20 = softest, default = 2)
#
# Common flags:
#   -W, --output-width: Output width (display size)
#   -H, --output-height: Output height (display size)
#   -w, --nested-width: Game width (rendering size, for upscaling)
#   -h, --nested-height: Game height (rendering size, for upscaling)
#   -r, --nested-refresh: Game refresh rate (frames per second)
#   -f, --fullscreen: Make the window fullscreen
#   -F, --filter: Upscaler filter (linear, nearest, fsr, nis, pixel)
#   --mangoapp: Launch with MangoHud overlay (preferred over 'mangohud' command)
#   --adaptive-sync: Enable VRR if available
