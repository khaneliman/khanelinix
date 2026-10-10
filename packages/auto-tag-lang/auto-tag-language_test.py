import contextlib
import importlib.util
import io
import os
import subprocess
import sys
import tempfile
import types
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

SCRIPT_PATH = (
    Path(sys.argv.pop(1))
    if len(sys.argv) > 1
    else Path(__file__).with_name("auto-tag-language.py")
)
whisper = types.ModuleType("whisper")
whisper.load_model = Mock(return_value=object())
with patch.dict(sys.modules, whisper=whisper):
    spec = importlib.util.spec_from_file_location("tagger", SCRIPT_PATH)
    tagger = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(tagger)


class ExtractionTests(unittest.TestCase):
    def test_failed_track_never_detected_or_tagged(self):
        for failure in ("partial", "missing", "oserror", "empty_success"):
            with (
                self.subTest(failure=failure),
                tempfile.TemporaryDirectory() as directory,
            ):
                sentinel = Path(directory, "temp_whisper_sample.wav")
                sentinel.write_bytes(b"unrelated audio")
                paths = []
                candidates = [
                    {"path": name, "index": 2, "mkv_num": 1}
                    for name in ("good.mkv", "bad.mkv", "next.mkv")
                ]

                def run(cmd, paths=paths, failure=failure, **kwargs):
                    sample = Path(cmd[-1])
                    paths.append(sample)
                    if cmd[cmd.index("-i") + 1] == "bad.mkv":
                        if failure == "partial":
                            sample.write_bytes(b"partial")
                        if failure == "oserror":
                            raise OSError("ffmpeg unavailable")
                        if failure != "empty_success":
                            if kwargs.get("check"):
                                raise subprocess.CalledProcessError(1, cmd)
                            return subprocess.CompletedProcess(cmd, 1)
                    else:
                        sample.write_bytes(b"fresh audio")

                def detect(model, path):
                    self.assertEqual(Path(path).read_bytes(), b"fresh audio")
                    return "en", 0.99

                previous = os.getcwd()
                try:
                    os.chdir(directory)
                    with (
                        patch.object(tagger, "check_dependencies"),
                        patch.object(
                            tagger, "get_undef_audio_files", return_value=candidates
                        ),
                        patch.object(
                            tagger.subprocess, "check_output", return_value=b"60"
                        ),
                        patch.object(tagger.subprocess, "run", side_effect=run),
                        patch.object(
                            tagger, "detect_language", side_effect=detect
                        ) as detection,
                        patch.object(tagger, "update_metadata") as update,
                        patch.object(sys, "argv", ["tagger", directory, "--apply"]),
                        contextlib.redirect_stdout(io.StringIO()),
                    ):
                        tagger.main()
                    self.assertEqual(detection.call_count, 2)
                    self.assertEqual(
                        [call.args[0] for call in update.call_args_list],
                        ["good.mkv", "next.mkv"],
                    )
                    self.assertEqual(len(set(paths)), 3)
                    self.assertTrue(all(not path.parent.exists() for path in paths))
                    self.assertEqual(sentinel.read_bytes(), b"unrelated audio")
                finally:
                    os.chdir(previous)

    def test_dry_run_and_confidence_are_preserved(self):
        for flags, probability in (([], 0.99), (["--apply"], 0.5)):
            with self.subTest(flags=flags, probability=probability):

                def run(cmd, **kwargs):
                    Path(cmd[-1]).write_bytes(b"audio")

                with (
                    patch.object(tagger, "check_dependencies"),
                    patch.object(
                        tagger,
                        "get_undef_audio_files",
                        return_value=[{"path": "movie.mkv", "index": 1, "mkv_num": 1}],
                    ),
                    patch.object(tagger.subprocess, "check_output", return_value=b"60"),
                    patch.object(tagger.subprocess, "run", side_effect=run),
                    patch.object(
                        tagger, "detect_language", return_value=("en", probability)
                    ),
                    patch.object(tagger, "update_metadata") as update,
                    patch.object(sys, "argv", ["tagger", "movie.mkv", *flags]),
                    contextlib.redirect_stdout(io.StringIO()),
                ):
                    tagger.main()
                update.assert_not_called()


if __name__ == "__main__":
    unittest.main()
