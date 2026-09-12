# ==============================================================================
#  ~/.config/fzf/fzf.bash - Production-Grade FZF Configuration for Bash
#  Themed in Catppuccin Mocha | Optimized for Sway / Wayland / Ghostty
# ==============================================================================
#
# Sections:
#   1. Binary & Tool Detection (fd/fdfind, bat/batcat, eza/tree, rg, wl-copy)
#   2. Catppuccin Mocha Palette & Global Default Options (FZF_DEFAULT_OPTS)
#   3. File Indexing & Commands (FZF_DEFAULT_COMMAND, CTRL_T, ALT_C)
#   4. Widget Options & Rich Previews (FZF_CTRL_T_OPTS, FZF_ALT_C_OPTS, FZF_CTRL_R_OPTS)
#   5. Initialization (fzf --bash, key-bindings, completions)
#   6. Vi-Mode Readline Keybinding Synchronization
#   7. Fuzzy Completion Settings & Triggers (**<TAB>)
#   8. Senior Workflow Functions & Aliases (fe, fif, fcd, fkill, fgb, fgl, fgst)
# ==============================================================================

# Return early if not running interactively
case $- in
    *i*) ;;
      *) return 2>/dev/null || exit 0 ;;
esac

# ------------------------------------------------------------------------------
# 1. Binary & Tool Detection
# ------------------------------------------------------------------------------
_fzf_has() { command -v "$1" &>/dev/null; }

# Fast file finder: fd or fdfind (Ubuntu/Debian packages fd as fdfind)
if _fzf_has fd; then
    _FZF_FD_CMD="fd"
elif _fzf_has fdfind; then
    _FZF_FD_CMD="fdfind"
else
    _FZF_FD_CMD=""
fi

# Syntax-highlighted viewer: bat or batcat (Ubuntu/Debian packages bat as batcat)
if _fzf_has bat; then
    _FZF_BAT_CMD="bat"
elif _fzf_has batcat; then
    _FZF_BAT_CMD="batcat"
else
    _FZF_BAT_CMD=""
fi

# Directory tree visualizer: eza or tree
if _fzf_has eza; then
    _FZF_TREE_CMD="eza --tree --level=2 --color=always --icons --group-directories-first"
elif _fzf_has tree; then
    _FZF_TREE_CMD="tree -C -L 2"
else
    _FZF_TREE_CMD="ls -la --color=always"
fi

# Fast search engine: ripgrep
if _fzf_has rg; then
    _FZF_RG_CMD="rg"
else
    _FZF_RG_CMD=""
fi

# Clipboard utility for Wayland / Sway (fallback to X11 xclip)
if _fzf_has wl-copy; then
    _FZF_CLIP_CMD="wl-copy"
elif _fzf_has xclip; then
    _FZF_CLIP_CMD="xclip -selection clipboard"
else
    _FZF_CLIP_CMD=""
fi

# ------------------------------------------------------------------------------
# 2. Catppuccin Mocha Palette & Global Default Options
# ------------------------------------------------------------------------------
# Catppuccin Mocha Color Palette:
#   Base:        #1e1e2e    Surface0:    #313244    Surface1:    #45475a
#   Text:        #cdd6f4    Mauve:       #cba6f7    Red:         #f38ba8
#   Lavender:    #b4befe    Rosewater:   #f5e0dc    Sapphire:    #74c7ec
export FZF_DEFAULT_OPTS=" \
    --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
    --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
    --color=selected-bg:#45475a \
    --height 60% \
    --layout=reverse \
    --border=rounded \
    --inline-info \
    --prompt='❯ ' \
    --pointer='◆ ' \
    --marker='✓ ' \
    --bind 'ctrl-/:toggle-preview' \
    --bind 'ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down'"

# ------------------------------------------------------------------------------
# 3. File Indexing & Default Search Commands
# ------------------------------------------------------------------------------
if [[ -n "$_FZF_FD_CMD" ]]; then
    # Respect .gitignore, index hidden files, exclude .git directory
    export FZF_DEFAULT_COMMAND="$_FZF_FD_CMD --type f --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="$_FZF_FD_CMD --hidden --follow --exclude .git"
    export FZF_ALT_C_COMMAND="$_FZF_FD_CMD --type d --hidden --follow --exclude .git"
else
    export FZF_DEFAULT_COMMAND="find . -mindepth 1 -not -path '*/.*' -type f"
    export FZF_CTRL_T_COMMAND="find . -mindepth 1 -not -path '*/.*'"
    export FZF_ALT_C_COMMAND="find . -mindepth 1 -not -path '*/.*' -type d"
fi

# ------------------------------------------------------------------------------
# 4. Widget Options & Rich Previews
# ------------------------------------------------------------------------------

# CTRL-T: Find files and directories with context-aware preview
export FZF_CTRL_T_OPTS=" \
    --preview 'if [ -d {} ]; then (eza --tree --level=2 --color=always --icons {} 2>/dev/null || tree -C -L 2 {} 2>/dev/null || ls -la --color=always {}); elif [ -f {} ]; then (bat --style=numbers --color=always --line-range :300 {} 2>/dev/null || batcat --style=numbers --color=always --line-range :300 {} 2>/dev/null || head -n 200 {}); else echo {}; fi' \
    --preview-window=right:55%:hidden:wrap \
    --header 'CTRL-/: Toggle preview | TAB: Multi-select | Enter: Insert path'"

# ALT-C: Directory navigation with tree preview
export FZF_ALT_C_OPTS=" \
    --preview 'eza --tree --level=2 --color=always --icons {} 2>/dev/null || tree -C -L 2 {} 2>/dev/null || ls -la --color=always {}' \
    --preview-window=right:50%:hidden:wrap \
    --header 'CTRL-/: Toggle preview | Enter: cd into directory'"

# CTRL-R: Command history search with preview and Wayland clipboard copy
_clip_pipeline="printf \"%s\" {2..} | (${_FZF_CLIP_CMD:-wl-copy} 2>/dev/null)"
export FZF_CTRL_R_OPTS=" \
    --preview 'echo {}' \
    --preview-window=down:3:hidden:wrap \
    --bind 'ctrl-y:execute-silent($_clip_pipeline)+abort' \
    --header 'CTRL-Y: Copy command | CTRL-/: Toggle wrap preview | Enter: Run command'"
unset _clip_pipeline

# ------------------------------------------------------------------------------
# 5. Initialization (Completions & Keybindings)
# ------------------------------------------------------------------------------
if _fzf_has fzf; then
    # Modern fzf (0.48.0+) provides self-contained bash integration
    if fzf --bash &>/dev/null; then
        eval "$(fzf --bash)"
    else
        # Fallback discovery for distribution packages & manual installs
        # Key bindings
        for _kb in \
            "/usr/share/doc/fzf/examples/key-bindings.bash" \
            "/usr/share/fzf/key-bindings.bash" \
            "/usr/share/fzf/shell/key-bindings.bash" \
            "/etc/profile.d/fzf-key-bindings.bash" \
            "$HOME/.fzf/shell/key-bindings.bash"; do
            if [[ -f "$_kb" ]]; then
                # shellcheck source=/dev/null
                source "$_kb"
                break
            fi
        done

        # Completions
        for _comp in \
            "/usr/share/doc/fzf/examples/completion.bash" \
            "/usr/share/fzf/completion.bash" \
            "/usr/share/fzf/shell/completion.bash" \
            "/usr/share/bash-completion/completions/fzf" \
            "/etc/bash_completion.d/fzf" \
            "$HOME/.fzf/shell/completion.bash"; do
            if [[ -f "$_comp" ]]; then
                # shellcheck source=/dev/null
                source "$_comp"
                break
            fi
        done
        unset _kb _comp
    fi
fi

# ------------------------------------------------------------------------------
# 6. Vi-Mode Readline Keybinding Synchronization
# ------------------------------------------------------------------------------
# When `set -o vi` is enabled in Bash, Readline binds to `vi-insert` and
# `vi-command` modes instead of `emacs-standard`. Ensure seamless operation:
if [[ -t 0 ]] && [[ -o vi ]]; then
    # CTRL-R: Fuzzy history search
    if declare -F __fzf_history__ &>/dev/null; then
        bind -m vi-insert -x '"\C-r": __fzf_history__' 2>/dev/null
        bind -m vi-command -x '"\C-r": __fzf_history__' 2>/dev/null
    fi

    # CTRL-T: Fuzzy file insertion
    if declare -F __fzf_select__ &>/dev/null; then
        bind -m vi-insert -x '"\C-t": __fzf_select__' 2>/dev/null
        bind -m vi-command -x '"\C-t": __fzf_select__' 2>/dev/null
    elif declare -F fzf-file-widget &>/dev/null; then
        bind -m vi-insert -x '"\C-t": fzf-file-widget' 2>/dev/null
        bind -m vi-command -x '"\C-t": fzf-file-widget' 2>/dev/null
    fi

    # ALT-C: Fuzzy cd navigation
    if declare -F __fzf_cd__ &>/dev/null; then
        bind -m vi-insert -x '"\ec": __fzf_cd__' 2>/dev/null
        bind -m vi-command -x '"\ec": __fzf_cd__' 2>/dev/null
    elif declare -F fzf-cd-widget &>/dev/null; then
        bind -m vi-insert -x '"\ec": fzf-cd-widget' 2>/dev/null
        bind -m vi-command -x '"\ec": fzf-cd-widget' 2>/dev/null
    fi
fi

# ------------------------------------------------------------------------------
# 7. Fuzzy Completion Settings & Triggers (**<TAB>)
# ------------------------------------------------------------------------------
# Options for default completion trigger (e.g., `code **<TAB>`, `cd **<TAB>`)
export FZF_COMPLETION_TRIGGER='**'

# Path generator using fd if available
_fzf_compgen_path() {
    if [[ -n "$_FZF_FD_CMD" ]]; then
        "$_FZF_FD_CMD" --hidden --follow --exclude ".git" . "$1"
    else
        find "$1" -path '*/.*' -prune -o -type f -print -o -type d -print | sed -e 's@^\./@@'
    fi
}

# Directory generator using fd if available
_fzf_compgen_dir() {
    if [[ -n "$_FZF_FD_CMD" ]]; then
        "$_FZF_FD_CMD" --type d --hidden --follow --exclude ".git" . "$1"
    else
        find "$1" -path '*/.*' -prune -o -type d -print | sed -e 's@^\./@@'
    fi
}

# Context-aware completion runner with preview
_fzf_comprun() {
    local command=$1
    shift

    case "$command" in
        cd)
            fzf --preview 'eza --tree --level=2 --color=always --icons {} 2>/dev/null || tree -C -L 2 {} 2>/dev/null || ls -la --color=always {}' "$@" ;;
        export|unset)
            fzf --preview "eval 'echo \${}'" "$@" ;;
        ssh)
            fzf --preview 'dig {} 2>/dev/null || host {} 2>/dev/null' "$@" ;;
        kill|pkill)
            fzf --preview 'ps -fp {} 2>/dev/null || ps aux | grep {}' "$@" ;;
        *)
            fzf --preview 'if [ -d {} ]; then (eza --tree --level=2 --color=always --icons {} 2>/dev/null || tree -C -L 2 {} 2>/dev/null || ls -la --color=always {}); elif [ -f {} ]; then (bat --style=numbers --color=always --line-range :300 {} 2>/dev/null || batcat --style=numbers --color=always --line-range :300 {} 2>/dev/null || head -n 200 {}); else echo {}; fi' "$@" ;;
    esac
}

# ------------------------------------------------------------------------------
# 8. Senior Workflow Functions & Aliases
# ------------------------------------------------------------------------------

# fe [query] - Fuzzy edit file(s) with preview in $EDITOR (Neovim)
fe() {
    local editor="${EDITOR:-nvim}"
    local files=()
    local preview_cmd='if [ -d {} ]; then (eza --tree --level=2 --color=always --icons {} 2>/dev/null || tree -C -L 2 {} 2>/dev/null || ls -la --color=always {}); elif [ -f {} ]; then (bat --style=numbers --color=always --line-range :300 {} 2>/dev/null || batcat --style=numbers --color=always --line-range :300 {} 2>/dev/null || head -n 200 {}); else echo {}; fi'

    mapfile -t files < <(
        fzf --query="$1" \
            --multi \
            --select-1 \
            --exit-0 \
            --preview "$preview_cmd" \
            --preview-window=right:55%:wrap \
            --header 'Tab: Multi-select | Enter: Edit | Esc: Cancel'
    )

    if [[ ${#files[@]} -gt 0 ]]; then
        "$editor" "${files[@]}"
    fi
}

# fif [query] - Interactive ripgrep live search with syntax preview and jump to line
fif() {
    if [[ -z "$_FZF_RG_CMD" ]]; then
        echo "fif error: ripgrep (rg) is not installed." >&2
        return 1
    fi

    local editor="${EDITOR:-nvim}"
    local initial_query="${*:-}"
    local rg_prefix="$_FZF_RG_CMD --column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git'"
    local preview_script

    if [[ -n "$_FZF_BAT_CMD" ]]; then
        preview_script="$_FZF_BAT_CMD --color=always --style=numbers --highlight-line {2} {1} 2>/dev/null || cat {1}"
    else
        preview_script="head -n 200 {1}"
    fi

    local selection
    selection=$(
        FZF_DEFAULT_COMMAND="$rg_prefix ''" \
        fzf --ansi \
            --disabled \
            --query "$initial_query" \
            --bind "start:reload:$rg_prefix {q} || true" \
            --bind "change:reload:$rg_prefix {q} || true" \
            --delimiter : \
            --preview "$preview_script" \
            --preview-window=right:60%:wrap \
            --header 'Type to search text | Enter: Open in editor | Esc: Cancel'
    )

    if [[ -n "$selection" ]]; then
        local file line
        file=$(cut -d: -f1 <<< "$selection")
        line=$(cut -d: -f2 <<< "$selection")
        "$editor" "+$line" "$file"
    fi
}

# fcd [path] - Fuzzy cd into any directory (including hidden directories)
fcd() {
    local target_dir
    local search_path="${1:-.}"
    local tree_cmd='eza --tree --level=2 --color=always --icons {} 2>/dev/null || tree -C -L 2 {} 2>/dev/null || ls -la --color=always {}'

    if [[ -n "$_FZF_FD_CMD" ]]; then
        target_dir=$("$_FZF_FD_CMD" --type d --hidden --follow --exclude .git . "$search_path" | \
            fzf +m --preview "$tree_cmd" --preview-window=right:50%:wrap --header 'Select directory to cd')
    else
        target_dir=$(find "$search_path" -type d -not -path '*/.*' | \
            fzf +m --preview "$tree_cmd" --preview-window=right:50%:wrap --header 'Select directory to cd')
    fi

    if [[ -n "$target_dir" ]]; then
        cd "$target_dir" || return 1
    fi
}

# fkill [signal] - Fuzzy process killer with detailed process tree preview
fkill() {
    local signal="${1:-15}"
    local pids=()

    mapfile -t pids < <(
        ps -u "$USER" -o pid,%cpu,%mem,stat,start,time,comm,command | \
        sed 1d | \
        fzf --multi \
            --header "Select process(es) to kill (Signal: SIG${signal}) | Tab: Multi-select" \
            --preview 'ps -fp {1} 2>/dev/null' \
            --preview-window=down:30%:wrap | \
        awk '{print $1}'
    )

    if [[ ${#pids[@]} -gt 0 ]]; then
        echo "Sending SIG${signal} to PID(s): ${pids[*]}"
        kill -"$signal" "${pids[@]}"
    fi
}

# fgb - Fuzzy git branch switcher with commit log preview
fgb() {
    git rev-parse --is-inside-work-tree &>/dev/null || { echo "Not a git repository" >&2; return 1; }
    local branch
    branch=$(
        git for-each-ref --format='%(refname:short) | %(contents:subject) | %(authorname)' refs/heads refs/remotes | \
        fzf --header 'Select branch to checkout | Enter: Switch' \
            --preview 'git log --oneline --graph --date=short --color=always $(cut -d" " -f1 <<< {})' \
            --preview-window=right:60%:wrap | \
        awk '{print $1}'
    )
    if [[ -n "$branch" ]]; then
        local local_branch="${branch#origin/}"
        git checkout "$local_branch" 2>/dev/null || git checkout "$branch"
    fi
}

# fgl - Fuzzy git commit viewer with commit diff preview & commit hash copy
fgl() {
    git rev-parse --is-inside-work-tree &>/dev/null || { echo "Not a git repository" >&2; return 1; }
    local commit
    commit=$(
        git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" | \
        fzf --ansi --no-sort --reverse --tiebreak=index \
            --header 'Enter: View full commit | CTRL-Y: Copy commit SHA' \
            --bind 'ctrl-y:execute-silent(grep -o "[a-f0-9]\{7,\}" <<< {} | head -n1 | ('"${_FZF_CLIP_CMD:-wl-copy}"' 2>/dev/null))+abort' \
            --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | head -n1 | xargs git show --color=always' \
            --preview-window=right:60%:wrap
    )
    if [[ -n "$commit" ]]; then
        local sha
        sha=$(grep -o "[a-f0-9]\{7,\}" <<< "$commit" | head -n1)
        [[ -n "$sha" ]] && git show "$sha"
    fi
}

# fgst - Fuzzy git status viewer with diff preview and interactive staging
fgst() {
    git rev-parse --is-inside-work-tree &>/dev/null || { echo "Not a git repository" >&2; return 1; }
    local selected
    selected=$(
        git -c color.status=always status --short | \
        fzf --ansi \
            --multi \
            --header 'Enter: Open in editor | CTRL-S: Stage/Unstage file' \
            --preview 'git diff --color=always -- {2} 2>/dev/null | head -n 300' \
            --preview-window=right:60%:wrap \
            --bind 'ctrl-s:execute(git add {2} 2>/dev/null || git restore --staged {2} 2>/dev/null)+reload(git -c color.status=always status --short)'
    )
    if [[ -n "$selected" ]]; then
        local files=()
        while IFS= read -r line; do
            local f
            f=$(awk '{print $2}' <<< "$line")
            [[ -n "$f" ]] && files+=("$f")
        done <<< "$selected"
        [[ ${#files[@]} -gt 0 ]] && "${EDITOR:-nvim}" "${files[@]}"
    fi
}

# Ergonomic aliases
alias fzf-edit="fe"
alias fzf-grep="fif"
alias fzf-cd="fcd"
alias fzf-kill="fkill"
alias fzf-branch="fgb"
alias fzf-log="fgl"
alias fzf-status="fgst"
