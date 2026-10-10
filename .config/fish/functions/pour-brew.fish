function pour-brew
    # Pours the latest Brew(file) out and sends it into the series of tubes
    set -l brewfile (realpath ~/.config/Brewfile)
    set -l repo (git -C (dirname $brewfile) rev-parse --show-toplevel)
    or return 1

    echo "Stage: Running brew bundle dump"
    brew bundle dump --force --file=$brewfile
    or return 1

    if git -C $repo diff --quiet -- $brewfile
        echo "No changes to commit."
        return 0
    end

    echo "Stage: Committing Brewfile"
    git -C $repo commit -m "Update brew bundle dump" -- $brewfile
    or return 1

    echo "Stage: Pushing changes to remote"
    git -C $repo push
end
