#!/usr/bin/env bash
# Pass the rendered writeShellApplication script, not extracted Nix text.
source "$1"
set -euo pipefail

YABAI_WINDOW_ID=20
calls=''
yabai() {
    if [[ $* == '-m query --windows' ]]; then
        printf '%s\n' "$windows"
    else
        calls+="$*"
    fi
}

check() {
    windows=$1
    calls=''
    auto_stack "$2"
    [[ $calls == "$3" ]] || {
        printf 'Expected <%s>, got <%s>\n' "$3" "$calls" >&2
        exit 1
    }
}

check '[{"app":"Code","id":10},{"app":"Code","id":20}]' Code '-m window 10 --stack 20'
check '[{"app":"Code","id":20},{"app":"Code","id":10}]' Code '-m window 10 --stack 20'
check '[{"app":"Code","id":20}]' Code ''
check '[{"app":"Other","id":10},{"app":"Code","id":20}]' Code ''
check '[]' Code ''
check '[{"app":"Code","id":10},{"app":"Code","id":30},{"app":"Code","id":20}]' Code '-m window 10 --stack 20'
check '[{"app":"A \"quoted\" app","id":10},{"app":"A \"quoted\" app","id":20}]' 'A "quoted" app' '-m window 10 --stack 20'
printf 'auto_stack peer selection and no-peer cases passed\n'
