#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$SCRIPT_DIR/packages.txt"
GITHUB_PACKAGES_URL="https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/packages.txt"

echo "Installing packages..."

# Check if packages.txt exists locally
if [[ -f "$PACKAGES_FILE" ]]; then
  echo "Using local packages.txt"
  sudo pacman -S --needed --noconfirm - < "$PACKAGES_FILE"
else
  echo "Downloading packages.txt from GitHub..."
  curl -sL "$GITHUB_PACKAGES_URL" | sudo pacman -S --needed --noconfirm -
fi

echo "Package installation complete!"