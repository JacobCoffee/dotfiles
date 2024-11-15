function ntp
    set venv_flag 0
    set litestar_flag 0
    set dir_name ""
    set action "create"
    set python_version "3.12"
    for arg in $argv
        switch $arg
            case '-v' '--venv'
                set venv_flag 1
            case '-l' '--litestar'
                set litestar_flag 1
                set venv_flag 1
            case 'close'
                set action "close"
            case '3.*'
                set python_version $arg
            case '*'
                set dir_name $arg
        end
    end
    if test $action != "close" -a -z "$dir_name"
        echo "Usage: ntp [-v --venv] [-l --litestar] [python_version] <word> or ntp close [dirname]"
        return 1
    end
    if test $action = "close"
        if test -z "$dir_name"
            set dir_name (basename (pwd))
        end
        set dir "/tmp/testing/$dir_name"
        if test (pwd) = $dir
            if test -d ".venv"
                deactivate
                echo "Virtual environment deactivated."
            end
            cd ~/
            rm -r $dir
            echo "Directory $dir deleted and switched to home directory."
            return 0
        else
            echo "You are not in the directory $dir."
            return 1
        end
    end
    set dir "/tmp/testing/$dir_name"
    if test -d "$dir"
        echo "Directory $dir already exists. Delete it? [y/N]"
        read -l confirm
        if test "$confirm" != "y"
            echo "Switching to $dir"
        end
        rm -r "$dir"
        echo "Deleted directory $dir."
    end
    mkdir -p $dir
    cd $dir
    echo "Directory $dir created and switched to."
    if test $venv_flag -eq 1
        uv venv --python $python_version --seed .venv
        source .venv/bin/activate.fish
        echo "Virtual environment created with Python $python_version and activated."
        if test $litestar_flag -eq 1
            uv pip install "litestar[standard]"
            curl -s https://gist.githubusercontent.com/JacobCoffee/4cc26bee5604787f1352760852b56c29/raw > app.py
            echo "Installed Litestar and downloaded starter template."
        end
    end
end
