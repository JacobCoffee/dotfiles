# nvim
alias vefc "nvim ~/.config/fish/config.fish"
alias vefa "nvim ~/.config/fish/aliases.fish"
alias view "nvim -R"

# Functions
function timestamp
    python3 -c 'import time; print(int(time.time()))'
end

# Aliases
# tooling
alias v nvim
alias vim nvim
alias g git
alias gx gix
alias zj zellij
alias cat bat
alias du dust
alias find fd
alias ls eza
alias diff delta
alias grep rg

# general
alias c clear

# projects - general
alias m make

# python
alias av "source .venv/bin/activate.fish"
alias python python3
alias pip pip3

# work
if test -e ~/.config/fish/work_aliases.fish
    source ~/.config/fish/work_aliases.fish
end
