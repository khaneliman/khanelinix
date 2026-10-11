function bak
    if test (count $argv) -ne 1
        echo "1 path must be supplied"
        return 1
    end
    if test -z "$argv[1]"
        return 1
    end
    set -l file (path basename -- "$argv[1]")
    set -l directory (path dirname -- "$argv[1]")
    set -l target "$directory/$file"
    set -l other "$target.bak"
    if string match -q '*.bak' -- "$file"; and test "$file" != .bak
        set other "$target"
    end
    if test -e "$target"; or test -L "$target"
        if test -e "$other"; or test -L "$other"
            # Keep recovery data beside the originals, without a reusable swap name.
            set -l temporary "$(command mktemp -d -- "$directory/.bak.XXXXXXXXXX")"
            or return 1
            set -l saved "$temporary/original"
            set -l failed 0
            if command mv -- "$target" "$saved"
                if command mv -- "$other" "$target"
                    if not command mv -- "$saved" "$other"
                        set failed 1
                        if not test -e "$other"; and not test -L "$other"; and command mv -- "$target" "$other"
                            if not test -e "$target"; and not test -L "$target"
                                command mv -- "$saved" "$target"
                            end
                        end
                    end
                else
                    set failed 1
                    if not test -e "$target"; and not test -L "$target"
                        command mv -- "$saved" "$target"
                    end
                end
            else
                set failed 1
            end
            # Never remove a nonempty recovery directory, even if rollback failed.
            if not command rmdir -- "$temporary"
                printf 'bak: swap incomplete; inspect "%s", "%s", and retained recovery directory "%s"\n' "$target" "$other" "$temporary" >&2
                return 1
            end
            return $failed
        else
            command mv -- "$target" "$other"
        end
    else
        if test -e "$other"; or test -L "$other"
            command mv -- "$other" "$target"
        else
            echo "Neither $argv[1] nor $other exist"
            return 1
        end
    end
end
