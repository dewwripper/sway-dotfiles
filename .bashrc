# ~/.bashrc - Written for Sway / Bash setup reproducing Zsh (.zshrc) workflow

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# ------------------------------------------------------------------------------
# History & Shell Options (Emulating Oh-My-Zsh & Zsh defaults)
# ------------------------------------------------------------------------------
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
shopt -s checkwinsize
shopt -s autocd 2>/dev/null
shopt -s cdspell 2>/dev/null
shopt -s globstar 2>/dev/null

# ------------------------------------------------------------------------------
# Vi Keybindings (Emulating `bindkey -v` & `export KEYTIMEOUT=1`)
# ------------------------------------------------------------------------------
set -o vi

# Readline Vi mode tuning & completion settings
if [[ -t 0 ]]; then
    # Enable completion options similar to zsh
    bind 'set completion-ignore-case on' 2>/dev/null
    bind 'set show-all-if-ambiguous on' 2>/dev/null
    bind 'set menu-complete-display-prefix on' 2>/dev/null
    
    # History prefix search with Up/Down arrows
    bind '"\e[A": history-search-backward' 2>/dev/null
    bind '"\e[B": history-search-forward' 2>/dev/null
fi

# ------------------------------------------------------------------------------
# Prompt - Starship (Replacing Powerlevel10k / p10k prompt)
# ------------------------------------------------------------------------------
export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship/starship.toml"
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

# ------------------------------------------------------------------------------
# Plugins & Tool Integrations (Emulating OMZ plugins: git, z, zsh-autosuggestions, zsh-nvm)
# ------------------------------------------------------------------------------

# Plugin: git completion
if [ -f /usr/share/bash-completion/completions/git ]; then
    . /usr/share/bash-completion/completions/git
elif [ -f /etc/bash_completion.d/git-prompt ]; then
    . /etc/bash_completion.d/git-prompt
fi

# Plugin: z (autojump/directory navigation)
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
elif [ -f /usr/share/z/z.sh ]; then
    . /usr/share/z/z.sh
elif [ -f "$HOME/.local/bin/z.sh" ]; then
    . "$HOME/.local/bin/z.sh"
elif [ -f "$HOME/z.sh" ]; then
    . "$HOME/z.sh"
fi

# Plugin: zsh-nvm (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
    . "$NVM_DIR/bash_completion"
fi

# Plugin: fzf (Fuzzy Finder - https://junegunn.github.io/fzf/shell-integration/)
if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/fzf.bash" ]; then
    . "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/fzf.bash"
elif [ -f "$HOME/sway-dotfiles/.config/fzf/fzf.bash" ]; then
    . "$HOME/sway-dotfiles/.config/fzf/fzf.bash"
elif [ -f "$HOME/.fzf.bash" ]; then
    . "$HOME/.fzf.bash"
elif command -v fzf &>/dev/null; then
    eval "$(fzf --bash)"
fi

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------
export EDITOR='nvim'
export VISUAL='nvim'
export REQUESTS_CA_BUNDLE=/usr/share/ca-certificates/azure_cli_cert.pem

# Local binary/environment script if present
if [ -f "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi

# ------------------------------------------------------------------------------
# Personal Aliases (Mirrored from .zshrc)
# ------------------------------------------------------------------------------

# Editor
alias vim='nvim'

# File Listing (eza)
alias ls='/usr/bin/eza -al --color=always --group-directories-first' # my preferred listing
alias la='/usr/bin/eza -a --color=always --group-directories-first'  # all files and dirs
alias ll='/usr/bin/eza -l --color=always --group-directories-first'  # long format
alias lt='/usr/bin/eza -aT --color=always --group-directories-first' # tree listing
alias l.='/usr/bin/eza -a | egrep "^\."'

# Colorized grep
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# File operation safety confirmations
alias cp="cp -i"
alias mv='mv -i'
alias rm='rm -i'

# Git Aliases
alias g="git"
alias gbr="git branch -a"
alias gst="git status"
alias gcp="git add . && git commit --amend --no-edit && git push -f"
alias grc="git rebase --continue"
alias grs="git rebase --skip"
alias grhh="git reset --hard HEAD"

# Docker Compose Aliases
alias dcd="docker compose down"
alias dcu="docker compose up -d"
alias dcb="docker compose build"
alias dcr="docker compose down && docker compose up -d"
