# pedrorochaosx dotfiles

## Quick Setup (Interactive)
Run all configuration scripts interactively:
```bash
curl -sL "https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/RunAll.sh" | bash
```

## Quick Setup (Non-interactive)
Run all configuration scripts without prompts:
```bash
curl -sL "https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/RunAll.sh" | bash -s -- --yes
```

## Individual Scripts
You can also run individual scripts if needed:

Install packages:
```bash
curl -sL "https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/InstallPackages.sh" | bash
```

Update git configuration:
```bash
curl -sL "https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/UpdateGitConfig.sh" | bash
```

Configure zsh:
```bash
curl -sL "https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/ZshConfig.sh" | bash
```

Configure Alacritty terminal:
```bash
curl -sL "https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/AlacrittyConfig.sh" | bash
```

Configure Neovim:
```bash
curl -sL "https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/NeovimConfig.sh" | bash
```

Update GNOME settings:
```bash
curl -sL "https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/GnomeConfig.sh" | bash
```
