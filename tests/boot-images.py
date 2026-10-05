"""Boot an actual ISO with disposable UEFI variables and no host disks/network."""

import argparse
import os
import pathlib
import re
import selectors
import shutil
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("iso", type=pathlib.Path)
parser.add_argument("qemu", type=pathlib.Path)
parser.add_argument(
    "firmware", type=pathlib.Path, help="OVMF directory containing CODE/VARS fd files"
)
parser.add_argument("evidence", type=pathlib.Path)
parser.add_argument("--rescue", action="store_true")
parser.add_argument("--tcg", action="store_true")
args = parser.parse_args()
args.evidence.mkdir(parents=True, exist_ok=True)
cache = pathlib.Path(os.environ.get("XDG_CACHE_HOME", pathlib.Path.home() / ".cache"))
cache.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix="khanelinix-uefi-", dir=cache) as scratch:
    variables = pathlib.Path(scratch) / "OVMF_VARS.fd"
    shutil.copyfile(args.firmware / "OVMF_VARS.fd", variables)
    command = [
        str(args.qemu),
        "-machine",
        "q35",
        "-accel",
        "tcg" if args.tcg else "kvm",
        "-cpu",
        "max" if args.tcg else "host",
        "-m",
        "4096",
        "-smp",
        "2",
        "-drive",
        f"if=pflash,format=raw,readonly=on,file={args.firmware / 'OVMF_CODE.fd'}",
        "-drive",
        f"if=pflash,format=raw,file={variables}",
        "-cdrom",
        str(args.iso.resolve()),
        "-boot",
        "order=d",
        "-nic",
        "none",
        "-display",
        "none",
        "-serial",
        "stdio",
        "-monitor",
        "none",
    ]
    (args.evidence / "command.txt").write_text(repr(command) + "\n")
    process = subprocess.Popen(
        command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT
    )
    selector = selectors.DefaultSelector()
    selector.register(process.stdout, selectors.EVENT_READ)
    output = b""
    sent = False
    success = False
    deadline = time.monotonic() + 300
    checks = "test -d /sys/firmware/efi && findmnt / && findmnt /nix/store && test $(ls /sys/class/net | wc -l) -eq 1"
    checks += ' && { for efiVar in /sys/firmware/efi/efivars/SecureBoot-* /sys/firmware/efi/efivars/SetupMode-*; do if [ -e "$efiVar" ]; then printf "%s " "$efiVar"; od -An -tu1 -j4 "$efiVar"; fi; done; }'
    if args.rescue:
        checks += " && ! systemctl is-active --quiet NetworkManager sshd systemd-networkd systemd-resolved systemd-timesyncd"
        checks += ' && guestScratch=$(mktemp -d /root/rescue-check.XXXXXX) && ddrescue --quiet --size=65536 /dev/sr0 "$guestScratch/boot-sector.bin" "$guestScratch/map" && test $(stat -c%s "$guestScratch/boot-sector.bin") -eq 65536 && test "$(dd if=/dev/sr0 bs=65536 count=1 status=none | sha256sum | cut -d " " -f1)" = "$(sha256sum "$guestScratch/boot-sector.bin" | cut -d " " -f1)"'
        checks += " && cryptsetup --version && ddrescue --version && testdisk /version && smartctl --version && nvme version && parted --version && sgdisk --version && btrfs version && xfs_repair -V && tmux -V && file --version && lsblk && nix-store --verify --check-contents"
    else:
        checks += " && command -v nixos-install nixos-generate-config && PAGER=cat MANPAGER=cat nixos-install --help && PAGER=cat MANPAGER=cat nixos-generate-config --help"
    # Split the success marker so its echoed command cannot be mistaken for output.
    guest = "sudo -n sh -c '" + checks + ' && printf "KHANELINIX_%s_OK\\n" UEFI\'\n'
    try:
        with (args.evidence / "serial.log").open("wb") as log:
            while time.monotonic() < deadline and process.poll() is None:
                for key, _ in selector.select(timeout=1):
                    chunk = os.read(key.fd, 65536)
                    if not chunk:
                        break
                    log.write(chunk)
                    log.flush()
                    output += chunk
                    terminal = re.sub(
                        rb"\x1b\].*?(?:\x07|\x1b\\)", b"", output, flags=re.DOTALL
                    )
                    terminal = re.sub(rb"\x1b\[[0-?]*[ -/]*[@-~]", b"", terminal)
                    if not sent and re.search(rb"\[nixos@[^\r\n]+\].*\$", terminal):
                        process.stdin.write(guest.encode())
                        process.stdin.flush()
                        sent = True
                    if b"KHANELINIX_UEFI_OK" in output:
                        success = True
                        break
                if success:
                    break
    finally:
        selector.close()
        process.terminate()
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
    (args.evidence / "result.txt").write_text(
        f"bootedPrompt={sent}\nchecksPassed={success}\n"
    )
    raise SystemExit(0 if success else 1)
