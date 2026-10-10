function mythos --description "Claude Code in the network-isolated Mythos container"
    # Thin wrapper only. All Mythos config and resource IDs live in
    # ~/git/internal/mythos-wif, deliberately not in this public repo.
    ~/git/internal/mythos-wif/bin/mythos-shell $argv
end
