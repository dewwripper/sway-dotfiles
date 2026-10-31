# Sway Dotfiles for Ubuntu 26.04

A clean, modern, and high-performance Wayland desktop environment setup powered by **Sway**, **Quickshell**, **Ghostty**, and **Zsh** with **Starship** prompt (faithfully replicating the Powerlevel10k Lean theme, Catppuccin Mocha theme & Nerd Fonts).

---

## 📸 Desktop Stack Overview

| Component | Software | Description |
| :--- | :--- | :--- |
| **Window Manager** | [Sway](https://swaywm.org/) | i3-compatible Wayland tiling compositor |
| **Status Bar** | [Quickshell](https://quickshell.outfoxxed.me/) | Flexible QtQuick/QML-based desktop shell & status bar (Catppuccin Mocha theme) |
| **Terminal** | [Ghostty](https://ghostty.org/) | Fast, feature-rich GPU-accelerated terminal |
| **Editor** | [Neovim](https://neovim.io/) | Modern modal text editor configured with LazyVim & Catppuccin Mocha theme |
| **App Launcher** | [Rofi](https://github.com/davatorium/rofi) | Application menu & window switcher |
| **Shell & Prompt** | [Zsh](https://www.zsh.org/) + [Starship](https://starship.rs/) | Powerlevel10k Lean replica prompt, Vi mode, fzf (Catppuccin Mocha), zoxide, eza, git completions |
| **Fonts** | JetBrains Mono & Hack Nerd Font | High-legibility coding fonts with complete icon glyphs |
| **Audio / Media** | PipeWire / WirePlumber & Pavucontrol | Controlled via `wpctl`, GUI mixer via `pavucontrol`, and brightness via `brightnessctl` |

---

## 🛠️ Installation Guide for Ubuntu 26.04

Follow the step-by-step instructions below to set up and deploy these dotfiles on a fresh or existing Ubuntu 26.04 LTS installation.

---

### Step 1: Update System & Install Base Utilities

Ensure your package repositories are up-to-date and install core command-line tools:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
    git \
    curl \
    wget \
    unzip \
    tar \
    fontconfig \
    build-essential
```

---

### Step 2: Install JetBrains Mono & Hack Nerd Fonts

These dotfiles use **Hack Nerd Font** for Ghostty and **JetBrains Mono Nerd Font** (along with Hack) for Quickshell icons and status indicators.

Run the following commands to download and install both Nerd Fonts in the system:

```bash
# Create local font directory
mkdir -p ~/.local/share/fonts/NerdFonts

# 1. Download and extract JetBrains Mono Nerd Font
echo "Downloading JetBrains Mono Nerd Font..."
wget -q --show-progress -O /tmp/JetBrainsMono.tar.xz \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
tar -xf /tmp/JetBrainsMono.tar.xz -C ~/.local/share/fonts/NerdFonts/
rm /tmp/JetBrainsMono.tar.xz

# 2. Download and extract Hack Nerd Font
echo "Downloading Hack Nerd Font..."
wget -q --show-progress -O /tmp/Hack.tar.xz \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.tar.xz
tar -xf /tmp/Hack.tar.xz -C ~/.local/share/fonts/NerdFonts/
rm /tmp/Hack.tar.xz

# 3. Rebuild font cache
fc-cache -fv

# 4. Verify font installation
fc-list : family | grep -E "JetBrainsMono Nerd Font|Hack Nerd Font" | sort -u
```

---

### Step 3: Install Sway, Quickshell & Desktop Utilities

Install Sway, Quickshell, Rofi, audio/brightness controls, and authentication tools:

```bash
sudo apt install -y \
    sway \
    swaylock \
    swayidle \
    swaybg \
    xwayland \
    xdg-desktop-portal-wlr \
    sway-notification-center \
    quickshell \
    rofi \
    brightnessctl \
    grim \
    slurp \
    pipewire \
    wireplumber \
    pipewire-pulse \
    pulseaudio-utils \
    pavucontrol \
    blueman \
    polkit-gnome \
    neovim \
    wl-clipboard \
    copyq \
    fcitx5 \
    fcitx5-unikey \
    fcitx5-frontend-all \
    fcitx5-config-qt \
    eza
```

> **Note on Polkit Authentication Agent:**
> The Sway configuration expects the polkit agent at `/usr/libexec/polkit-gnome-authentication-agent-1`. If your system placed it in `/usr/lib/policykit-1-gnome/`, create a symlink:
> ```bash
> if [ -f /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 ] && [ ! -f /usr/libexec/polkit-gnome-authentication-agent-1 ]; then
>     sudo mkdir -p /usr/libexec
>     sudo ln -s /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 /usr/libexec/polkit-gnome-authentication-agent-1
> fi
> ```

---

### Step 4: Install Ghostty Terminal

Install [Ghostty](https://ghostty.org/) using the official package repository or direct binary/deb for Ubuntu:

```bash
# Option A: Via Snap (easiest)
sudo snap install ghostty --classic

# Option B: Via official deb package from Ghostty releases
# Download the appropriate Ubuntu .deb package from https://ghostty.org or GitHub releases
# sudo dpkg -i ghostty_*.deb || sudo apt-get install -f -y
```

---

### Step 5: Install & Configure Zsh with Starship and CLI Tools

1. **Install Zsh and change default shell**:
   ```bash
   sudo apt install -y zsh
   chsh -s $(which zsh)
   ```

2. **Install Starship Prompt**:
   Starship is a fast, zero-config, highly customizable prompt configured to faithfully emulate your Powerlevel10k Lean theme:
   ```bash
   curl -sS https://starship.rs/install.sh | sh -s -- -y
   ```

3. **Install Oh My Zsh & Recommended Plugins** (optional, supported):
   ```bash
   # Oh My Zsh
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

   # zsh-autosuggestions
   git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

   # zsh-nvm
   git clone https://github.com/lukechilds/zsh-nvm ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-nvm
   ```

4. **Install Shell Utilities (`fzf`, `ripgrep`, `fd-find`, `bat`, `eza`, `zoxide`)**:
   These tools provide fuzzy searching, modern directory jumping, syntax-highlighted previews, and smart completions:
   ```bash
   # Base shell utilities & CLI tools
   sudo apt install -y fzf ripgrep fd-find bat

   # Install eza (modern ls replacement used in aliases)
   sudo apt install -y eza || {
       sudo mkdir -p /etc/apt/keyrings
       wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
       echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
       sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
       sudo apt update && sudo apt install -y eza
   }

   # Install zoxide (smart directory cd replacement for z)
   curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
   ```

5. **Install NVM (Node Version Manager)**:
   ```bash
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
   ```

---

### Step 6: Clone and Symlink Dotfiles

1. **Clone the repository**:
   ```bash
   git clone https://github.com/dewwripper/sway-dotfiles.git ~/sway-dotfiles
   ```

2. **Create configuration symlinks**:
   ```bash
   # Ensure target directories exist
   mkdir -p ~/.config

   # Backup any existing configs if present
   [ -d ~/.config/sway ] && mv ~/.config/sway ~/.config/sway.backup.$(date +%s)
   [ -d ~/.config/quickshell ] && mv ~/.config/quickshell ~/.config/quickshell.backup.$(date +%s)
   [ -d ~/.config/swaync ] && mv ~/.config/swaync ~/.config/swaync.backup.$(date +%s)
   [ -d ~/.config/ghostty ] && mv ~/.config/ghostty ~/.config/ghostty.backup.$(date +%s)
   [ -d ~/.config/rofi ] && mv ~/.config/rofi ~/.config/rofi.backup.$(date +%s)
   [ -d ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim.backup.$(date +%s)
   [ -d ~/.config/starship ] && mv ~/.config/starship ~/.config/starship.backup.$(date +%s)
   [ -d ~/.config/fzf ] && mv ~/.config/fzf ~/.config/fzf.backup.$(date +%s)
   [ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.backup.$(date +%s)

   # Link configurations
   ln -sfn ~/sway-dotfiles/.config/sway ~/.config/sway
   ln -sfn ~/sway-dotfiles/.config/quickshell ~/.config/quickshell
   ln -sfn ~/sway-dotfiles/.config/swaync ~/.config/swaync
   ln -sfn ~/sway-dotfiles/.config/ghostty ~/.config/ghostty
   ln -sfn ~/sway-dotfiles/.config/rofi ~/.config/rofi
   ln -sfn ~/sway-dotfiles/.config/nvim ~/.config/nvim
   ln -sfn ~/sway-dotfiles/.config/starship ~/.config/starship
   ln -sfn ~/sway-dotfiles/.config/fzf ~/.config/fzf
   ln -sf ~/sway-dotfiles/.zshrc ~/.zshrc
   ```

---

### Step 7: Launching Sway

1. Log out of your current desktop session.
2. At the display manager (GDM/SDDM/Greetd) login screen, select **Sway** as the session type, or launch directly from TTY by running:
   ```bash
   sway
   ```
3. Ghostty will launch Zsh with the custom Starship prompt preloaded from `~/.config/starship/starship.toml`.


---

## ⌨️ Keybindings Cheat Sheet

The default modifier key is `Mod4` (**Super / Windows Key**).

### Window Management & Launchers
| Shortcut | Action |
| :--- | :--- |
| `Super + Return` | Open Ghostty terminal |
| `Super + d` | Open Rofi application launcher |
| `Super + q` | Close / kill focused window |
| `Super + f` | Toggle fullscreen |
| `Super + Shift + Space` | Toggle floating mode |
| `Super + Space` | Toggle focus between tiling & floating |
| `Super + b` | Split layout horizontally |
| `Super + v` | Split layout vertically |
| `Super + s` | Stacking layout |
| `Super + w` | Tabbed layout |
| `Super + e` | Toggle split layout |
| `Super + r` | Enter window resize mode (`Esc`/`Enter` to exit) |

### Navigation & Workspaces
| Shortcut | Action |
| :--- | :--- |
| `Super + [h/j/k/l]` or `Super + Arrow` | Move focus (left, down, up, right) |
| `Super + Shift + [h/j/k/l]` or `Arrow` | Move focused window |
| `Super + [1-9, 0]` | Switch to workspace 1–10 |
| `Super + Shift + [1-9, 0]` | Move focused window to workspace 1–10 |
| `Super + Shift + -` | Move window to scratchpad |
| `Super + -` | Show / cycle scratchpad windows |

### System & Media Controls
| Shortcut | Action |
| :--- | :--- |
| `Super + Shift + c` | Reload Sway configuration |
| `Super + Shift + e` | Exit Sway (logout prompt) |
| `Super + Shift + n` | Toggle notification control center (`swaync-client -t -sw`) |
| `Super + Shift + d` | Toggle Do Not Disturb (`swaync-client -d -sw`) |
| `Print` | Take screenshot with `grim` |
| `Super + Shift + v` | Open audio control mixer (`pavucontrol` floating) |
| `Super + Shift + b` | Open Bluetooth manager (`blueman-manager` floating) |
| `Super + c + k` | Toggle input method English ↔ Vietnamese (`fcitx5-remote -t`) |
| `XF86AudioRaiseVolume` | Increase volume (+5%) via WirePlumber |
| `XF86AudioLowerVolume` | Decrease volume (-5%) via WirePlumber |
| `XF86AudioMute` | Toggle audio mute via WirePlumber |
| `XF86MonBrightnessUp` | Increase display brightness (+5%) via `brightnessctl` |
| `XF86MonBrightnessDown` | Decrease display brightness (-5%) via `brightnessctl` |

### 🔊 Audio & Volume Management
- **Hardware Keys:** Adjust volume (+5% / -5%) and toggle mute using dedicated media keys via WirePlumber (`wpctl`).
- **GUI Mixer (`pavucontrol`):** Open the PipeWire/PulseAudio mixer using `Super + Shift + v`.
- **Floating Window Rule:** `pavucontrol` automatically opens as a centered floating window (`700x500`) rather than splitting your tiled layout.

### 󰂯 Bluetooth Management
- **GUI Manager (`blueman-manager`):** Full-featured GTK Bluetooth manager tailored for standalone window managers like Sway.
  - Discover, pair, connect, and manage Bluetooth devices.
  - Audio profile selection (A2DP / HSP/HFP) and file transfers.
- **Floating Window Rule:** `blueman-manager` automatically opens as a centered floating window (`700x500`) via `~/.config/sway/config.d/bluetooth.conf`.
- **Shortcuts:** Press `Super + Shift + b` or right-click the Quickshell Bluetooth button to open `blueman-manager`.

### 🔔 Notification Center (SwayNotificationCenter)
- **Daemon:** Sway launches `swaync` automatically on startup via `~/.config/sway/config.d/notifications.conf`.
- **Control Center:** Press `Super + Shift + n` or click the bell icon in Quickshell to toggle the Catppuccin Mocha notification panel with media player controls, volume slider, and quick action toggles.
- **Do Not Disturb:** Press `Super + Shift + d` or right-click the notification bell in Quickshell to toggle DND mode.

### 📊 Quickshell Status Bar
- **Workspaces:** Interactive workspace indicators on the left; click any workspace number to switch directly to it.
- **Active Window:** Displays the currently focused application title in the center.
- **Volume Control:**
  - **Indicator:** Real-time volume percentage with dynamic Nerd Font speaker icons (`󰕾`, `󰖀`, `󰕿`) and mute indicator (`󰝟 Muted`).
  - **Left-Click:** Toggle audio mute.
  - **Right-Click:** Open GUI mixer (`pavucontrol`).
  - **Scroll Up / Down:** Raise / lower volume by 5%.
- **Twingate:** (hidden when the `twingate` CLI is not installed)
  - **Indicator:** Connection status (`󰒃 TG` when online, `󰦞 Off` otherwise), read from `systemctl is-active twingate` and the `sdwan0` tunnel rather than `twingate status`: the daemon answers CLI calls on a single thread and wedges when polled frequently. Resources are only fetched when the dropdown opens. `󰒙 TG?` means that fetch got no answer from the daemon; the dropdown then offers **Restart Twingate service** (`sudo systemctl restart twingate`).
  - **Left-Click:** Toggle a dropdown listing your authorized resources with their address / alias and auth expiry. Type in the search field to filter by name, address or alias (`Enter` acts on the top match, `Esc` clears the search, then closes the dropdown). Click a resource to copy its address to the clipboard, or re-authenticate it (`twingate auth`) if its auth has lapsed.
  - **Right-Click:** Connect / disconnect (`twingate start` / `twingate stop`, opened in Ghostty for the sudo prompt).
- **Bluetooth Control:**
  - **Indicator:** Real-time Bluetooth adapter and connection status (`󰂱 <Device>` when connected, `󰂯 On` when active, `󰂲 Off` when disabled).
  - **Left-Click:** Toggle Bluetooth power on / off.
  - **Right-Click:** Open Bluetooth manager (`blueman-manager`).
- **Notification Center:**
  - **Indicator:** Bell icon (`󰂚`).
  - **Left-Click:** Toggle SwayNotificationCenter control panel (`swaync-client -t -sw`).
  - **Right-Click:** Toggle Do Not Disturb (`swaync-client -d -sw`).
- **Clock:** Real-time date and digital clock formatted on the right.
- **Power & Shutdown Menu:**
  - **Left-Click:** Toggle the native desktop dropdown menu under the button with options for **Lock** (``), **Suspend** (`󰒲`), **Hibernate** (`󰒄`), **Reboot** (`󰜉`), and **Shutdown** (``).
  - **Right-Click:** Immediate screen lock (`swaylock`).
  - **Dismiss:** Click outside or select any option to automatically close the dropdown.

### 🔍 FZF (Fuzzy Finder) & Interactive Utilities
FZF shell integration is configured following the official upstream standard (`eval "$(fzf --bash)"`), themed with a **Catppuccin Mocha** palette, built-in `--walker-skip` options, preview toggles (`Ctrl + /`), Wayland clipboard integration (`Ctrl + y`), and Vi-mode compatibility.

| Keybinding / Command | Description |
| :--- | :--- |
| `Ctrl + t` | Fuzzy find files & directories, with live syntax-highlighted / tree preview |
| `Ctrl + r` | Fuzzy search command history; press `Ctrl + y` to copy command to Wayland clipboard |
| `Alt + c` | Fuzzy cd into subdirectories with `eza` tree preview |
| `**<TAB>` | Fuzzy completion trigger for file paths, `cd`, `ssh`, `kill`, environment variables |
| `fe [query]` | **Fuzzy Edit:** Interactively select file(s) with preview and open in `$EDITOR` (`nvim`) |
| `fif [query]` | **Fuzzy Ripgrep:** Live interactive regex text search across repo with line jump in `$EDITOR` |
| `fcd [dir]` | **Fuzzy CD:** Interactively browse and change directories with tree preview |
| `fkill [signal]` | **Fuzzy Kill:** Interactive process manager showing CPU/MEM with process tree preview |
| `fgb` | **Fuzzy Git Branch:** Switch local/remote branches with commit graph preview |
| `fgl` | **Fuzzy Git Log:** Browse commit history; view diffs and copy commit SHA via `Ctrl + y` |
| `fgst` | **Fuzzy Git Status:** Browse modified files; press `Ctrl + s` to stage/unstage |

### 🚀 Starship Prompt Configuration
The prompt is defined in `~/.config/starship/starship.toml` (symlinked from this repo). `.zshrc` points Starship at it via `STARSHIP_CONFIG` and runs `eval "$(starship init zsh)"`.

**Prompt layout:**
- **Left (`format`):** directory → git branch / commit / state / metrics / status → prompt character (`➜` success, `✗` error, `❮` Vi command mode).
- **Right (`right_format`):** exit status → command duration (≥ 3s) → background jobs → direnv → `$ENV` → language runtimes → Kubernetes / Terraform / AWS (+ session time left) / Azure → Docker / Nix → username → hostname → time.

**Common customizations:**
| Goal | Change in `starship.toml` |
| :--- | :--- |
| Add / remove / reorder a module | Edit the `$module` list in `format` (left) or `right_format` (right); custom modules use `${custom.name}`, env vars use `${env_var.NAME}` |
| Disable a module entirely | Add `disabled = true` under its `[module]` table (e.g. `[package]`, `[gcloud]`) |
| Show hostname only over SSH | Set `ssh_only = true` under `[hostname]` (currently `false`, so it's always shown) |
| Always show username | Set `show_always = true` under `[username]` |
| Change colors | Edit `style` values: 256-color numbers (`"bold 76"`), names (`"bold red"`), or hex (`"#89b4fa"`) |
| Change the slow-command threshold | Set `min_time` (ms) under `[cmd_duration]` |
| Highlight production clusters | Add `[[kubernetes.contexts]]` entries with a `context_pattern` regex and `style` |
| Add a custom segment | Add a `[custom.name]` table with `command` / `when` / `format`, then reference `${custom.name}` in a format string |

**Testing changes** (edits apply on the next prompt; no reload needed):
```bash
starship explain                 # Show each module in the current prompt and how long it took
starship module hostname         # Render a single module
starship print-config hostname   # Show a module's effective config, including defaults
starship timings                 # Find slow modules
```

See the [Starship configuration docs](https://starship.rs/config/) for every module and option.

### ⌨️ Input Method (Fcitx5 – Vietnamese Unikey)
Vietnamese typing is provided by **Fcitx5** with the **Unikey** engine.

- **Daemon:** Sway starts `fcitx5 -d --replace` on login via `~/.config/sway/config.d/input.conf`.
- **Environment:** `~/.zshrc` exports `XMODIFIERS=@im=fcitx`, `QT_IM_MODULE=fcitx` and `GTK_IM_MODULE=fcitx` so GTK, Qt and XWayland apps use Fcitx5.
- **Toggle English ↔ Vietnamese:** Press `Super + c + k` (hold `Super`, then press `c` and `k` together), or left-click the `󰌌 ENG` / `󰌌 VIE` button in Quickshell.
- **Configure:** Right-click the Quickshell input method button (or run `fcitx5-configtool`) to change input methods, the Unikey typing style (Telex / VNI / VIQR), and other options.
- **Status bar indicator:** The button shows `ENG` (keyboard layout), `VIE` (Unikey active), or `N/A` if Fcitx5 isn't running. Left-clicking it while it shows `N/A` starts the daemon.

**First-time setup:** If Unikey isn't in the list yet, open `fcitx5-configtool`, keep **Keyboard - English (US)** as the first entry, then add **Unikey** below it. `Super + c + k` switches between the first and the active input method, so the order matters. The resulting `~/.config/fcitx5/profile` should look like:
```ini
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=unikey

[Groups/0/Items/0]
Name=keyboard-us

[Groups/0/Items/1]
Name=unikey
```

**Troubleshooting**
- **Can't type Vietnamese in an app:** Make sure the environment variables above are set for your Sway session (log out and back in after editing `~/.zshrc`), then restart Fcitx5 with `fcitx5 -d --replace`.
- **Check the current input method:** `fcitx5-remote -n` prints `keyboard-us` or `unikey`.
- **Diagnose problems:** Run `fcitx5-diagnose` to check frontends, environment variables and addons.

### 📋 Clipboard (Wayland, Neovim & CopyQ)
Clipboard support is provided by **wl-clipboard** (`wl-copy` / `wl-paste`), with **CopyQ** running as the clipboard history manager (started from `sway/config.d/clipboard.conf`).

- **Neovim:** LazyVim sets `clipboard=unnamedplus`, so `y` / `p` use the system clipboard directly. Neovim picks `wl-copy` automatically when `WAYLAND_DISPLAY` is set.
- **CopyQ:** Its window opens as a floating popup centered on screen; the bar button toggles it.

**Troubleshooting: yank/paste in Neovim doesn't reach other apps**

1. Check which clipboard tool Neovim is using:
   ```vim
   :checkhealth vim.provider
   ```
   The *Clipboard* section should report `Clipboard tool found: wl-copy`.
2. If it reports `xclip` / `xsel` (or nothing), `wl-clipboard` is missing. Neovim falls back to the X11 (XWayland) clipboard, which doesn't sync reliably with native Wayland apps such as Ghostty, browsers, or CopyQ. Install it and restart Neovim:
   ```bash
   sudo apt install -y wl-clipboard
   ```
3. Verify the clipboard works outside Neovim:
   ```bash
   echo "hello" | wl-copy && wl-paste
   ```

### 🔔 Notifications Not Showing / `Super + Shift + n` Does Nothing
If the `xfce4` package is installed, `xfce4-notifyd` gets D-Bus-activated at login and claims `org.freedesktop.Notifications` before `swaync` starts, so `swaync` exits and `swaync-client` hangs.
1. Check who owns the notification bus name:
   ```bash
   busctl --user status org.freedesktop.Notifications | grep Comm=
   ```
2. If it is not `swaync`, mask `xfce4-notifyd` and start `swaync`:
   ```bash
   systemctl --user mask --now xfce4-notifyd.service
   pkill -x swaync-client; swaymsg exec swaync
   notify-send "test" "swaync works"
   ```
   (Undo with `systemctl --user unmask xfce4-notifyd.service`.)

### 🔄 Reloading Configurations
- **Reload Sway:** Press `Super + Shift + c` (or run `swaymsg reload`).
- **Restart Quickshell:** Run `pkill quickshell; quickshell &` (or detached with `quickshell -d`).
- **Reload SwayNC:** Run `swaync-client -R && swaync-client -rs`.
- **Reload Zsh:** Run `source ~/.zshrc`.

---

## 📁 Repository Structure

```text
sway-dotfiles/
├── .config/
│   ├── fzf/                 # Production-grade FZF configuration (Catppuccin Mocha)
│   │   ├── fzf.zsh          # Zsh keybindings, previews, completion & workflows
│   │   └── fzf.bash         # (Optional) Bash FZF configuration
│   ├── ghostty/             # Ghostty terminal config (default shell: zsh) & themes
│   │   ├── config
│   │   └── themes/
│   ├── nvim/                # Neovim configuration (LazyVim, LSP, Catppuccin)
│   │   ├── init.lua
│   │   ├── lazyvim.json
│   │   └── lua/
│   ├── quickshell/          # Quickshell status bar config (QtQuick/QML)
│   │   └── shell.qml
│   ├── rofi/                # Rofi application launcher config
│   │   └── config.rasi
│   ├── starship/            # Starship prompt configuration
│   │   └── starship.toml    # Powerlevel10k Lean replica theme
│   ├── sway/                # Sway window manager config
│   │   ├── config
│   │   ├── config.d/        # Modular configs (audio, brightness, bar, notifications, etc.)
│   │   └── startup-ws1.sh   # Workspace 1 terminal startup layout script (zsh)
│   ├── swaync/              # SwayNotificationCenter config & Catppuccin Mocha CSS
│   │   ├── config.json
│   │   └── style.css
│   └── waybar/              # (Optional) Waybar status bar config & Catppuccin CSS
│       ├── config.jsonc
│       └── style.css
├── .zshrc                   # Zsh configuration (Starship prompt, Vi mode, OMZ, fzf, zoxide, aliases)
├── .bashrc                  # (Optional) Bash configuration
└── README.md                # Installation and usage guide
```
