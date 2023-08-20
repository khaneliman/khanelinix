from ranger.api.commands import Command


class show_files_in_finder(Command):
    """
    :show_files_in_finder

    Present selected files in finder
    """

    def execute(self):
        import subprocess

        files = ",".join(
            [
                '"{0}" as POSIX file'.format(file.path)
                for file in self.fm.thistab.get_selection()
            ]
        )
        reveal_script = 'tell application "Finder" to reveal {{{0}}}'.format(files)
        activate_script = 'tell application "Finder" to set frontmost to true'
        script = "osascript -e '{0}' -e '{1}'".format(reveal_script, activate_script)
        self.fm.notify(script)
        subprocess.check_output(
            ["osascript", "-e", reveal_script, "-e", activate_script]
        )
