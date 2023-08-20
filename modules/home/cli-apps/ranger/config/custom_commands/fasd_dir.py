from ranger.api.commands import Command


class fasd_dir(Command):
    def execute(self):
        import os.path
        import subprocess

        fzf = self.fm.execute_command(
            "fasd -dl | grep -iv cache | fzf 2>/dev/tty",
            universal_newlines=True,
            stdout=subprocess.PIPE,
        )
        stdout, stderr = fzf.communicate()
        if fzf.returncode == 0:
            fzf_file = os.path.abspath(stdout.rstrip("\n"))
            print(fzf_file)
            if os.path.isdir(fzf_file):
                self.fm.cd(fzf_file)
            else:
                self.fm.select_file(fzf_file)
