function mkcd
    mkdir -p $argv; or return
    cd $argv
end
