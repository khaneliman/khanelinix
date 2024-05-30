# Enable Vi mode
bindkey -v

# C-right / C-left for word skips
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# C-Backspace / C-Delete for word deletions
# bindkey "^[[3;5~" forward-kill-word
bindkey "^H" backward-kill-word

# Home/End
bindkey "^[[OH" beginning-of-line
bindkey "^[[OF" end-of-line

# Use vim keys in the tab complete menu
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

bindkey "^A" vi-beginning-of-line
bindkey "^E" vi-end-of-line
