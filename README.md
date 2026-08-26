# Sway Dotfiles for Ubuntu 26.04

A clean, modern, and high-performance Wayland desktop environment setup powered by **Sway**, **Waybar**, **Ghostty**, and **Zsh** (with Catppuccin Mocha theme & Nerd Fonts).

---

## 📸 Desktop Stack Overview

| Component | Software | Description |
| :--- | :--- | :--- |
| **Window Manager** | [Sway](https://swaywm.org/) | i3-compatible Wayland tiling compositor |
| **Status Bar** | [Waybar](https://github.com/Alexays/Waybar) | Highly customizable Wayland bar (Catppuccin Mocha theme) |
| **Terminal** | [Ghostty](https://ghostty.org/) | Fast, feature-rich GPU-accelerated terminal |
| **App Launcher** | [Rofi](https://github.com/davatorium/rofi) | Application menu & window switcher |
| **Shell** | [Zsh](https://www.zsh.org/) + [Oh My Zsh](https://ohmyz.sh/) | Powerlevel10k prompt, autosuggestions, eza aliases |
| **Fonts** | JetBrains Mono & Hack Nerd Font | High-legibility coding fonts with complete icon glyphs |
| **Audio / Media** | PipeWire / WirePlumber | Controlled via `wpctl` and brightness via `brightnessctl` |

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

These dotfiles use **Hack Nerd Font** for Ghostty and **JetBrains Mono Nerd Font** (along with Hack) for Waybar icons and status indicators.

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

### Step 3: Install Sway, Waybar & Desktop Utilities

Install Sway, Waybar, Rofi, audio/brightness controls, and authentication tools:

```bash
sudo apt install -y \
    sway \
    swaylock \
    swayidle \
    swaybg \
    xwayland \
    xdg-desktop-portal-wlr \
    waybar \
    rofi \
    brightnessctl \
    grim \
    slurp \
    pipewire \
    wireplumber \
    pipewire-pulse \
    pulseaudio-utils \
    pavucontrol \
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

### Step 5: Install & Configure Zsh with Oh My Zsh and Plugins

1. **Install Zsh and change default shell**:
   ```bash
   sudo apt install -y zsh
   chsh -s $(which zsh)
   ```

2. **Install Oh My Zsh**:
   ```bash
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
   ```

3. **Install Powerlevel10k Theme**:
   ```bash
   git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
   ```

4. **Install Zsh Plugins**:
   ```bash
   # zsh-autosuggestions
   git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

   # zsh-nvm
   git clone https://github.com/lukechilds/zsh-nvm ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-nvm
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
   [ -d ~/.config/waybar ] && mv ~/.config/waybar ~/.config/waybar.backup.$(date +%s)
   [ -d ~/.config/ghostty ] && mv ~/.config/ghostty ~/.config/ghostty.backup.$(date +%s)
   [ -d ~/.config/rofi ] && mv ~/.config/rofi ~/.config/rofi.backup.$(date +%s)
   [ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.backup.$(date +%s)

   # Link configurations
   ln -sfn ~/sway-dotfiles/.config/sway ~/.config/sway
   ln -sfn ~/sway-dotfiles/.config/waybar ~/.config/waybar
   ln -sfn ~/sway-dotfiles/.config/ghostty ~/.config/ghostty
   ln -sfn ~/sway-dotfiles/.config/rofi ~/.config/rofi
   ln -sf ~/sway-dotfiles/.zshrc ~/.zshrc
   ```

---

### Step 7: Launching Sway

1. Log out of your current desktop session.
2. At the display manager (GDM/SDDM/Greetd) login screen, select **Sway** as the session type, or launch directly from TTY by running:
   ```bash
   sway
   ```
3. On first terminal launch in Zsh, configure Powerlevel10k if prompted (`p10k configure`).

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
| `Print` | Take screenshot with `grim` |
| `XF86AudioRaiseVolume` | Increase volume (+5%) via WirePlumber |
| `XF86AudioLowerVolume` | Decrease volume (-5%) via WirePlumber |
| `XF86AudioMute` | Toggle audio mute via WirePlumber |
| `XF86MonBrightnessUp` | Increase display brightness (+5%) via `brightnessctl` |
| `XF86MonBrightnessDown` | Decrease display brightness (-5%) via `brightnessctl` |

---

## 📁 Repository Structure

```text
sway-dotfiles/
├── .config/
│   ├── ghostty/             # Ghostty terminal config & Catppuccin themes
│   │   ├── config
│   │   └── themes/
│   ├── rofi/                # Rofi application launcher config
│   │   └── config.rasi
│   ├── sway/                # Sway window manager config
│   │   ├── config
│   │   └── config.d/        # Modular configs (audio, brightness, bar, etc.)
│   └── waybar/              # Waybar status bar config & Catppuccin CSS
│       ├── config.jsonc
│       └── style.css
├── .zshrc                   # Zsh configuration (Powerlevel10k, plugins, aliases)
└── README.md                # Installation and usage guide
```
