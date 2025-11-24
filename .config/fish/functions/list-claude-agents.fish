function list-claude-agents --description "List available Claude Code agents from global and local .claude/agents directories"
    set -l global_dir "$HOME/.claude/agents"
    set -l local_dir ".claude/agents"

    set -l found 0

    # Colors
    set -l cyan (set_color cyan)
    set -l yellow (set_color yellow)
    set -l green (set_color green)
    set -l dim (set_color brblack)
    set -l reset (set_color normal)

    # Global agents
    if test -d $global_dir
        set -l files $global_dir/*.md
        if test (count $files) -gt 0 -a -e $files[1]
            echo $cyan"Global agents"$reset $dim"($global_dir)"$reset
            echo $dim(string repeat -n 60 "─")$reset
            for file in $files
                if test -f $file
                    set found 1
                    set -l name (basename $file .md)
                    set -l desc ""
                    set -l model ""
                    set -l in_frontmatter 0

                    while read -l line
                        if test "$line" = "---"
                            if test $in_frontmatter -eq 1
                                break
                            end
                            set in_frontmatter 1
                            continue
                        end
                        if test $in_frontmatter -eq 1
                            if string match -qr '^name:\s*(.+)$' -- $line
                                set name (string replace -r '^name:\s*' '' $line)
                            else if string match -qr '^model:\s*(.+)$' -- $line
                                set model (string replace -r '^model:\s*' '' $line)
                            else if string match -qr '^description:\s*(.+)$' -- $line
                                set desc (string replace -r '^description:\s*' '' $line)
                                # Truncate long descriptions
                                if test (string length "$desc") -gt 80
                                    set desc (string sub -l 77 "$desc")"..."
                                end
                            end
                        end
                    end < $file

                    printf "  %s%-30s%s" $green $name $reset
                    if test -n "$model"
                        printf " %s[%s]%s" $yellow $model $reset
                    end
                    echo
                    if test -n "$desc"
                        printf "    $dim%s$reset\n" $desc
                    end
                end
            end
            echo
        end
    end

    # Local agents
    if test -d $local_dir
        set -l files $local_dir/*.md
        if test (count $files) -gt 0 -a -e $files[1]
            echo $cyan"Local agents"$reset $dim"($local_dir)"$reset
            echo $dim(string repeat -n 60 "─")$reset
            for file in $files
                if test -f $file
                    set found 1
                    set -l name (basename $file .md)
                    set -l desc ""
                    set -l model ""
                    set -l in_frontmatter 0

                    while read -l line
                        if test "$line" = "---"
                            if test $in_frontmatter -eq 1
                                break
                            end
                            set in_frontmatter 1
                            continue
                        end
                        if test $in_frontmatter -eq 1
                            if string match -qr '^name:\s*(.+)$' -- $line
                                set name (string replace -r '^name:\s*' '' $line)
                            else if string match -qr '^model:\s*(.+)$' -- $line
                                set model (string replace -r '^model:\s*' '' $line)
                            else if string match -qr '^description:\s*(.+)$' -- $line
                                set desc (string replace -r '^description:\s*' '' $line)
                                if test (string length "$desc") -gt 80
                                    set desc (string sub -l 77 "$desc")"..."
                                end
                            end
                        end
                    end < $file

                    printf "  %s%-30s%s" $green $name $reset
                    if test -n "$model"
                        printf " %s[%s]%s" $yellow $model $reset
                    end
                    echo
                    if test -n "$desc"
                        printf "    $dim%s$reset\n" $desc
                    end
                end
            end
            echo
        end
    end

    if test $found -eq 0
        echo "No agents found in $global_dir or $local_dir"
        return 1
    end
end
