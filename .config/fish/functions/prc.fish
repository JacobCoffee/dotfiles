function prc --description "gh pr checks with compact URLs"
    gh pr checks $argv 2>&1 | while read -l line
        # Split on tab
        set -l parts (string split \t $line)

        # If fewer than 4 parts or no URL, print as-is
        if test (count $parts) -lt 4; or test -z "$parts[4]"
            echo $line
            continue
        end

        set -l name $parts[1]
        set -l st $parts[2]
        set -l duration $parts[3]
        set -l url $parts[4]

        # Color the status
        switch $st
            case pass
                set st (set_color green)"pass"(set_color normal)
            case fail
                set st (set_color red)"fail"(set_color normal)
            case pending
                set st (set_color yellow)"pend"(set_color normal)
            case skipping
                set st (set_color brblack)"skip"(set_color normal)
            case '*'
                set st (set_color cyan)$st(set_color normal)
        end

        # OSC 8 hyperlink: clickable "LINK" text in supported terminals
        set -l link (printf '\e]8;;%s\e\\LINK\e]8;;\e\\' $url)

        printf "%-40s  %s  %5s  %s\n" $name $st $duration $link
    end
end
