# Advantage360 Pro Firmware

Declarative Kinesis Advantage360 Pro ZMK configuration.

Build:

```sh
nix build .#adv360-firmware
```

Flash:

```sh
flash-adv360 left /run/media/$USER/<LEFT_BOOTLOADER> ./result
flash-adv360 right /run/media/$USER/<RIGHT_BOOTLOADER> ./result
```

Bootloader mode:

1. Connect only one module over USB.
2. For firmware updates, start with the left module and keep the right module powered down.
3. Use a paperclip to quickly double-click that module's bootloader/reset button.
4. Wait for the `ADV360PRO` removable drive to appear, then flash the matching side.
5. Disconnect/power-cycle that side after it finishes, then repeat for the right module.

Do not open both bootloader drives at once. They use the same `ADV360PRO` label,
which makes it easy to copy the wrong UF2 to the wrong half.

VoxType bindings:

- `Fn+D` emits `F13` for VoxType toggle.
- `Fn+F` emits `F14` for VoxType cancel.

Existing imported mappings preserved from `/home/khaneliman/Documents/github/Adv360-Pro-ZMK`:

- Base right inner key emits `PRINTSCREEN`.
- Base right home-row inner key emits `SCROLLLOCK`.
