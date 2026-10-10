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
alias gs 'git status'
alias ga 'git add -p'
alias gsw 'git switch'
alias gswm 'git switch main'
alias gd 'git diff'
alias gde 'git diff --name-only | fzf --multi | xargs nvim'
alias gdc 'git diff --cached'
alias gc 'git commit -m'
alias gro 'gh repo view --web'
alias gpo 'gh pr view --web' 
alias gcfp 'git commit -m "fmt" && git push'
alias gl "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative --all"
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
alias ftp ncftp 

# general
alias c clear

# projects - general
alias m make
alias tf terraform

# python
alias av "source .venv/bin/activate.fish"
alias python python3
#alias pip pip3

# docker / k8s
alias dpa "docker ps -a"
alias k "kubectl"
alias kga "kubectl get all"
alias kgap "kubectl get -A pods"

# vagrant
alias vs "vagrant ssh"
alias vu "vagrant up"
alias vd "vagrant destroy"
alias vp "vagrant provision"
alias vss "vagrant status"

# ai
alias ghce "gh copilot explain"
alias ghcs "gh copilot suggest"

# work
if test -e ~/.config/fish/work_aliases.fish
    source ~/.config/fish/work_aliases.fish
end

# dev logs (PTY-preserving capture for Claude Code)
alias dev-log "mkdir -p logs; script -qF logs/dev.log make dev"

# gh cli
alias grv "gh repo view --web"

