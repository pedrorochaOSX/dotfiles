#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

declare -A SCRIPT_DESCRIPTIONS=(
  ["InstallPackages.sh"]="Install packages (pacman)"
  ["GitHubAuth.sh"]="Login into GitHub"
  ["ZshConfig.sh"]="Configure zsh shell"
  ["GhosttyConfig.sh"]="Install and configure Ghostty terminal"
  ["ZellijConfig.sh"]="Configure Zellij"
  ["NeovimConfig.sh"]="Configure Neovim"
  ["GetFonts.sh"]="Download and install JetBrainsMono Nerd Font"
  ["GnomeExtensions.sh"]="Install GNOME extensions"
  ["GnomeConfig.sh"]="Apply GNOME settings"
)

SCRIPTS=(
  InstallPackages.sh
  GitHubAuth.sh
  ZshConfig.sh
  GhosttyConfig.sh
  ZellijConfig.sh
  NeovimConfig.sh
  GetFonts.sh
  GnomeExtensions.sh
  GnomeConfig.sh
)

NONINTERACTIVE=0
if [[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]]; then
  NONINTERACTIVE=1
fi

declare -a SELECTED_SCRIPTS=()

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
        echo "---- $script (local) ----"
        cat "$SCRIPT_DIR/$script"
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
  local script_path="$SCRIPT_DIR/$script"
  
  if [[ ! -f "$script_path" ]]; then
    echo "Error: $script not found at $script_path"
    return 1
  fi
  
  echo "Running $script locally..."
  bash "$script_path"
}

if [[ $NONINTERACTIVE -eq 1 ]]; then
  for s in "${SCRIPTS[@]}"; do
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
