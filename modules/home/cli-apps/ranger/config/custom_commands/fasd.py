from ranger.api.commands import Command


class fasd(Command):
    """
    :fasd

    Jump to directory using fasd
    """

    def execute(self):
        args = self.rest(1).split()
        if args:
            directories = self._get_directories(*args)
            if directories:
                self.fm.cd(directories[0])
            else:
                self.fm.notify("No results from fasd", bad=True)

    def tab(self, tabnum):
        start, current = self.start(1), self.rest(1)
        for path in self._get_directories(*current.split()):
            yield start + path

    @staticmethod
    def _get_directories(*args):
        import subprocess

        output = subprocess.check_output(
            ["fasd", "-dl"] + list(args), universal_newlines=True
        )
        dirs = output.strip().split("\n")
        dirs.sort(reverse=True)  # Listed in ascending frecency
        return dirs
