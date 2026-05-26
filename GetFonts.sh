#!/usr/bin/env sh

set -e

# Fetch latest JetBrainsMono Nerd Font version from GitHub API
echo "Fetching latest JetBrainsMono Nerd Font version..."
LATEST_VERSION=$(curl -fsSL "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" \
  | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

if [ -z "$LATEST_VERSION" ]; then
  echo "Warning: Could not fetch latest version, falling back to v3.4.0"
  LATEST_VERSION="v3.4.0"
fi

echo "Installing JetBrainsMono Nerd Font $LATEST_VERSION..."

DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${LATEST_VERSION}/JetBrainsMono.zip"
DOWNLOAD_PATH="$HOME/Downloads/JetBrainsMono.zip"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"

mkdir -p "$FONT_DIR"
mkdir -p "$HOME/Downloads"

echo "Downloading JetBrainsMono.zip..."
curl -fsSL -o "$DOWNLOAD_PATH" "$DOWNLOAD_URL"

echo "Extracting to $FONT_DIR..."
unzip -o "$DOWNLOAD_PATH" -d "$FONT_DIR"

rm "$DOWNLOAD_PATH"

echo "Refreshing font cache..."
fc-cache -f "$FONT_DIR"

echo "Font installation complete ($LATEST_VERSION)."