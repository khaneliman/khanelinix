set-option -sa terminal-overrides ",xterm*:Tc"
set -g default-terminal "xterm-kitty"
set -g mouse on

set -g base-index 1
set -g pane-base-index 1
set-window-option -g pane-base-index 1
set-option -g renumber-windows on
set-option -sa terminal-features ',xterm-kitty:RGB'

# Prefix override
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Key bindings overrides
set-window-option -g mode-keys vi
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
bind-key -T copy-mode-vi Escape send-keys -X cancel
bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
bind '"' split-window -v  -c '#{pane_current_path}'
bind '%' split-window -h -c '#{pane_current_path}'

##
# Plugins
##
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'christoomey/vim-tmux-navigator'
# set -g @plugin 'catppuccin/tmux'
set -g @plugin 'dreamsofcode-io/catppuccin-tmux'
set -g @catppuccin_flavour 'macchiato'
set -g @plugin 'tmux-plugins/tmux-yank'

# tmux-resurrect
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @resurrect-capture-pane-contents 'on'

# Install plugin manager and plugins
if "test ! -d ~/.tmux/plugins/tpm" \
   "run 'git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && ~/.tmux/plugins/tpm/bin/install_plugins'"

# Source tpm
run '~/.tmux/plugins/tpm/tpm'
