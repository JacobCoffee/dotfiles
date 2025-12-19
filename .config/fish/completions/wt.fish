# Completions for wt (git worktree helper)

# Helper to get worktree names for completion
function __wt_complete_names
    set -l root (git rev-parse --show-toplevel 2>/dev/null)

    # Git tracked worktrees - extract branch names
    git worktree list --porcelain 2>/dev/null | while read -l line
        if string match -q "branch refs/heads/*" -- $line
            string replace "branch refs/heads/" "" -- $line
        end
    end

    # .worktrees/ directory names
    if test -n "$root" -a -d "$root/.worktrees"
        for dir in $root/.worktrees/*/
            if test -d "$dir"
                basename (string trim -r -c '/' "$dir")
            end
        end
    end
end

# Disable file completion by default
complete -c wt -f

# Subcommands
complete -c wt -n "__fish_use_subcommand" -a "ls list" -d "List all worktrees"
complete -c wt -n "__fish_use_subcommand" -a "j jump" -d "Jump to worktree"
complete -c wt -n "__fish_use_subcommand" -a "new add" -d "Create new worktree"
complete -c wt -n "__fish_use_subcommand" -a "rm remove" -d "Remove a worktree"
complete -c wt -n "__fish_use_subcommand" -a "prune" -d "Clean up stale worktrees"
complete -c wt -n "__fish_use_subcommand" -a "help" -d "Show help"

# Flags for ls/list
complete -c wt -n "__fish_seen_subcommand_from ls list" -s l -l long -d "Show full paths"

# Worktree name completion for jump/remove
complete -c wt -n "__fish_seen_subcommand_from j jump rm remove" -a "(__wt_complete_names)" -d "Worktree"

# Branch completion for new (base branch argument)
complete -c wt -n "__fish_seen_subcommand_from new add; and test (count (commandline -opc)) -ge 3" -a "(git branch -a 2>/dev/null | string replace -r '^\*?\s*' '' | string replace -r '^remotes/origin/' '')" -d "Base branch"
