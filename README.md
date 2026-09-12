# Sway Dotfiles for Ubuntu 26.04

A clean, modern, and high-performance Wayland desktop environment setup powered by **Sway**, **Quickshell**, **Ghostty**, and **Bash** with **Starship** prompt (faithfully replicating the Powerlevel10k Lean theme, Catppuccin Mocha theme & Nerd Fonts).

---

## 📸 Desktop Stack Overview

| Component | Software | Description |
| :--- | :--- | :--- |
| **Window Manager** | [Sway](https://swaywm.org/) | i3-compatible Wayland tiling compositor |
| **Status Bar** | [Quickshell](https://quickshell.outfoxxed.me/) | Flexible QtQuick/QML-based desktop shell & status bar (Catppuccin Mocha theme) |
| **Terminal** | [Ghostty](https://ghostty.org/) | Fast, feature-rich GPU-accelerated terminal |
| **Editor** | [Neovim](https://neovim.io/) | Modern modal text editor configured with LazyVim & Catppuccin Mocha theme |
| **App Launcher** | [Rofi](https://github.com/davatorium/rofi) | Application menu & window switcher |
| **Shell & Prompt** | [Bash](https://www.gnu.org/software/bash/) + [Starship](https://starship.rs/) | Powerlevel10k Lean replica prompt, Vi mode, fzf (Catppuccin Mocha), zoxide, eza, git completions |
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

### Step 5: Install & Configure Bash with Starship and CLI Tools

1. **Install Starship Prompt**:
   Starship is a fast, zero-config, highly customizable prompt configured to faithfully emulate your Powerlevel10k Lean theme:
   ```bash
   curl -sS https://starship.rs/install.sh | sh -s -- -y
   ```

2. **Install Shell Utilities (`fzf`, `ripgrep`, `fd-find`, `bat`, `eza`, `zoxide`, `bash-completion`)**:
   These tools provide fuzzy searching, modern directory jumping, syntax-highlighted previews, and smart completions:
   ```bash
   # Base shell completions, fuzzy finder & CLI tools
   sudo apt install -y bash-completion fzf ripgrep fd-find bat

   # Install eza (modern ls replacement used in .bashrc aliases)
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

3. **Install NVM (Node Version Manager)**:
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
   [ -f ~/.bashrc ] && mv ~/.bashrc ~/.bashrc.backup.$(date +%s)

   # Link configurations
   ln -sfn ~/sway-dotfiles/.config/sway ~/.config/sway
   ln -sfn ~/sway-dotfiles/.config/quickshell ~/.config/quickshell
   ln -sfn ~/sway-dotfiles/.config/swaync ~/.config/swaync
   ln -sfn ~/sway-dotfiles/.config/ghostty ~/.config/ghostty
   ln -sfn ~/sway-dotfiles/.config/rofi ~/.config/rofi
   ln -sfn ~/sway-dotfiles/.config/nvim ~/.config/nvim
   ln -sfn ~/sway-dotfiles/.config/starship ~/.config/starship
   ln -sfn ~/sway-dotfiles/.config/fzf ~/.config/fzf
   ln -sf ~/sway-dotfiles/.bashrc ~/.bashrc
   ```

---

### Step 7: Launching Sway

1. Log out of your current desktop session.
2. At the display manager (GDM/SDDM/Greetd) login screen, select **Sway** as the session type, or launch directly from TTY by running:
   ```bash
   sway
   ```
3. Ghostty will launch Bash with the custom Starship prompt preloaded from `~/.config/starship/starship.toml`.

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

### 🔄 Reloading Configurations
- **Reload Sway:** Press `Super + Shift + c` (or run `swaymsg reload`).
- **Restart Quickshell:** Run `pkill quickshell; quickshell &` (or detached with `quickshell -d`).
- **Reload SwayNC:** Run `swaync-client -R && swaync-client -rs`.
- **Reload Bash:** Run `source ~/.bashrc`.

---

## 📁 Repository Structure

```text
sway-dotfiles/
├── .config/
│   ├── fzf/                 # Production-grade FZF bash configuration (Catppuccin Mocha)
│   │   └── fzf.bash         # Previews, keybindings, Vi-mode sync, completion & workflows
│   ├── ghostty/             # Ghostty terminal config & Catppuccin themes
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
│   │   └── config.d/        # Modular configs (audio, brightness, bar, notifications, etc.)
│   ├── swaync/              # SwayNotificationCenter config & Catppuccin Mocha CSS
│   │   ├── config.json
│   │   └── style.css
│   └── waybar/              # (Optional) Waybar status bar config & Catppuccin CSS
│       ├── config.jsonc
│       └── style.css
├── .bashrc                  # Bash configuration (Starship, Vi mode, completions, aliases)
├── .zshrc                   # (Optional) Zsh configuration
└── README.md                # Installation and usage guide
```
