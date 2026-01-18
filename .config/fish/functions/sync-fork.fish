function sync-fork
    set branch (git branch --show-current)
    git fetch upstream && git merge upstream/$branch && git push origin $branch
end
