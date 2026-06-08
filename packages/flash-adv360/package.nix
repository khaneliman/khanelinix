{
  lib,
  writeShellApplication,
  coreutils,
  ...
}:

writeShellApplication {
  name = "flash-adv360";

  runtimeInputs = [ coreutils ];

  text = ''
    usage() {
      cat <<'USAGE'
    Usage: flash-adv360 <left|right> <bootloader-mountpoint> [firmware-dir]

    Build firmware first:
      nix build .#adv360-firmware

    Then put one keyboard half in bootloader mode and pass its mountpoint:
      flash-adv360 left /run/media/$USER/<LEFT_BOOTLOADER> ./result
      flash-adv360 right /run/media/$USER/<RIGHT_BOOTLOADER> ./result

    Bootloader mode:
      1. Connect one module over USB.
      2. Start with the left module; keep the right module powered down.
      3. Quickly double-click that module's bootloader/reset button with a paperclip.
      4. Wait for the ADV360PRO removable drive to mount.
      5. Flash only the matching side, then repeat for the other module.

    Do not mount both halves at once; both drives use the ADV360PRO label.
    USAGE
    }

    if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
      usage >&2
      exit 2
    fi

    part="$1"
    mountpoint="$2"
    firmware_dir="''${3:-./result}"

    case "$part" in
      left|right) ;;
      *)
        usage >&2
        exit 2
        ;;
    esac

    firmware="$firmware_dir/zmk_$part.uf2"

    if [ ! -f "$firmware" ]; then
      echo "missing firmware: $firmware" >&2
      exit 1
    fi

    if [ ! -d "$mountpoint" ]; then
      echo "missing mountpoint: $mountpoint" >&2
      exit 1
    fi

    cp "$firmware" "$mountpoint/"
    sync "$mountpoint"
    echo "flashed $firmware to $mountpoint"
  '';

  meta = {
    description = "Flash Kinesis Advantage360 Pro UF2 firmware";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "flash-adv360";
  };
}
