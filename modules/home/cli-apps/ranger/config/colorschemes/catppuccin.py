# Austin Horstman <khaneliman12@gmail.com>, 2023
# Catppuccin like colorscheme for https://github.com/hut/ranger .
# This software is distributed under the terms of the GNU GPL version 3.

from ranger.gui.color import *
from ranger.gui.colorscheme import ColorScheme

##
# Catppuccin Color Palette
##
# Base 234
# Mantle 233
# Crust 232

# Overlay1.5 103

# Red 211
# Pink 218
# Flamingo 224
# Blue 111
# Peach 180
# yellow 229
# Green 156
# Teal 116
# Sapphire 123
# Sky 159
# Lavender 147


# pylint: disable=too-many-branches,too-many-statements
class Catppuccin(ColorScheme):
    progress_bar_color = 156

    def use(self, context):
        fg, bg, attr = default_colors

        if context.reset:
            return default_colors

        if context.in_browser:
            if context.selected:
                attr = reverse
            else:
                attr = normal
            if context.empty or context.error:
                fg = 211
                bg = 234
            if context.border:
                fg = 111
            if context.image:
                fg = 224
            if context.video:
                fg = 147
            if context.audio:
                fg = 116
            if context.document:
                fg = 159
            if context.container:
                attr |= bold
                fg = 211
            if context.directory:
                attr |= bold
                fg = 111
            elif context.executable and not any(
                (context.media, context.container, context.fifo, context.socket)
            ):
                attr |= bold
                fg = 123
            if context.socket:
                fg = 180
                attr |= bold
            if context.fifo or context.device:
                fg = 103
                if context.device:
                    attr |= bold
            if context.link:
                fg = 156 if context.good else 211
                bg = default
            if context.bad:
                bg = default
            if context.tag_marker and not context.selected:
                attr |= bold
                if fg in (211, 95):
                    fg = 218
                else:
                    fg = 211
            if not context.selected and (context.cut or context.copied):
                fg = 123
                bg = 234
            if context.main_column:
                if context.selected:
                    attr |= bold
                if context.marked:
                    attr |= bold
                    fg = 223
            if context.badinfo:
                if attr & reverse:
                    bg = 211
                else:
                    fg = 211
        if context.in_titlebar:
            if context.hostname:
                if context.good:
                    fg = 156
                elif context.bad:
                    fg = 211
            else:
                fg = default

        if context.in_taskview:
            fg = 156

        if context.in_statusbar:
            if context.permissions:
                if context.good:
                    fg = 156
                elif context.bad:
                    fg = 211
            if context.message:
                if context.good:
                    attr |= bold
                    fg = 156
                elif context.bad:
                    attr |= bold
                    fg = 211
            if context.marked:
                attr |= bold | reverse
                fg = 229
                fg += BRIGHT
            if context.frozen:
                attr |= bold | reverse
                fg = 116
                fg += BRIGHT
            if context.loaded:
                bg = self.progress_bar_color
            if context.vcsinfo:
                fg = 111
                attr &= ~bold
            if context.vcscommit:
                fg = 229
                attr &= ~bold
            if context.vcsdate:
                fg = 116
                attr &= ~bold

        return fg, bg, attr
