# Key bindings overrides
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
bind-key -T copy-mode-vi Escape send-keys -X cancel
bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
bind '"' split-window -v  -c '#{pane_current_path}'
bind '%' split-window -h -c '#{pane_current_path}'

set-option -sa terminal-features ",*xterm*:RGB"
set -ga terminal-overrides ",xterm-kitty:Tc"

set -g allow-passthrough on
set -ga update-environment TERM
set -ga update-environment TERM_PROGRAM

set -g set-titles
