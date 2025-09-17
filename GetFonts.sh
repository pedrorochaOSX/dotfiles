#!/usr/bin/env sh

LATEST_VERSION="v3.4.0"
DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${LATEST_VERSION}/JetBrainsMono.zip"
DOWNLOAD_PATH="$HOME/Downloads/JetBrainsMono.zip"
FONT_DIR="$HOME/.fonts/JetBrainsMonoNerdFont"

if [ ! -d "$FONT_DIR" ]; then
    mkdir -p "$FONT_DIR"
    echo "Created $FONT_DIR"
fi

echo "Downloading JetBrainsMono.zip..."
wget -O "$DOWNLOAD_PATH" "$DOWNLOAD_URL"

echo "Extracting to $FONT_DIR..."
unzip -o "$DOWNLOAD_PATH" -d "$FONT_DIR"

rm "$DOWNLOAD_PATH"

echo "Font installation complete."