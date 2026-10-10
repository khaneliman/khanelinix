"""Exercise the real C handler and queue with only Darwin services stubbed."""

import os
import shlex
import shutil
import subprocess
import tempfile
from pathlib import Path

package = Path(__file__).resolve().parent.parent
cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
cache.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix="island-regression-", dir=cache) as directory:
    scratch = Path(directory)
    for name in ("islandhelper.c", "dynamicisland.h"):
        shutil.copyfile(package / name, scratch / name)
    shutil.copyfile(package / "tests/regression.c", scratch / "regression.c")
    (scratch / "notificationhelper.h").write_text(
        '#include "dynamicisland.h"\n'
        "struct notificationHelper { int unused; };\n"
        "static void database_init(struct notificationHelper *h) { (void)h; }\n"
        "static struct islandItem *check_notifications(struct notificationHelper *h) "
        "{ (void)h; return NULL; }\n"
    )
    (scratch / "sketchybar.h").write_text(
        "struct test_env { char *sender; char *id; char *args; };\n"
        "typedef struct test_env *env;\n"
        "static int sent;\n"
        "static char *env_get_value_for_key(env e, char *key) {\n"
        '  if (strcmp(key, "SENDER") == 0) return e->sender;\n'
        '  if (strcmp(key, "INFO") == 0) return e->id;\n'
        "  return e->args;\n"
        "}\n"
        "static void sketchybar(char *command) { (void)command; ++sent; }\n"
        "static void event_server_begin(void (*handler)(env), char *name) "
        "{ (void)handler; (void)name; }\n"
    )
    command = shlex.split(os.environ.get("CC", "cc"))
    command += [
        "-std=c99",
        "-g",
        "-O1",
        "-fsanitize=address,undefined",
        "-fno-omit-frame-pointer",
        "regression.c",
        "-o",
        "regression",
    ]
    subprocess.run(command, cwd=scratch, check=True)
    subprocess.run([str(scratch / "regression")], check=True)
