#!/usr/bin/env python3

import argparse
import fcntl
import json
import os
import re
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

IMAGES_FILE = Path("systems/x86_64-linux/khanelilab/images.nix")
DIGEST = r"sha256:[0-9a-f]{64}"
TAG = r"[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}"
PIN = re.compile(
    r'[ \t]+[A-Za-z0-9_-]+[ \t]*=[ \t]*"'
    rf'(?P<image>[a-z0-9][a-z0-9._:/-]*(?::{TAG})?)@(?P<digest>{DIGEST})";'
    r"[ \t]*(?:#[^\r\n]*)?"
)


def tracked_images_file() -> Path:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=True,
    )
    root = Path(result.stdout.rstrip("\n")).resolve()
    subprocess.run(
        ["git", "ls-files", "--error-unmatch", "--", str(IMAGES_FILE)],
        cwd=root,
        capture_output=True,
        text=True,
        check=True,
    )
    return root / IMAGES_FILE


def file_mode(path: Path) -> int:
    mode = path.lstat().st_mode
    if not stat.S_ISREG(mode) or path.resolve() != path:
        raise ValueError(f"{path} must be a regular file in the checkout")
    return stat.S_IMODE(mode)


def find_pin(source: str, container: str) -> tuple[re.Match[str], int]:
    # Only edit literal assignments in the current pin map, not block comments.
    if "/*" in source:
        raise ValueError(f"unsupported block comment in {IMAGES_FILE}")
    entries = list(
        re.finditer(
            rf"^[ \t]+{re.escape(container)}[ \t]*=[^\r\n]*", source, re.MULTILINE
        )
    )
    if len(entries) != 1 or (pin := PIN.fullmatch(entries[0][0])) is None:
        raise ValueError(
            f"expected one literal SHA-256 pin for {container} in {IMAGES_FILE}"
        )
    return pin, entries[0].start()


def source_reference(image: str, requested_tag: str | None) -> str:
    # A registry port is not an image tag.
    _, separator, pinned_tag = image.rsplit("/", 1)[-1].partition(":")
    if separator:
        if requested_tag is not None and requested_tag != pinned_tag:
            raise ValueError(
                f"{image} already selects tag {pinned_tag}; refusing to retag"
            )
        tag = pinned_tag
        reference = image
    else:
        if requested_tag is None:
            raise ValueError(f"{image} has no pinned tag; supply --tag explicitly")
        tag = requested_tag
        reference = f"{image}:{tag}"
    if not re.fullmatch(TAG, tag):
        raise ValueError(f"invalid OCI tag: {tag!r}")
    return reference


def inspect_digest(reference: str) -> str:
    result = subprocess.run(
        [
            "skopeo",
            "--override-os",
            "linux",
            "--override-arch",
            "amd64",
            "inspect",
            "--no-tags",
            f"docker://{reference}",
        ],
        capture_output=True,
        text=True,
        check=True,
        timeout=60,
    )
    try:
        metadata = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise ValueError(f"{reference}: invalid JSON from skopeo") from error
    digest = metadata.get("Digest") if isinstance(metadata, dict) else None
    if not isinstance(digest, str) or not re.fullmatch(DIGEST, digest):
        raise ValueError(f"{reference}: skopeo did not return a valid SHA-256 digest")
    if (metadata.get("Os"), metadata.get("Architecture")) != ("linux", "amd64"):
        raise ValueError(f"{reference}: skopeo did not resolve a linux/amd64 image")
    return digest


def replace_pin_file(path: Path, original: bytes, updated: bytes, mode: int) -> None:
    # Lock the directory so two updater runs cannot race across an atomic rename.
    directory = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
    try:
        fcntl.flock(directory, fcntl.LOCK_EX)
        with tempfile.NamedTemporaryFile(
            prefix=".images.nix.tmp-", dir=path.parent, delete=False
        ) as temporary:
            replacement = Path(temporary.name)
            try:
                temporary.write(updated)
                temporary.flush()
                os.fchmod(temporary.fileno(), mode)
                os.fsync(temporary.fileno())
                if file_mode(path) != mode or path.read_bytes() != original:
                    raise ValueError(
                        f"{path} changed during the lookup; run the updater again"
                    )
                replacement.replace(path)
            finally:
                replacement.unlink(missing_ok=True)
    finally:
        os.close(directory)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="update-container-digests",
        description="Check or update one khanelilab image pin.",
    )
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument(
        "--check", action="store_true", help="report drift without writing (default)"
    )
    modes.add_argument(
        "--update", action="store_true", help="replace only the selected digest"
    )
    parser.add_argument("container", help="container name in khanelilab's images.nix")
    parser.add_argument("--tag", help="explicit registry tag for a pin without a tag")
    args = parser.parse_args(argv)

    try:
        path = tracked_images_file()
        mode = file_mode(path)
        original = path.read_bytes()
        source = original.decode("utf-8")
        pin, offset = find_pin(source, args.container)
        reference = source_reference(pin["image"], args.tag)
        digest = inspect_digest(reference)
        if digest == pin["digest"]:
            print(f"{args.container}: {reference} matches {digest}")
            return 0

        if args.update:
            start, end = pin.span("digest")
            updated = source[: offset + start] + digest + source[offset + end :]
            replace_pin_file(path, original, updated.encode("utf-8"), mode)
        action = "updated" if args.update else "differs"
        print(f"{args.container}: {reference} {action}: {pin['digest']} -> {digest}")
        return 0 if args.update else 1
    except subprocess.CalledProcessError as error:
        print(f"{parser.prog}: {error.stderr.strip() or error}", file=sys.stderr)
    except (OSError, ValueError, subprocess.TimeoutExpired) as error:
        print(f"{parser.prog}: {error}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
