# dotfiles

Arch Linux + GNOME configuration dotfiles

## Quick Setup

Run all configuration scripts:
```bash
bash <(curl -sL "https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/RunAll.sh")
```

Or non-interactive:
```bash
bash <(curl -sL "https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/RunAll.sh") --yes
```

## What's Included

- **Packages**: Install system packages from `packages.txt`
- **Zsh**: Oh My Zsh + custom theme + aliases
- **Alacritty**: Terminal configuration
- **Neovim**: LazyVim setup with plugins
- **GNOME**: Desktop settings + extensions (dash-to-panel, tophat)
- **Git**: GitHub authentication setup

## Local Installation

Clone and run locally:
```bash
git clone https://github.com/pedrorochaOSX/dotfiles.git
cd dotfiles
./RunAllLocal.sh
```
