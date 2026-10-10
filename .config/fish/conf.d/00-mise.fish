# Keep mise activation in config.fish, which selects interactive hooks or shims.
# This runs before Homebrew's vendor conf.d/mise-activate.fish.
set -gx MISE_FISH_AUTO_ACTIVATE 0
