#!/usr/bin/env sh

set -e

require_command() {
  cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: Required command not found: $cmd"
    exit 1
  fi
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

require_command dconf

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
  require_command curl
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
