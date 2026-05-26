#!/usr/bin/env sh

set -e

require_command() {
  cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: Required command not found: $cmd"
    exit 1
  fi
}

detect_shell_versions() {
  full_version=$(gnome-shell --version 2>/dev/null | sed -n 's/^GNOME Shell \([0-9][0-9.]*\).*$/\1/p')
  if [ -z "$full_version" ]; then
    echo "Error: Could not detect GNOME Shell version"
    exit 1
  fi

  major_version=$(printf '%s' "$full_version" | cut -d'.' -f1)
  SHELL_VERSION_CANDIDATES="$full_version $major_version"
  echo "-> GNOME Shell version detected: $full_version (candidates: $SHELL_VERSION_CANDIDATES)"
}

download_latest_ego_zip() {
  ext_uuid="$1"
  out_zip="$2"

  for shell_version in $SHELL_VERSION_CANDIDATES; do
    url="https://extensions.gnome.org/download-extension/${ext_uuid}.shell-extension.zip?shell_version=${shell_version}"
    echo "-> Trying latest $ext_uuid for shell version $shell_version"

    if curl -fL -sS "$url" -o "$out_zip"; then
      DOWNLOADED_SHELL_VERSION="$shell_version"
      return 0
    fi
  done

  echo "Error: Could not download $ext_uuid from extensions.gnome.org"
  return 1
}

install_extension_from_zip() {
  zip_file="$1"
  ext_uuid="$2"

  if [ ! -f "$zip_file" ]; then
    echo "Error: Zip file not found: $zip_file"
    return 1
  fi

  tmpdir=$(mktemp -d)

  echo "-> Unpacking $ext_uuid..."
  unzip -q -o "$zip_file" -d "$tmpdir/unpack"

  found_dir=$(find "$tmpdir/unpack" -maxdepth 3 -type f -name metadata.json -printf '%h\n' | head -n1)
  if [ -z "$found_dir" ]; then
    found_dir="$tmpdir/unpack"
  fi

  target_dir="$HOME/.local/share/gnome-shell/extensions/$ext_uuid"

  rm -rf "$target_dir"
  mkdir -p "$target_dir"
  cp -a "$found_dir/." "$target_dir/"

  metadata_file="$target_dir/metadata.json"
  if [ ! -f "$metadata_file" ]; then
    rm -rf "$tmpdir"
    echo "Error: metadata.json not found for $ext_uuid after installation"
    return 1
  fi

  installed_uuid=$(sed -n 's/.*"uuid"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$metadata_file" | head -n1)
  installed_version=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$metadata_file" | head -n1)

  rm -rf "$tmpdir"

  if [ "$installed_uuid" != "$ext_uuid" ]; then
    echo "Error: Installed UUID mismatch. Expected $ext_uuid, got $installed_uuid"
    return 1
  fi

  if [ -n "$installed_version" ]; then
    echo "-> Installed $ext_uuid version $installed_version"
  else
    echo "-> Installed $ext_uuid (version not declared in metadata)"
  fi
}

install_latest_ego_extension() {
  ext_uuid="$1"

  echo "-> Installing latest shell-compatible release for $ext_uuid"
  tmpdir=$(mktemp -d)
  asset_zip="$tmpdir/asset.zip"

  download_latest_ego_zip "$ext_uuid" "$asset_zip"
  install_extension_from_zip "$asset_zip" "$ext_uuid"

  rm -rf "$tmpdir"
  echo "-> $ext_uuid installed using extensions.gnome.org (shell $DOWNLOADED_SHELL_VERSION)"
}

require_command curl
require_command unzip
require_command gnome-shell

detect_shell_versions

install_latest_ego_extension "dash-to-dock@micxgx.gmail.com"
install_latest_ego_extension "dash-to-panel@jderose9.github.com"
install_latest_ego_extension "just-perfection-desktop@just-perfection"

echo "  GNOME Extensions Installation Completed"
