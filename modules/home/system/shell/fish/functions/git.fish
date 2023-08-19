# Add custom git extensions
function git
    set -l code
    
    # Truncate long lines in git grep
    if test "$argv[1]" = "grep"
        
        if ! command -v perl &>/dev/null
            command git $argv
            return
        end

        command git -c color.ui=always $argv | perl -pe 'my $truncate = 500; (my $blank = $_) =~ s/\e\[[^m]*m//g; if (length $blank > $truncate) {
            s/^((?:(?:\e\[[^m]*m)+(?:.|$)|.(?:\e\[[^m]*m)*|$(*SKIP)(*FAIL)){$truncate})(?=(?:(?:\e\[[^m]*m)+(?:.|$)|.(?:\e\[[^m]*m)*|$(*SKIP)(*FAIL)){15}).*/$1\e\[m...(truncated)/
        }'
        
        return
    end
    
    # Prevent accidental git commit -a
    if test "$argv[1]" = "commit"  && contains -- "$argv[2]" "-a"
        if ! command git diff-index --cached --quiet HEAD -- && ! command git diff-files --quiet
            
            echo >&2 '\e[0;31mERROR!\e[0m Changes are already staged. Preventing git commit -a'
            echo >&2 '\e[0;31mERROR!\e[0m Run git commit without -a or run git reset HEAD first'
            
            return 1
        end
    end
    
    # forward original git command
    if test -n "$argv"
        command git $argv
    else
        command git
    end

    # record command exit code
    set code $status
    
    # output commit length if successful
    if test "$argv[1]" = "commit"  && ! code
        printf 'Commit subject length: '
        command git log -1 --format="%s" | tr -d '\n' | wc -m | awk '{print $1}'
    end
    
    # return original exit code
    return $code
end

