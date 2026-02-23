function wt --description "Git worktree helpers"
    set -l cmd $argv[1]
    set -l args $argv[2..-1]

    switch "$cmd"
        case "" help -h --help
            echo "Usage: wt <command> [args]"
            echo ""
            echo "Commands:"
            echo "  ls, list      List worktrees (short names, -l for long)"
            echo "  j, jump       Jump to worktree (fuzzy match)"
            echo "  new, add      Create new worktree in .worktrees/"
            echo "  rm, remove    Remove a worktree"
            echo "  prune         Clean up stale worktrees"
            echo ""
            echo "Examples:"
            echo "  wt ls"
            echo "  wt j docs        # jump to worktree matching 'docs'"
            echo "  wt new feature   # create .worktrees/feature"
        case l ls list
            if contains -- -l $args; or contains -- --long $args
                __wt_list_long
            else
                __wt_list
            end
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

function __wt_all --description "Get all worktrees as path<TAB>branch pairs"
    set -l root (__wt_root)
    set -l seen_paths
    set -l current_path ""
    set -l current_branch ""

    git worktree list --porcelain 2>/dev/null | while read -l line
        if string match -q "worktree *" -- $line
            set current_path (string replace "worktree " "" -- $line)
            set current_branch ""
        else if string match -q "branch refs/heads/*" -- $line
            set current_branch (string replace "branch refs/heads/" "" -- $line)
        else if test -z "$line" -a -n "$current_path"
            if test -z "$current_branch"
                set current_branch (basename "$current_path")
            end
            printf '%s\t%s\n' "$current_path" "$current_branch"
            set -a seen_paths "$current_path"
            set current_path ""
            set current_branch ""
        end
    end

    # Flush last entry if no trailing blank line
    if test -n "$current_path"
        if test -z "$current_branch"
            set current_branch (basename "$current_path")
        end
        printf '%s\t%s\n' "$current_path" "$current_branch"
        set -a seen_paths "$current_path"
    end

    # .worktrees/ entries not already git-tracked
    if test -n "$root" -a -d "$root/.worktrees"
        for dir in $root/.worktrees/*/
            if test -d "$dir"
                set -l wt_path (string trim -r -c '/' "$dir")
                if not contains -- "$wt_path" $seen_paths
                    printf '%s\t%s\n' "$wt_path" (basename "$wt_path")
                end
            end
        end
    end
end

function __wt_list --description "List worktrees (short names)"
    set -l root (__wt_root)
    set -l wt_dir "$root/.worktrees"
    set -l in_worktrees
    set -l other

    # Parse git worktree list
    set -l current_path ""
    git worktree list --porcelain 2>/dev/null | while read -l line
        if string match -q "worktree *" -- $line
            set current_path (string replace "worktree " "" -- $line)
        else if string match -q "branch refs/heads/*" -- $line
            set -l branch (string replace "branch refs/heads/" "" -- $line)
            if string match -q "$wt_dir/*" -- $current_path
                set -a in_worktrees $branch
            else
                set -a other $branch
            end
        end
    end

    # Show main repo worktrees
    if test (count $other) -gt 0
        echo "branches:"
        for b in $other
            echo "  $b"
        end
    end

    # Show .worktrees/ group
    if test (count $in_worktrees) -gt 0
        echo ".worktrees/:"
        for b in $in_worktrees
            echo "  $b"
        end
    end
end

function __wt_list_long --description "List worktrees (full paths)"
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
    set -l pairs (__wt_all)

    if test (count $pairs) -eq 0
        echo "No worktrees found"
        return 1
    end

    if test (count $argv) -eq 0
        if type -q fzf
            set -l selected (printf '%s\n' $pairs | fzf --height 40% --reverse --prompt="wt> " --delimiter='\t' --with-nth=2)
            if test -n "$selected"
                builtin cd (string split \t -- "$selected")[1]
            end
        else
            for pair in $pairs
                echo "  "(string split \t -- "$pair")[2]
            end
            echo ""
            echo "Install fzf for interactive selection, or: wt j <pattern>"
        end
    else
        set -l match (printf '%s\n' $pairs | grep -i "$argv[1]" | head -1)
        if test -n "$match"
            builtin cd (string split \t -- "$match")[1]
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
    and if test -f "$root/.env"
        cp "$root/.env" "$worktree_path/.env"
        echo "Copied .env to worktree"
    end
    and builtin cd "$worktree_path"
end

function __wt_remove --description "Remove a worktree"
    set -l pairs (__wt_all)

    if test (count $pairs) -eq 0
        echo "No worktrees found"
        return 1
    end

    if test (count $argv) -eq 0
        if type -q fzf
            set -l selected (printf '%s\n' $pairs | fzf --height 40% --reverse --prompt="remove> " --delimiter='\t' --with-nth=2)
            if test -n "$selected"
                set -l path (string split \t -- "$selected")[1]
                git worktree remove "$path"
            end
        else
            echo "Usage: wt rm <pattern>"
            for pair in $pairs
                echo "  "(string split \t -- "$pair")[2]
            end
        end
    else
        set -l match (printf '%s\n' $pairs | grep -i "$argv[1]" | head -1)
        if test -n "$match"
            set -l path (string split \t -- "$match")[1]
            set -l branch (string split \t -- "$match")[2]
            read -l -P "Remove $branch ($path)? [y/N] " confirm
            if test "$confirm" = y -o "$confirm" = Y
                git worktree remove "$path"
            end
        else
            echo "No worktree matching: $argv[1]"
            return 1
        end
    end
end
