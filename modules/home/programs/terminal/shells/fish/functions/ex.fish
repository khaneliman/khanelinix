function ex
    if test (count $argv) -ne 1
        echo "1 archive path must be supplied"
        return 1
    end
    if test -f "$argv[1]"
        set filename (basename -- "$argv[1]")
        set foldername (echo $filename | sed 's/\.[^.]*$//')
        mkdir -p -- "$foldername"; or return
        switch $argv[1]
            case '*.tar.bz2'
                tar xjf $argv[1] -C $foldername
            case '*.tar.gz'
                tar xzf $argv[1] -C $foldername
            case '*.bz2' '*.gz' '*.Z'
                set -l destination "./$foldername/"(string replace -r '\.(bz2|gz|Z)$' '' -- "$filename")
                set -l temporary "$(command mktemp -d -- "./$foldername/.ex.XXXXXXXXXX")"
                or return 1
                # Seed regular-file permissions and ACLs before writing new bytes.
                if test -f "$destination"; and not test -L "$destination"
                    command cp -p "$destination" "$temporary/output"
                    set -l copied $status
                    if test $copied -ne 0
                        command rm -f -- "$temporary/output"
                        command rmdir -- "$temporary"
                        return $copied
                    end
                end
                switch $argv[1]
                    case '*.bz2'
                        bunzip2 -c -- "$argv[1]" >"$temporary/output"
                    case '*.gz'
                        gunzip -c -- "$argv[1]" >"$temporary/output"
                    case '*.Z'
                        uncompress -c "$argv[1]" >"$temporary/output"
                end
                set -l result $status
                if test $result -eq 0
                    if test -d "$destination"
                        printf 'ex: "%s" is a directory\n' "$destination" >&2
                        set result 1
                    else
                        command mv -- "$temporary/output" "$destination"
                        set result $status
                    end
                end
                command rm -f -- "$temporary/output"
                command rmdir -- "$temporary"
                return $result
            case '*.rar'
                unrar x $argv[1] ./$foldername/
            case '*.tar'
                tar xf $argv[1] -C ./$foldername/
            case '*.tbz2'
                tar xjf $argv[1] -C ./$foldername/
            case '*.tgz'
                tar xzf $argv[1] -C ./$foldername/
            case '*.zip'
                unzip -d "./$foldername/" "$argv[1]"
            case '*.7z'
                7z x "$argv[1]" "-o./$foldername/"
            case '*'
                echo "'$filename' cannot be extracted via ex()"
                return 1
        end
    else
        echo "'$argv[1]' is not a valid file"
        return 1
    end
end
