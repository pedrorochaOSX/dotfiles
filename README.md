# dotfiles

Arch Linux + GNOME configuration dotfiles

## Quick Setup

Run all configuration scripts from GitHub (interactive):
```bash
bash <(curl -sL "https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/RunAll.sh")
```

Run non-interactive:
```bash
bash <(curl -sL "https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/RunAll.sh") --yes
```

## What's Included

- **Packages**: Install system packages from `packages.txt` via `pacman`
- **Zsh**: Oh My Zsh + custom theme + aliases
- **Ghostty**: Terminal configuration
- **Alacritty**: Terminal configuration
- **Neovim**: LazyVim setup with plugins
- **Zellij**: Terminal multiplexer configuration
- **Fonts**: JetBrainsMono Nerd Font (latest release)
- **GNOME Extensions**: Download/install shell-compatible releases (dash-to-dock, dash-to-panel, just-perfection)
- **GNOME Config**: Apply desktop settings from `gnome_backup.conf`
- **Git**: GitHub authentication setup

## Local Installation

Clone and run locally:
```bash
git clone https://github.com/pedrorochaOSX/dotfiles.git
cd dotfiles
./RunAllLocal.sh
```

Local non-interactive:
```bash
./RunAllLocal.sh --yes
```

## GNOME Extensions

`GnomeExtensions.sh` downloads the latest shell-compatible zip from extensions.gnome.org and installs into `~/.local/share/gnome-shell/extensions/<uuid>`.

`GnomeConfig.sh` resets extension-specific dconf paths, applies `gnome_backup.conf`, then verifies key settings.
