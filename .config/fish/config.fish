# Source Cargo environment
if test -f ~/.cargo/env
    bash -c 'source ~/.cargo/env'
end

#source ~/.profile
source ~/.config/fish/aliases.fish

# WARN: We can no longer have this in `is-interactive` because PyCharm, et al fail
set -x GPG_TTY (tty)
set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent

if status is-interactive
    if test "$TERMINAL_EMULATOR" != "JetBrains-JediTerm"
        eval (zellij -l compact setup --generate-auto-start fish | string collect)
    end
end

# Colima / Docker
set -x COLIMA_VM "default"
set -x COLIMA_VM_SOCKET "$HOME/.colima/$COLIMA_VM/docker.sock"
set -x DOCKER_HOST "unix://$COLIMA_VM_SOCKET"

# Secretive
set -x SSH_AUTH_SOCK /Users/coffee/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh

# Theme omf bobthefisher
set -g theme_nerd_fonts yes
set -g theme_date_format "+%a %H:%M"
set -g theme_display_vagrant yes
set -g theme_color_scheme dracula
set -g theme_newline_cursor yes
set -g theme_title_display_user yes
set -g theme_title_display_process yes
set -g theme_display_cmd_duration yes
set -g theme_nerd_fonts yes
set -g theme_powerline_fonts yes

# Source Aliases
#source ~/.bash_aliases

# editor
set -gx EDITOR nvim

# golang
set -g fish_user_paths "/usr/local/go/bin" fish_user_paths
set -x  GOPATH   $HOME/GO-lang
set -x PATH $PATH $GOPATH/bin


# Starship
/opt/homebrew/bin/starship init fish | source

# RTX / PyEnv / ASDF
#~/.local/share/rtx/bin/rtx activate fish | source

# Created by `pipx` on 2023-09-30 18:53:20
set PATH $PATH ~/.local/bin

# PATH
set PATH $PATH /opt/homebrew/bin
set PATH $PATH ~/.cargo/bin
set PATH $PATH ~/.local/share/bob/nvim-bin

# tools
zoxide init fish | source

alias cd=z
alias cdi=zi

# MOTD bs
set fish_greeting

# theme for bat
export BAT_THEME="Dracula"
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
#export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'
# TODO: Fix
set -g FZF_CTRL_T_COMMAND "command find -L \$dir -type f 2> /dev/null | sed '1d; s#^\./##'"

if status is-interactive
  /opt/homebrew/opt/mise/bin/mise activate fish | source
else
  /opt/homebrew/opt/mise/bin/mise activate fish --shims | source
end

# pnpm
set -gx PNPM_HOME "/Users/coffee/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
