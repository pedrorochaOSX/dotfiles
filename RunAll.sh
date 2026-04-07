#!/usr/bin/env bash

set -euo pipefail

GITHUB_BASE_URL="https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main"

declare -A SCRIPT_DESCRIPTIONS=(
  ["InstallPackages.sh"]="Install packages (pacman)"
  ["InstallPackagesFedora.sh"]="Install packages (Fedora dnf)"
  ["GitHubAuth.sh"]="Login into GitHub"
  ["ZshConfig.sh"]="Configure zsh shell"
  ["GhosttyConfig.sh"]="Install and configure Ghostty terminal"
  ["ZellijConfig.sh"]="Configure Zellij"
  ["NeovimConfig.sh"]="Configure Neovim"
  ["GetFonts.sh"]="Download and install JetBrainsMono Nerd Font"
  ["GnomeConfig.sh"]="Update GNOME settings"
)

SCRIPTS=(
  InstallPackages.sh
  InstallPackagesFedora.sh
  GitHubAuth.sh
  ZshConfig.sh
  GhosttyConfig.sh
  ZellijConfig.sh
  NeovimConfig.sh
  GetFonts.sh
  GnomeConfig.sh
)

NONINTERACTIVE=0
if [[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]]; then
  NONINTERACTIVE=1
fi

declare -a SELECTED_SCRIPTS=()
PACKAGES_FLAVOR="${PACKAGES_FLAVOR:-pacman}" # pacman | fedora | both

ask_script() {
  local script="$1"
  local description="${SCRIPT_DESCRIPTIONS[$script]:-$script}"
  
  echo
  echo "----------------------------------------"
  echo "$description?"
  echo "----------------------------------------"

  while true; do
    printf "[y]es / [n]o / [v]iew / [q]uit: "
    read ans </dev/tty
    
    case "$ans" in
      y|Y|yes|YES|Yes)
        SELECTED_SCRIPTS+=("$script")
        break
        ;;
      n|N|no|NO|No)
        break
        ;;
      v|V|view|VIEW|View)
        echo "---- $script (from GitHub) ----"
        curl -sL "$GITHUB_BASE_URL/$script"
        echo "---- end ----"
        ;;
      q|Q|quit|QUIT|Quit)
        echo "Quitting."
        exit 0
        ;;
      *)
        echo "Please answer y, n, v, or q."
        ;;
    esac
  done
}

run_script() {
  local script="$1"
  echo "Running $script from GitHub..."
  curl -sL "$GITHUB_BASE_URL/$script" | bash
}

if [[ $NONINTERACTIVE -eq 1 ]]; then
  for s in "${SCRIPTS[@]}"; do
    if [[ "$s" == "InstallPackages.sh" && "$PACKAGES_FLAVOR" != "pacman" && "$PACKAGES_FLAVOR" != "both" ]]; then
      echo "Skipping $s because PACKAGES_FLAVOR=$PACKAGES_FLAVOR"
      continue
    fi
    if [[ "$s" == "InstallPackagesFedora.sh" && "$PACKAGES_FLAVOR" != "fedora" && "$PACKAGES_FLAVOR" != "both" ]]; then
      echo "Skipping $s because PACKAGES_FLAVOR=$PACKAGES_FLAVOR"
      continue
    fi
    run_script "$s"
  done
else
  for s in "${SCRIPTS[@]}"; do
    ask_script "$s"
  done
  for s in "${SELECTED_SCRIPTS[@]}"; do
    run_script "$s"
  done
fi

echo
echo "All selected scripts processed."