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
alias tree erd
alias rtime hyperfine

# general
alias c clear

# projects - general
alias m make
alias tf terraform

# python
alias av "source .venv/bin/activate.fish"
alias python python3
#alias pip pip3

# docker
alias dpa "docker ps -a"

# vagrant
alias vs "vagrant ssh"
alias vu "vagrant up"
alias vd "vagrant destroy"
alias vp "vagrant provision"

# work
if test -e ~/.config/fish/work_aliases.fish
    source ~/.config/fish/work_aliases.fish
end
