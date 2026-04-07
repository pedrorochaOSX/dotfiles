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

ensure_extension_enabled() {
  ext_uuid="$1"
  enabled_extensions=$(dconf read /org/gnome/shell/enabled-extensions 2>/dev/null || true)
  if printf '%s' "$enabled_extensions" | grep -F "'$ext_uuid'" >/dev/null 2>&1; then
    return 0
  fi

  if command -v gnome-extensions >/dev/null 2>&1; then
    echo "-> Enabling $ext_uuid"
    gnome-extensions enable "$ext_uuid" || true
  fi
}

assert_dconf_value() {
  key_path="$1"
  expected="$2"
  actual=$(dconf read "$key_path" 2>/dev/null || true)

  if [ "$actual" = "$expected" ]; then
    echo "-> OK: $key_path = $expected"
    return 0
  fi

  echo "Warning: $key_path expected $expected but found $actual"
  return 1
}

verify_extension_config() {
  failures=0

  assert_dconf_value "/org/gnome/shell/extensions/dash-to-dock/dock-position" "'BOTTOM'" || failures=1
  assert_dconf_value "/org/gnome/shell/extensions/dash-to-panel/panel-position" "'TOP'" || failures=1
  assert_dconf_value "/org/gnome/shell/extensions/dash-to-panel/group-apps" "false" || failures=1
  assert_dconf_value "/org/gnome/shell/extensions/just-perfection/panel" "true" || failures=1

  if [ "$failures" -ne 0 ]; then
    echo "Warning: Some extension settings did not match expected values"
    return 1
  fi

  echo "-> Extension settings checks passed"
}

reset_extension_dconf_paths() {
  dconf reset -f /org/gnome/shell/extensions/dash-to-dock/ || true
  dconf reset -f /org/gnome/shell/extensions/dash-to-panel/ || true
  dconf reset -f /org/gnome/shell/extensions/just-perfection/ || true
}

require_command curl
require_command unzip
require_command dconf
require_command gnome-shell

detect_shell_versions

install_latest_ego_extension "dash-to-dock@micxgx.gmail.com"
install_latest_ego_extension "dash-to-panel@jderose9.github.com"
install_latest_ego_extension "just-perfection-desktop@just-perfection"

echo "  GNOME Extensions Installation Completed"

# Load GNOME settings from dconf backup
echo "-> Loading GNOME settings from dconf backup..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GNOME_BACKUP="$SCRIPT_DIR/gnome_backup.conf"

reset_extension_dconf_paths

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

ensure_extension_enabled "dash-to-dock@micxgx.gmail.com"
ensure_extension_enabled "dash-to-panel@jderose9.github.com"
ensure_extension_enabled "just-perfection-desktop@just-perfection"

verify_extension_config

echo "  GNOME Configuration Complete!"
