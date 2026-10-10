function __mythos_dirs
    for root in ~/git/internal ~/git/public
        test -d $root; or continue
        for group in $root/*/
            set -l g (basename $group)
            echo $g
            for repo in $group*/
                test -d $repo; and echo $g/(basename $repo)
            end
        end
    end
end

complete -c mythos -f
complete -c mythos -l list -d "List available project groups"
complete -c mythos -l ps -d "Show every mythos stack running right now"
complete -c mythos -l down -d "Stop one stack (default: current directory)"
complete -c mythos -l down-all -d "Stop all running mythos stacks"
complete -c mythos -s c -d "Skip the shell, go straight into claude"
complete -c mythos -a "(__mythos_dirs)" -d "project"
