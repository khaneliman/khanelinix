function bak
    if [ (count $argv) -ne 1 ]
        echo "1 path must be supplied"
        return 1
    end
    set file (basename $argv[1] '.bak')
    set other "$file.bak"
    if test -e $argv[1]
        if test -e $other
            mv $argv[1] $other.tmp
            mv $other $argv[1]
            mv $other.tmp $other
        else
            mv $argv[1] $other
        end
    else
        if test -e $other
            mv $other $argv[1]
        else
            echo "Neither $argv[1] nor $other exist"
            return 1
        end
    end
end
