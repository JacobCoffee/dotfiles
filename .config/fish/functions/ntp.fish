function ntp
    set venv_flag 0
    set dir_name ""

    for arg in $argv
        switch $arg
            case '-v' '--venv'
                set venv_flag 1
            case '*'
                set dir_name $arg
        end
    end

    if test -z "$dir_name"
        echo "Usage: ntp [-v --venv] <word>"
        return 1
    end

    set dir "/tmp/testing/$dir_name"

    if test -d "$dir"
        echo "Directory $dir already exists. Delete it? [y/N]"
        read -l confirm
        if test "$confirm" != "y"
            echo "Aborted."
            return 1
        end
        rm -r "$dir"
        echo "Deleted directory $dir."
    end

    mkdir -p $dir
    cd $dir
    echo "Directory $dir created and switched to."

    if test $venv_flag -eq 1
        python3 -m venv venv
        source venv/bin/activate.fish
        echo "Virtual environment created and activated."
    end
end
