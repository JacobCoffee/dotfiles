# Initialize a global variable for the previous directory
set -g prev_dir $PWD

function on_cd --on-event fish_postexec
    if string match -q 'cd*' $argv[1]; and test $PWD != $prev_dir
        set -l venv_path
        # Check for venv or .venv and activate it if cd_venv is set to 'yes'
        if set -q cd_venv; and string match -q 'yes' $cd_venv
            if test -d "venv/bin"
                set venv_path "$PWD/venv"
                source venv/bin/activate.fish
            else if test -d ".venv/bin"
                set venv_path "$PWD/.venv"
                source .venv/bin/activate.fish
            end
        end

        # Echo only if a venv is activated and cd_echo is set to 'yes'
        if set -q venv_path; and test -n "$venv_path"; and set -q cd_echo; and string match -q 'yes' $cd_echo
            echo "Activated virtual environment at $venv_path."
        end
    end
    set prev_dir $PWD  # Update the previous directory
end

