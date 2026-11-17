# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- set to "" since prompt is managed by Starship
ZSH_THEME=""

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# History control: add a space at the beginning-of-line to do not save this line to history
HISTCONTROL=ignorespace

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git z zsh-autosuggestions zsh-nvm)

source $ZSH/oh-my-zsh.sh

# ------------------------------------------------------------------------------
# Vi mode (must come after OMZ, which sets bindkey -e; and before Starship,
# which wraps zle-keymap-select to redraw its ❮ vimcmd prompt symbol)
# ------------------------------------------------------------------------------
bindkey -v
export KEYTIMEOUT=1   # Esc switches to normal mode in 10ms instead of 400ms

# Cursor shape: beam in insert mode, block in normal mode
_vi_cursor() {
    case $KEYMAP in
        vicmd)      print -n '\e[2 q' ;;   # steady block
        viins|main) print -n '\e[6 q' ;;   # steady beam
    esac
}
zle-keymap-select() { _vi_cursor }
zle-line-init()     { zle -K viins; _vi_cursor }
zle -N zle-keymap-select
zle -N zle-line-init
preexec_functions+=(_vi_cursor_reset)
_vi_cursor_reset() { print -n '\e[2 q' }   # restore block cursor for programs (nvim, less...)

# Insert mode: keep familiar emacs-style editing (vim's own insert mode allows these)
bindkey -M viins '^?' backward-delete-char     # Backspace past the insert start point
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^K' kill-line
bindkey -M viins '^P' up-line-or-search
bindkey -M viins '^N' down-line-or-search

# Normal mode: history search on prefix with k/j, edit full command in $EDITOR with v
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N edit-command-line
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search
bindkey -M vicmd 'v' edit-command-line
bindkey -M vicmd '/' history-incremental-search-backward
bindkey -M vicmd '?' history-incremental-search-forward

# Vim text objects: ciw, di", ya(, ci{ ...
autoload -Uz select-bracketed select-quoted
zle -N select-bracketed
zle -N select-quoted
for km in visual viopp; do
    bindkey -M $km -- '-' vi-up-line-or-history
    for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do bindkey -M $km $c select-bracketed; done
    for c in {a,i}${(s..)^:-\'\"\`\|,./:;=+@}; do bindkey -M $km $c select-quoted; done
done
unset km c

# Vim surround: cs"' (change), ds" (delete), ys{motion}" (add), S" in visual
autoload -Uz surround
zle -N delete-surround surround
zle -N add-surround surround
zle -N change-surround surround
bindkey -M vicmd 'cs' change-surround
bindkey -M vicmd 'ds' delete-surround
bindkey -M vicmd 'ys' add-surround
bindkey -M visual 'S' add-surround

# Yank to system clipboard in normal mode: Y copies the whole line
_vi_yank_clipboard() {
    if command -v wl-copy &>/dev/null; then print -rn -- "$BUFFER" | wl-copy
    elif command -v xclip &>/dev/null; then print -rn -- "$BUFFER" | xclip -selection clipboard
    fi
}
zle -N _vi_yank_clipboard
bindkey -M vicmd 'Y' _vi_yank_clipboard

# ------------------------------------------------------------------------------
# Home / End / Delete keys (bound in every keymap; OMZ only binds the terminfo variants)
# ------------------------------------------------------------------------------
for keymap in emacs viins vicmd; do
    bindkey -M $keymap '^[[H'  beginning-of-line   # Home (normal mode)
    bindkey -M $keymap '^[OH'  beginning-of-line   # Home (application mode)
    bindkey -M $keymap '^[[1~' beginning-of-line   # Home (tmux/screen/linux console)
    bindkey -M $keymap '^[[7~' beginning-of-line   # Home (rxvt)
    bindkey -M $keymap '^[[F'  end-of-line         # End (normal mode)
    bindkey -M $keymap '^[OF'  end-of-line         # End (application mode)
    bindkey -M $keymap '^[[4~' end-of-line         # End (tmux/screen/linux console)
    bindkey -M $keymap '^[[8~' end-of-line         # End (rxvt)
    bindkey -M $keymap '^[[3~' delete-char         # Delete
done
unset keymap

# Ctrl+F accepts zsh-autosuggestions suggestion (vi insert + emacs)
bindkey -M viins '^F' autosuggest-accept
bindkey -M emacs '^F' autosuggest-accept

# ------------------------------------------------------------------------------
# Prompt - Starship (Replacing Powerlevel10k / p10k prompt)
# ------------------------------------------------------------------------------
export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship/starship.toml"
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

# ------------------------------------------------------------------------------
# Plugins & Tool Integrations (zoxide, fzf)
# ------------------------------------------------------------------------------

# Plugin: z (autojump/directory navigation)
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# Plugin: fzf (Fuzzy Finder - https://junegunn.github.io/fzf/shell-integration/)
if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/fzf.zsh" ]; then
    . "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/fzf.zsh"
elif [ -f "$HOME/sway-dotfiles/.config/fzf/fzf.zsh" ]; then
    . "$HOME/sway-dotfiles/.config/fzf/fzf.zsh"
elif [ -f "$HOME/.fzf.zsh" ]; then
    . "$HOME/.fzf.zsh"
elif command -v fzf &>/dev/null; then
    eval "$(fzf --zsh)"
fi

# User configuration
export EDITOR='nvim'
export VISUAL='nvim'

# Input method (Fcitx5 - Vietnamese Unikey)
export XMODIFIERS=@im=fcitx
export QT_IM_MODULE=fcitx
export GTK_IM_MODULE=fcitx

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
export REQUESTS_CA_BUNDLE=/usr/share/ca-certificates/azure_cli_cert.pem
if [ -z "$SSH_AUTH_SOCK" ]; then
    if [ -S "$XDG_RUNTIME_DIR/openssh_agent" ]; then
        export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/openssh_agent"
    elif [ -S "/run/user/1000/gcr/ssh" ]; then
        export SSH_AUTH_SOCK="/run/user/1000/gcr/ssh"
    fi
fi

alias vim='nvim'
# Changing "ls" to "exa"
alias ls='/usr/bin/eza -al --color=always --group-directories-first' # my preferred listing
alias la='/usr/bin/eza -a --color=always --group-directories-first' # all files and dirs
alias ll='/usr/bin/eza -l --color=always --group-directories-first' # long format
alias lt='/usr/bin/eza -aT --color=always --group-directories-first' # tree listing
alias l.='/usr/bin/eza -a | egrep "^\."'

# Colorize grep output (good for log files)
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# confirm before overwriting something
alias cp="cp -i"
alias mv='mv -i'
alias rm='rm -i'

# git
alias g="git"
alias gbr="git branch -a"
alias gst="git status"
alias gcp="git add . && git commit --amend --no-edit && git push -f"
alias grc="git rebase --continue"
alias grs="git rebase --skip"
alias grhh="git reset --hard HEAD"

# docker
alias dcd="docker compose down"
alias dcu="docker compose up -d"
alias dcb="docker compose build"
alias dcr="docker compose down && docker compose up -d"
# open a login shell in a container with AWS credentials from aws-vault: awsdev <profile> <container>
awsdev() { aws-vault exec "$1" -- podman exec -it \
  -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN \
  -e AWS_REGION -e AWS_VAULT "$2" zsh --login; }

# devpod
alias ducode="devpod up --devcontainer-path .devpod/devcontainer.json --ide vscode --dotfiles https://github.com/dewwripper/dotfiles --dotfiles-script .setup-no-install.sh ."
alias ducodenc="devpod up --devcontainer-path .devpod/devcontainer.json --ide vscode --dotfiles https://github.com/dewwripper/dotfiles --dotfiles-script .setup-no-install.sh . --recreate"
alias duvimnc="devpod up --devcontainer-path .devpod/devcontainer.json --ide none --dotfiles https://github.com/dewwripper/dotfiles --dotfiles-script .setup-no-install.sh . --recreate"
alias duvim="devpod up --devcontainer-path .devpod/devcontainer.json --ide none --dotfiles https://github.com/dewwripper/dotfiles --dotfiles-script .setup-no-install.sh ."
# replace ./.devpod with a fresh copy of the devpod template, without its git history (command rm skips the rm -i alias)
alias gcldp="command rm -rf .devpod && git clone https://github.com/khanhcmlab/devpod-template-docker .devpod && command rm -rf .devpod/.git"
alias gcldpc="command rm -rf .devpod && git clone https://github.com/khanhcmlab/devpod-template-docker .devpod && command rm -rf .devpod/.git"
# herdr: add/remove the current folder's devpod workspace as a machine
alias hma='herdr machine add "${PWD:t}.devpod"'
alias tbo='terminal-browser open --ssh "${PWD:t}.devpod"'
# forward a port from the current folder's devpod workspace: sshpfw 3000
sshpfw() { ssh -L "${1}:localhost:${1}" "${PWD:t}.devpod"; }
# remove takes a profile id, so look it up by name in `herdr machine list`
unalias hmr 2>/dev/null
function hmr {
    local name="${PWD:t}.devpod" id
    id=$(herdr machine list | awk -F'\t' -v n="$name" '$2 == n { print $1; exit }')
    if [[ -z "$id" ]]; then
        echo "hmr: no saved machine named $name" >&2
        return 1
    fi
    herdr machine remove "$id"
}
# hdrcl: remove every saved machine that `herdr machine status` reports as error
unalias hdrcl 2>/dev/null
function hdrcl {
    local ids id name
    echo "hdrcl: checking saved machines (takes ~2s per machine)..."
    ids=$(herdr machine status </dev/null 2>/dev/null | awk -F'\t' '$3 == "error" { print $1 "\t" $2 }')
    if [[ -z "$ids" ]]; then
        echo "hdrcl: no machines in error state"
        return 0
    fi
    while IFS=$'\t' read -r id name; do
        echo "removing $name ($id)"
        herdr machine remove "$id" </dev/null
    done <<< "$ids"
}
# ds [workspace]: ssh into a devpod workspace (default: current folder name) with a reverse
# tunnel on 17777, so xdg-open/$BROWSER in the container opens URLs in the host browser
# (needs host-browser.service). Falls back to plain `devpod ssh` if no ssh host entry exists.
ds() {
    local ws="${1:-${PWD:t}}"
    if grep -q "^Host ${ws}\.devpod$" ~/.ssh/config 2>/dev/null; then
        ssh -R 17777:127.0.0.1:17777 "${ws}.devpod"
    else
        devpod ssh "$@"
    fi
}
alias drm="devpod delete"

zstyle ':bracketed-paste-magic' active-widgets '.self-*'

if [ -S "$XDG_RUNTIME_DIR/podman/podman.sock" ]; then
    export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
fi
export COMPOSE_BAKE=false DOCKER_BUILDKIT=0

export PATH="$HOME/.local/bin:$PATH"

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
