function mvcd -d "Moves files and directories and changes the current directory"
    if test (count $argv) -gt 1
        mkdir -p $argv[2]; or return
        mv $argv[1] $argv[2]; or return
        cd $argv[2]
    end
end
