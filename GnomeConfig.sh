#!/usr/bin/env sh

set -e

install_extension_from_local_zip() {
  zip_file="$1"
  ext_name="$2"    # extension uuid, e.g. dash-to-dock@micxgx.gmail.com

  if [ ! -f "$zip_file" ]; then
    echo "Error: Zip file not found: $zip_file"
    return 1
  fi

  echo "-> Installing extension $ext_name from local zip: $zip_file"

  tmpdir=$(mktemp -d)
  
  echo "-> Unpacking to temporary directory..."
  unzip -q -o "$zip_file" -d "$tmpdir/unpack" || true

  # Find the directory containing metadata.json or extension.js
  found_dir=$(find "$tmpdir/unpack" -maxdepth 3 -type f -name metadata.json -printf '%h\n' | head -n1 || true)
  if [ -z "$found_dir" ]; then
    found_dir=$(find "$tmpdir/unpack" -maxdepth 3 -type f \( -name extension.js -o -name schemas -o -name schemas.gschema.xml \) -printf '%h\n' | head -n1 || true)
  fi
  if [ -z "$found_dir" ]; then
    found_dir="$tmpdir/unpack"
  fi

  target_dir="$HOME/.local/share/gnome-shell/extensions/$ext_name"

  echo "-> Creating target extension directory: $target_dir"
  rm -rf "$target_dir" || true
  mkdir -p "$target_dir"

  echo "-> Copying extension files into $target_dir"
  cp -a "$found_dir/." "$target_dir/" || true

  rm -rf "$tmpdir"

  echo "-> Installed $ext_name to $target_dir"
  echo "-> Extension will be available after restarting GNOME Shell (Alt+F2, type 'r', press Enter)"
}

download_latest_asset() {
  repo="$1"
  pattern="$2"

  echo "-> Querying latest release for $repo..." >&2
  download_url=$(curl -s "https://api.github.com/repos/$repo/releases/latest" \
    | sed -n 's/.*"browser_download_url": *"\([^"\\]*\)".*/\1/p' \
    | grep -E "$pattern" \
    | head -n1)

  if [ -z "$download_url" ]; then
    echo "Could not find a matching asset for $repo (pattern: $pattern)" >&2
    return 1
  fi

  echo "$download_url"
}

install_extension_from_github() {
  repo="$1"
  pattern="$2"
  ext_name="$3"    # directory / extension uuid, e.g. dash-to-dock@micxgx.gmail.com

  echo "-> Installing extension $ext_name from $repo (pattern: $pattern)"

  download_url=$(download_latest_asset "$repo" "$pattern") || return 1

  tmpdir=$(mktemp -d)
  asset_zip="$tmpdir/asset.zip"

  echo "-> Downloading asset..."
  curl -L -s "$download_url" -o "$asset_zip"

  echo "-> Unpacking to temporary directory..."
  unzip -q -o "$asset_zip" -d "$tmpdir/unpack" || true

  found_dir=$(find "$tmpdir/unpack" -maxdepth 3 -type f -name metadata.json -printf '%h\n' | head -n1 || true)
  if [ -z "$found_dir" ]; then
    found_dir=$(find "$tmpdir/unpack" -maxdepth 3 -type f \( -name extension.js -o -name schemas -o -name schemas.gschema.xml \) -printf '%h\n' | head -n1 || true)
  fi
  if [ -z "$found_dir" ]; then
    found_dir="$tmpdir/unpack"
  fi

  target_dir="$HOME/.local/share/gnome-shell/extensions/$ext_name"

  echo "-> Creating target extension directory: $target_dir"
  rm -rf "$target_dir" || true
  mkdir -p "$target_dir"

  echo "-> Copying extension files into $target_dir"
  cp -a "$found_dir/." "$target_dir/" || true

  rm -rf "$tmpdir"

  echo "-> Installed $ext_name to $target_dir"
  echo "-> Extension will be available after restarting GNOME Shell (Alt+F2, type 'r', press Enter)"
}

# Install Dash to Dock from local zip if it exists in Downloads
if [ -f "$HOME/Downloads/dash-to-dock@micxgx.gmail.com.zip" ]; then
  install_extension_from_local_zip "$HOME/Downloads/dash-to-dock@micxgx.gmail.com.zip" "dash-to-dock@micxgx.gmail.com" || \
    echo "Warning: Local Dash-to-Dock installation failed."
else
  # Fallback to GitHub download if local zip not found
  install_extension_from_github "micheleg/dash-to-dock" "dash-to-dock.*\\.zip" "dash-to-dock@micxgx.gmail.com" || \
    echo "Warning: Dash-to-Dock installation failed or asset not found."
fi

install_extension_from_github "fflewddur/tophat" "tophat.*\\.zip" "tophat@fflewddur.github.io" || \
  echo "Warning: TopHat installation failed or asset not found."

install_extension_from_github "home-sweet-gnome/dash-to-panel" "dash-to-panel.*\\.zip" "dash-to-panel@jderose9.github.com" || \
  echo "Warning: Dash-to-Panel installation failed or asset not found."

echo "  GNOME Extensions Installation Completed"

# Load GNOME settings from dconf backup
echo "-> Loading GNOME settings from dconf backup..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GNOME_BACKUP="$SCRIPT_DIR/gnome_backup.conf"

if [ -f "$GNOME_BACKUP" ]; then
  dconf load / < "$GNOME_BACKUP"
  echo "-> GNOME settings loaded successfully"
else
  # Try downloading from GitHub if not local
  GITHUB_BACKUP_URL="https://raw.githubusercontent.com/pedrorochaOSX/dotfiles/refs/heads/main/gnome_backup.conf"
  echo "-> Local backup not found, downloading from GitHub..."
  if curl -fsSL "$GITHUB_BACKUP_URL" | dconf load /; then
    echo "-> GNOME settings loaded successfully from GitHub"
  else
    echo "Error: Could not load GNOME settings from local file or GitHub"
    exit 1
  fi
fi

echo "  GNOME Configuration Complete!"
