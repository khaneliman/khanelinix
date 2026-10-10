function cd --description 'change directory and run onefetch if a git directory'
    # navigate to root of git repo
    if test (count $argv) -eq 1; and test "$argv[1]" = ":/"
        set -l top (command git rev-parse --show-toplevel)
        or return $status
        builtin cd -- "$top[1]"
    else if test (count $argv) -eq 1; and test -f "$argv[1]"
        # check if cd to file and route to parent
        builtin cd -- (dirname -- "$argv[1]")
    else
        builtin cd $argv
    end

    set -l cdStatus $status
    if test $cdStatus -ne 0
        return $cdStatus
    end

    # check for git information
    command git rev-parse 2>/dev/null

    if test $status -eq 0
        if test -z "$LAST_REPO" -o "$LAST_REPO" != $(basename $(command git rev-parse --show-toplevel))
            onefetch
            set -g LAST_REPO $(basename $(command git rev-parse --show-toplevel))
        end
    end
    return $cdStatus
end
