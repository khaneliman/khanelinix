function cd --description 'change directory and run onefetch if a git directory' 
    set -l parent
    
    # navigate to root of git repo
    if [ $argv = ":/" ]
        set -l top  (command git rev-parse --show-cdup)
        builtin cd $top;
    # check if cd to file and route to parent
    else if [ -f $argv ] && [ -e $argv ] 
        set parent (dirname $argv)
        if [ "$parent" != . ] && [ -d "$parent" ]
            builtin cd "$parent";
        end
    # if navigating to a directory, cd as usual
    else if [ -d $argv ]
        if test -n "$argv" && 
            builtin cd "$argv";
        else 
            builtin cd;
        end
    end

    # check for git information
    git rev-parse 2>/dev/null;

    if test $status -eq 0
        if test -z "$LAST_REPO" -o "$LAST_REPO" != $(basename $(git rev-parse --show-toplevel)) 
            onefetch
            set -g LAST_REPO $(basename $(git rev-parse --show-toplevel))
        end
    end
end
