function wt --description "Git worktree helpers"
    set -l cmd $argv[1]
    set -l args $argv[2..-1]

    switch "$cmd"
        case "" help -h --help
            echo "Usage: wt <command> [args]"
            echo ""
            echo "Commands:"
            echo "  ls, list      List all worktrees"
            echo "  j, jump       Jump to worktree (fuzzy match)"
            echo "  new, add      Create new worktree in .worktrees/"
            echo "  rm, remove    Remove a worktree"
            echo "  prune         Clean up stale worktrees"
            echo ""
            echo "Examples:"
            echo "  wt ls"
            echo "  wt j docs        # jump to worktree matching 'docs'"
            echo "  wt new feature   # create .worktrees/feature"
        case ls list
            __wt_list
        case j jump
            __wt_jump $args
        case new add
            __wt_new $args
        case rm remove
            __wt_remove $args
        case prune
            git worktree prune -v
        case '*'
            __wt_jump $cmd $args
    end
end

function __wt_root --description "Get repo root"
    git rev-parse --show-toplevel 2>/dev/null
end

function __wt_all --description "Get all worktrees (git tracked + .worktrees/)"
    set -l root (__wt_root)
    set -l worktrees

    set -a worktrees (git worktree list --porcelain 2>/dev/null | grep "^worktree" | cut -d' ' -f2-)

    if test -n "$root" -a -d "$root/.worktrees"
        for dir in $root/.worktrees/*/
            if test -d "$dir"
                set -a worktrees (string trim -r -c '/' "$dir")
            end
        end
    end

    printf '%s\n' $worktrees | sort -u
end

function __wt_list --description "List all worktrees"
    echo "Git tracked:"
    git worktree list

    set -l root (__wt_root)
    if test -n "$root" -a -d "$root/.worktrees"
        echo ""
        echo ".worktrees/:"
        for dir in $root/.worktrees/*/
            if test -d "$dir"
                echo "  "(basename (string trim -r -c '/' "$dir"))
            end
        end
    end
end

function __wt_jump --description "Jump to a worktree"
    set -l worktrees (__wt_all)

    if test -z "$worktrees"
        echo "No worktrees found"
        return 1
    end

    if test (count $argv) -eq 0
        if type -q fzf
            set -l selected (printf '%s\n' $worktrees | fzf --height 40% --reverse --prompt="wt> ")
            if test -n "$selected"
                cd "$selected"
            end
        else
            printf '%s\n' $worktrees
            echo ""
            echo "Install fzf for interactive selection, or: wt j <pattern>"
        end
    else
        set -l match (printf '%s\n' $worktrees | grep -i "$argv[1]" | head -1)
        if test -n "$match"
            cd "$match"
        else
            echo "No worktree matching: $argv[1]"
            return 1
        end
    end
end

function __wt_new --description "Create a new worktree"
    if test (count $argv) -eq 0
        echo "Usage: wt new <branch-name> [base-branch]"
        return 1
    end

    set -l name $argv[1]
    set -l base (test (count $argv) -ge 2; and echo $argv[2]; or echo "main")
    set -l root (__wt_root)

    if test -z "$root"
        echo "Not in a git repository"
        return 1
    end

    set -l worktree_dir "$root/.worktrees"
    set -l worktree_path "$worktree_dir/$name"

    if test -d "$worktree_path"
        echo "Worktree already exists: $worktree_path"
        return 1
    end

    mkdir -p "$worktree_dir"
    git worktree add -b "$name" "$worktree_path" "$base"
    and echo "Created worktree at $worktree_path"
    and cd "$worktree_path"
end

function __wt_remove --description "Remove a worktree"
    set -l worktrees (__wt_all)

    if test -z "$worktrees"
        echo "No worktrees found"
        return 1
    end

    if test (count $argv) -eq 0
        if type -q fzf
            set -l selected (printf '%s\n' $worktrees | fzf --height 40% --reverse --prompt="remove> ")
            if test -n "$selected"
                git worktree remove "$selected"
            end
        else
            echo "Usage: wt rm <pattern>"
            printf '%s\n' $worktrees
        end
    else
        set -l match (printf '%s\n' $worktrees | grep -i "$argv[1]" | head -1)
        if test -n "$match"
            read -l -P "Remove $match? [y/N] " confirm
            if test "$confirm" = y -o "$confirm" = Y
                git worktree remove "$match"
            end
        else
            echo "No worktree matching: $argv[1]"
            return 1
        end
    end
end
