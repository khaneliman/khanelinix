import os
import subprocess

from ranger.api.commands import Command
from ranger.ext.get_executables import get_executables


def show_error_in_console(msg, fm):
    fm.notify(msg, bad=True)


def navigate_path(fm, selected):
    if not selected:
        return

    selected = os.path.abspath(selected)
    if os.path.isdir(selected):
        fm.cd(selected)
    elif os.path.isfile(selected):
        fm.select_file(selected)
    else:
        show_error_in_console(f"Neither directory nor file: {selected}", fm)
        return


def select_with_fzf(fzf_cmd, input, fm):
    fm.ui.suspend()
    try:
        # stderr is used to open to attach to /dev/tty
        proc = subprocess.Popen(
            fzf_cmd, stdout=subprocess.PIPE, stdin=subprocess.PIPE, text=True
        )
        stdout, _ = proc.communicate(input=input)

        # ESC gives 130
        if proc.returncode not in [0, 130]:
            raise Exception(
                f"Bad process exit code: {proc.returncode}, stdout={stdout}"
            )
    finally:
        fm.ui.initialize()
    return stdout.strip()


class dir_history_navigate(Command):
    def execute(self):
        lst = []
        for d in reversed(self.fm.tabs[self.fm.current_tab].history.history):
            lst.append(d.path)

        fm = self.fm
        selected = select_with_fzf(["fzf"], "\n".join(lst), fm)

        navigate_path(fm, selected)
