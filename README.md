# dotfiles

Arch Linux + Fedora + GNOME configuration dotfiles

## Documentation

- Project context: `docs/CONTEXT.md`

## Quick Setup

Run all configuration scripts from GitHub (interactive):
```bash
bash <(curl -sL "https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/RunAll.sh")
```

Run non-interactive using pacman packages (default):
```bash
bash <(curl -sL "https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/RunAll.sh") --yes
```

Run non-interactive using Fedora dnf packages:
```bash
PACKAGES_FLAVOR=fedora bash <(curl -sL "https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/RunAll.sh") --yes
```

Run non-interactive and attempt both package installers:
```bash
PACKAGES_FLAVOR=both bash <(curl -sL "https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/RunAll.sh") --yes
```

In interactive mode, you now get two separate package choices:
- Install packages (pacman)
- Install packages (Fedora dnf)

## Package Installation

- `InstallPackages.sh`: installs from `packages.txt` using pacman.
- `InstallPackagesFedora.sh`: installs from `packages.txt` using dnf.
- Fedora note: dnf only resolves packages from enabled repositories. If a package is in COPR, enable the COPR repo first.

Example:
```bash
sudo dnf copr enable <owner>/<project>
```

## What's Included

- **Packages**: Install system packages from `packages.txt` (pacman or dnf)
- **Zsh**: Oh My Zsh + custom theme + aliases
- **Ghostty**: Terminal configuration (default in RunAll scripts)
- **Neovim**: LazyVim setup with plugins
- **GNOME Extensions**: Download/install shell-compatible releases (dash-to-dock, dash-to-panel, just-perfection)
- **GNOME Config**: Apply desktop settings from `gnome_backup.conf`
- **Git**: GitHub authentication setup

GNOME extensions behavior (`GnomeExtensions.sh`):
- Downloads latest shell-compatible zip from extensions.gnome.org.
- Installs into `~/.local/share/gnome-shell/extensions/<uuid>`.

GNOME config behavior (`GnomeConfig.sh`):
- Resets extension-specific dconf paths, applies `gnome_backup.conf`, then verifies key settings.

## Local Installation

Clone and run locally:
```bash
git clone https://github.com/pedrorochaOSX/dotfiles.git
cd dotfiles
./RunAllLocal.sh
```

Local non-interactive examples:
```bash
./RunAllLocal.sh --yes
PACKAGES_FLAVOR=fedora ./RunAllLocal.sh --yes
```
