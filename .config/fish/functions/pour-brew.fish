#!/usr/bin/env fish
# File: git_root/public/dotfiles/brew_dump_and_commit.fish

function pour-brew 
    # Pours the latest Brew(file) out and sends it into the series of tubes 

    # Store the initial directory
    set initial_dir (pwd)


    echo "Stage: Navigating to dotfiles directory"
    cd ~/.config/

    echo "Stage: Running brew bundle dump"
    brew bundle dump --force

    echo "Stage: Adding changes to git"
    yadm add Brewfile
    set exit_status $status

    if test $exit_status -ne 0
        echo "Failed to add Brewfile."
        cd $initial_dir
        return 1
    end

    echo "Stage: Checking for changes to commit"
    if test -n "(git status --porcelain)"
        echo "Stage: Committing changes"
        yadm commit -m "Update brew bundle dump"
    else
        echo "No changes to commit."
    end

    set exit_status $status

    if test $exit_status -ne 0
        echo "Failed to commit changes."
        cd $initial_dir
        return 1
    end

    echo "Stage: Pushing changes to remote"
    yadm push
    set exit_status $status

    if test $exit_status -ne 0
        echo "Failed to push changes."
    end

    echo "Stage: Returning to original directory"
    cd $initial_dir
end
