import contextlib
import importlib.util
import io
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT_PATH = (
    Path(sys.argv.pop(1))
    if len(sys.argv) > 1
    else Path(__file__).with_name("mp4-to-mkv.py")
)
spec = importlib.util.spec_from_file_location("converter", SCRIPT_PATH)
converter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(converter)


class ConversionTests(unittest.TestCase):
    def test_failure_preserves_source_and_destination(self):
        for existing in (False, True):
            for failure in (
                "ffmpeg",
                "missing",
                "small",
                "oserror",
                "interrupt",
                "publish",
            ):
                with (
                    self.subTest(existing=existing, failure=failure),
                    tempfile.TemporaryDirectory() as directory,
                ):
                    source = Path(directory, "movie.mp4")
                    destination = source.with_suffix(".mkv")
                    source.write_bytes(b"source" * 100)
                    if existing:
                        destination.write_bytes(b"previous MKV")

                    def run(cmd, failure=failure, **kwargs):
                        staged = Path(cmd[-1])
                        self.assertEqual(cmd[cmd.index("-map") + 1], "0")
                        self.assertEqual(cmd[cmd.index("-c") + 1], "copy")
                        if failure != "missing":
                            staged.write_bytes(
                                b"x" * (100 if failure == "small" else 500)
                            )
                        if failure == "ffmpeg":
                            raise subprocess.CalledProcessError(1, cmd)
                        if failure == "oserror":
                            raise OSError("cannot run ffmpeg")
                        if failure == "interrupt":
                            raise KeyboardInterrupt

                    with (
                        patch.object(converter.subprocess, "run", side_effect=run),
                        contextlib.redirect_stdout(io.StringIO()),
                    ):
                        if failure == "interrupt":
                            with self.assertRaises(KeyboardInterrupt):
                                converter.convert_to_mkv(
                                    str(source), delete_source=True
                                )
                        elif failure == "publish":
                            with patch.object(
                                converter.os,
                                "replace",
                                side_effect=OSError("cannot publish"),
                            ):
                                converter.convert_to_mkv(
                                    str(source), delete_source=True
                                )
                        else:
                            converter.convert_to_mkv(str(source), delete_source=True)
                    self.assertEqual(source.read_bytes(), b"source" * 100)
                    if existing:
                        self.assertEqual(destination.read_bytes(), b"previous MKV")
                    else:
                        self.assertFalse(destination.exists())
                    self.assertFalse(list(Path(directory).glob(".mp4-to-mkv-*")))

    def test_success_publishes_before_optional_deletion(self):
        for delete in (False, True):
            with (
                self.subTest(delete=delete),
                tempfile.TemporaryDirectory() as directory,
            ):
                source = Path(directory, "movie.mp4")
                destination = source.with_suffix(".mkv")
                source.write_bytes(b"s" * 1000)
                destination.write_bytes(b"old")

                def run(cmd, destination=destination, **kwargs):
                    self.assertEqual(destination.read_bytes(), b"old")
                    Path(cmd[-1]).write_bytes(b"new MKV" * 100)

                with (
                    patch.object(converter.subprocess, "run", side_effect=run),
                    patch.object(
                        sys,
                        "argv",
                        ["converter", directory, *(["--delete"] if delete else [])],
                    ),
                    contextlib.redirect_stdout(io.StringIO()),
                ):
                    converter.main()
                self.assertEqual(destination.read_bytes(), b"new MKV" * 100)
                self.assertEqual(source.exists(), not delete)
                self.assertFalse(list(Path(directory).glob(".mp4-to-mkv-*")))

    def test_existing_complete_output_and_interactive_decline_are_untouched(self):
        for complete in (False, True):
            with (
                self.subTest(complete=complete),
                tempfile.TemporaryDirectory() as directory,
            ):
                source = Path(directory, "movie.mp4")
                source.write_bytes(b"s" * 1000)
                destination = source.with_suffix(".mkv")
                original = b"m" * (1000 if complete else 10)
                destination.write_bytes(original)
                with (
                    patch.object(converter.subprocess, "run") as run,
                    patch("builtins.input", return_value="n"),
                    contextlib.redirect_stdout(io.StringIO()),
                ):
                    converter.convert_to_mkv(
                        str(source), delete_source=True, interactive=True
                    )
                run.assert_not_called()
                self.assertEqual(destination.read_bytes(), original)
                self.assertTrue(source.exists())


if __name__ == "__main__":
    unittest.main()
