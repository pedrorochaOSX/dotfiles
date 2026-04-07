#!/usr/bin/env sh

set -e

require_command() {
  cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: Required command not found: $cmd"
    exit 1
  fi
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGES_FILE="$SCRIPT_DIR/packages.txt"

if [ ! -f "$PACKAGES_FILE" ]; then
  echo "Error: packages file not found: $PACKAGES_FILE"
  exit 1
fi

require_command dnf
require_command rpm

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  require_command sudo
  SUDO="sudo"
fi

clean_list_file=$(mktemp)
trap 'rm -f "$clean_list_file"' EXIT

# Keep only non-empty, non-comment lines.
grep -E '^[[:space:]]*[^#[:space:]]' "$PACKAGES_FILE" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' > "$clean_list_file"

already_installed=0
installed_now=0
failed_count=0
failed_pkgs=""

echo "-> Installing packages from $PACKAGES_FILE using dnf"

while IFS= read -r pkg; do
  [ -z "$pkg" ] && continue

  if rpm -q "$pkg" >/dev/null 2>&1; then
    echo "-> Already installed: $pkg"
    already_installed=$((already_installed + 1))
    continue
  fi

  echo "-> Installing: $pkg"
  if $SUDO dnf -y install "$pkg"; then
    installed_now=$((installed_now + 1))
  else
    echo "Warning: Failed to install package: $pkg"
    failed_count=$((failed_count + 1))
    failed_pkgs="$failed_pkgs $pkg"
  fi
done < "$clean_list_file"

echo ""
echo "Install summary:"
echo "- Already installed: $already_installed"
echo "- Installed now: $installed_now"
echo "- Failed: $failed_count"

if [ "$failed_count" -gt 0 ]; then
  echo ""
  echo "Packages that failed to install:"
  for pkg in $failed_pkgs; do
    echo "- $pkg"
  done
  echo ""
  echo "Tip: Some names in packages.txt are Arch package names and may differ on Fedora."
  exit 1
fi

echo "All packages in packages.txt were processed successfully."
