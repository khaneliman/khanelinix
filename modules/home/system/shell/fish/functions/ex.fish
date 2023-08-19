function ex
    if test -f $argv[1]
        set filename (basename $argv[1])
        set foldername (echo $filename | sed 's/\.[^.]*$//')
        mkdir -p $foldername
        switch $argv[1]
            case '*.tar.bz2'
                tar xjf $argv[1] -C $foldername
            case '*.tar.gz'
                tar xzf $argv[1] -C $foldername
            case '*.bz2'
                bunzip2 -k $argv[1]
                mv (basename $argv[1] .bz2) ./$foldername/
            case '*.rar'
                unrar x $argv[1] ./$foldername/
            case '*.gz'
                gunzip -k $argv[1]
                mv (basename $argv[1] .gz) ./$foldername/
            case '*.tar'
                tar xf $argv[1] -C ./$foldername/
            case '*.tbz2'
                tar xjf $argv[1] -C ./$foldername/
            case '*.tgz'
                tar xzf $argv[1] -C ./$foldername/
            case '*.zip'
                unzip  -d ./$foldername/  "$filename"
            case '*.Z'
                uncompress  "$filename"
                 mv (basename "$filename" ".Z") "./$foldername/"
            case '*.7z'
                 7z x "$filename" "-o./$foldername/"
             otherwise
                 echo "'$filename' cannot be extracted via ex()"
        end
    else
        echo "'$filename' is not a valid file"
    end
end
