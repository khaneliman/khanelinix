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
            case '*.bz2'
                bunzip2 -c -- "$argv[1]" >"./$foldername/"(basename -- "$argv[1]" .bz2)
            case '*.rar'
                unrar x $argv[1] ./$foldername/
            case '*.gz'
                gunzip -c -- "$argv[1]" >"./$foldername/"(basename -- "$argv[1]" .gz)
            case '*.tar'
                tar xf $argv[1] -C ./$foldername/
            case '*.tbz2'
                tar xjf $argv[1] -C ./$foldername/
            case '*.tgz'
                tar xzf $argv[1] -C ./$foldername/
            case '*.zip'
                unzip -d "./$foldername/" "$argv[1]"
            case '*.Z'
                uncompress -c "$argv[1]" >"./$foldername/"(basename -- "$argv[1]" .Z)
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
