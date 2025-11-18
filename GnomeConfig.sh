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

  # Handle schemas
  if command -v glib-compile-schemas >/dev/null 2>&1; then
    if [ -d "$target_dir/schemas" ]; then
      user_schema_dir="$HOME/.local/share/glib-2.0/schemas"
      mkdir -p "$user_schema_dir"
      echo "-> Found schemas in extension; copying to $user_schema_dir"
      find "$target_dir/schemas" -maxdepth 1 -type f \( -name '*.gschema.xml' -o -name '*.xml' \) -exec cp -a {} "$user_schema_dir/" \; || true
      echo "-> Compiling per-user schemas..."
      glib-compile-schemas "$user_schema_dir" || echo "Warning: glib-compile-schemas failed"
      echo "-> Installed user schemas for $ext_name"
    fi
  else
    echo "Note: 'glib-compile-schemas' not found. Install the package that provides it (e.g. libglib2.0-bin) to compile per-user schemas."
  fi

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

  if command -v glib-compile-schemas >/dev/null 2>&1; then
    if [ -d "$target_dir/schemas" ]; then
      user_schema_dir="$HOME/.local/share/glib-2.0/schemas"
      mkdir -p "$user_schema_dir"
      echo "-> Found schemas in extension; copying to $user_schema_dir"
      find "$target_dir/schemas" -maxdepth 1 -type f \( -name '*.gschema.xml' -o -name '*.xml' \) -exec cp -a {} "$user_schema_dir/" \; || true
      echo "-> Compiling per-user schemas..."
      glib-compile-schemas "$user_schema_dir" || echo "Warning: glib-compile-schemas failed"
      echo "-> Installed user schemas for $ext_name"
    fi
  else
    echo "Note: 'glib-compile-schemas' not found. Install the package that provides it (e.g. libglib2.0-bin) to compile per-user schemas."
  fi

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

echo "  gsettings - Changing org.gnome.desktop.wm.keybindings";
echo "  gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "['<Super>w']"";
gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "['<Super>w']";
echo "  gsettings set org.gnome.desktop.wm.keybindings always-on-top "[]"";
gsettings set org.gnome.desktop.wm.keybindings always-on-top "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings begin-move "[]"";
gsettings set org.gnome.desktop.wm.keybindings begin-move "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings begin-resize "['<Super>r']"";
gsettings set org.gnome.desktop.wm.keybindings begin-resize "['<Super>r']";
echo "  gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']"";
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']";
echo "  gsettings set org.gnome.desktop.wm.keybindings cycle-group "[]"";
gsettings set org.gnome.desktop.wm.keybindings cycle-group "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings cycle-group-backward "[]"";
gsettings set org.gnome.desktop.wm.keybindings cycle-group-backward "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings cycle-panels "[]"";
gsettings set org.gnome.desktop.wm.keybindings cycle-panels "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings cycle-panels-backward "[]"";
gsettings set org.gnome.desktop.wm.keybindings cycle-panels-backward "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings cycle-windows "['<Alt>Escape']"";
gsettings set org.gnome.desktop.wm.keybindings cycle-windows "['<Alt>Escape']";
echo "  gsettings set org.gnome.desktop.wm.keybindings cycle-windows-backward "['<Shift><Alt>Escape']"";
gsettings set org.gnome.desktop.wm.keybindings cycle-windows-backward "['<Shift><Alt>Escape']";
echo "  gsettings set org.gnome.desktop.wm.keybindings lower "[]"";
gsettings set org.gnome.desktop.wm.keybindings lower "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings maximize "[]"";
gsettings set org.gnome.desktop.wm.keybindings maximize "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings maximize-horizontally "[]"";
gsettings set org.gnome.desktop.wm.keybindings maximize-horizontally "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings maximize-vertically "[]"";
gsettings set org.gnome.desktop.wm.keybindings maximize-vertically "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings minimize "[]"";
gsettings set org.gnome.desktop.wm.keybindings minimize "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-center "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-center "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-corner-ne "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-corner-ne "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-corner-nw "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-corner-nw "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-corner-se "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-corner-se "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-corner-sw "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-corner-sw "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-side-e "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-side-e "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-side-n "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-side-n "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-side-s "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-side-s "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-side-w "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-side-w "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-up "['<Shift><Super>Up']"";
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-up "['<Shift><Super>Up']";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-down "['<Shift><Super>Down']"";
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-down "['<Shift><Super>Down']";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-left "['<Shift><Super>Left']"";
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-left "['<Shift><Super>Left']";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-right "['<Shift><Super>Right']"";
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-right "['<Shift><Super>Right']";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-7 "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-7 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-8 "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-8 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-9 "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-9 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-10 "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-10 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-11 "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-11 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-12 "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-12 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-last "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-last "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "['<Shift><Super>s']"";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "['<Shift><Super>s']";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "['<Shift><Super>f']"";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "['<Shift><Super>f']";
echo "  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "[]"";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings panel-main-menu "['<Alt>F1']"";
gsettings set org.gnome.desktop.wm.keybindings panel-main-menu "['<Alt>F1']";
echo "  gsettings set org.gnome.desktop.wm.keybindings panel-run-dialog "[]"";
gsettings set org.gnome.desktop.wm.keybindings panel-run-dialog "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings raise "[]"";
gsettings set org.gnome.desktop.wm.keybindings raise "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings raise-or-lower "[]"";
gsettings set org.gnome.desktop.wm.keybindings raise-or-lower "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings set-spew-mark "[]"";
gsettings set org.gnome.desktop.wm.keybindings set-spew-mark "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']"";
gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']"";
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab']"";
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab']";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-group "['<Alt>Tab']"";
gsettings set org.gnome.desktop.wm.keybindings switch-group "['<Alt>Tab']";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-group-backward "['<Shift><Alt>Tab']"";
gsettings set org.gnome.desktop.wm.keybindings switch-group-backward "['<Shift><Alt>Tab']";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Super>space', 'XF86Keyboard']"";
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Super>space', 'XF86Keyboard']";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Shift><Super>space', '<Shift>XF86Keyboard']"";
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Shift><Super>space', '<Shift>XF86Keyboard']";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-panels "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-panels "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-panels-backward "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-panels-backward "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-9 "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-9 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-10 "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-10 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-11 "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-11 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-12 "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-12 "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-last "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-last "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Super>s']"";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Super>s']";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Super>f']"";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Super>f']";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-windows "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-windows "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "[]"";
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings toggle-above "[]"";
gsettings set org.gnome.desktop.wm.keybindings toggle-above "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>x']"";
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>x']";
echo "  gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Super>e', '<Super>Up', '<Super>KP_5']"";
gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Super>e', '<Super>Up', '<Super>KP_5']";
echo "  gsettings set org.gnome.desktop.wm.keybindings toggle-on-all-workspaces "[]"";
gsettings set org.gnome.desktop.wm.keybindings toggle-on-all-workspaces "[]";
echo "  gsettings set org.gnome.desktop.wm.keybindings unmaximize "[]"";
gsettings set org.gnome.desktop.wm.keybindings unmaximize "[]";

echo "  gsettings - Changing org.gnome.mutter.keybindings";
echo "  gsettings set org.gnome.mutter.keybindings cancel-input-capture "['<Super><Shift>Escape']"";
gsettings set org.gnome.mutter.keybindings cancel-input-capture "['<Super><Shift>Escape']";
echo "  gsettings set org.gnome.mutter.keybindings rotate-monitor "['XF86RotateWindows']"";
gsettings set org.gnome.mutter.keybindings rotate-monitor "['XF86RotateWindows']";
echo "  gsettings set org.gnome.mutter.keybindings switch-monitor "['<Super>p', 'XF86Display']"";
gsettings set org.gnome.mutter.keybindings switch-monitor "['<Super>p', 'XF86Display']";
echo "  gsettings set org.gnome.mutter.keybindings toggle-tiled-left "['<Super>Left']"";
gsettings set org.gnome.mutter.keybindings toggle-tiled-left "['<Super>Left']";
echo "  gsettings set org.gnome.mutter.keybindings toggle-tiled-right "['<Super>Right']"";
gsettings set org.gnome.mutter.keybindings toggle-tiled-right "['<Super>Right']";

echo "  gsettings - Changing org.gnome.shell.keybindings";
echo "  gsettings set org.gnome.shell.keybindings focus-active-notification "[]"";
gsettings set org.gnome.shell.keybindings focus-active-notification "[]";
echo "  gsettings set org.gnome.shell.keybindings open-new-window-application-1 "[]"";
gsettings set org.gnome.shell.keybindings open-new-window-application-1 "[]";
echo "  gsettings set org.gnome.shell.keybindings open-new-window-application-2 "[]"";
gsettings set org.gnome.shell.keybindings open-new-window-application-2 "[]";
echo "  gsettings set org.gnome.shell.keybindings open-new-window-application-3 "[]"";
gsettings set org.gnome.shell.keybindings open-new-window-application-3 "[]";
echo "  gsettings set org.gnome.shell.keybindings open-new-window-application-4 "[]"";
gsettings set org.gnome.shell.keybindings open-new-window-application-4 "[]";
echo "  gsettings set org.gnome.shell.keybindings open-new-window-application-5 "[]"";
gsettings set org.gnome.shell.keybindings open-new-window-application-5 "[]";
echo "  gsettings set org.gnome.shell.keybindings open-new-window-application-6 "[]"";
gsettings set org.gnome.shell.keybindings open-new-window-application-6 "[]";
echo "  gsettings set org.gnome.shell.keybindings open-new-window-application-7 "[]"";
gsettings set org.gnome.shell.keybindings open-new-window-application-7 "[]";
echo "  gsettings set org.gnome.shell.keybindings open-new-window-application-8 "[]"";
gsettings set org.gnome.shell.keybindings open-new-window-application-8 "[]";
echo "  gsettings set org.gnome.shell.keybindings open-new-window-application-9 "[]"";
gsettings set org.gnome.shell.keybindings open-new-window-application-9 "[]";
echo "  gsettings set org.gnome.shell.keybindings screenshot "[]"";
gsettings set org.gnome.shell.keybindings screenshot "[]";
echo "  gsettings set org.gnome.shell.keybindings screenshot-window "[]"";
gsettings set org.gnome.shell.keybindings screenshot-window "[]";
echo "  gsettings set org.gnome.shell.keybindings shift-overview-down "[]"";
gsettings set org.gnome.shell.keybindings shift-overview-down "[]";
echo "  gsettings set org.gnome.shell.keybindings shift-overview-up "[]"";
gsettings set org.gnome.shell.keybindings shift-overview-up "[]";
echo "  gsettings set org.gnome.shell.keybindings show-screen-recording-ui "[]"";
gsettings set org.gnome.shell.keybindings show-screen-recording-ui "[]";
echo "  gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Super>a']"";
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Super>a']";
echo "  gsettings set org.gnome.shell.keybindings switch-to-application-1 "[]"";
gsettings set org.gnome.shell.keybindings switch-to-application-1 "[]";
echo "  gsettings set org.gnome.shell.keybindings switch-to-application-2 "[]"";
gsettings set org.gnome.shell.keybindings switch-to-application-2 "[]";
echo "  gsettings set org.gnome.shell.keybindings switch-to-application-3 "[]"";
gsettings set org.gnome.shell.keybindings switch-to-application-3 "[]";
echo "  gsettings set org.gnome.shell.keybindings switch-to-application-4 "[]"";
gsettings set org.gnome.shell.keybindings switch-to-application-4 "[]";
echo "  gsettings set org.gnome.shell.keybindings switch-to-application-5 "[]"";
gsettings set org.gnome.shell.keybindings switch-to-application-5 "[]";
echo "  gsettings set org.gnome.shell.keybindings switch-to-application-6 "[]"";
gsettings set org.gnome.shell.keybindings switch-to-application-6 "[]";
echo "  gsettings set org.gnome.shell.keybindings switch-to-application-7 "[]"";
gsettings set org.gnome.shell.keybindings switch-to-application-7 "[]";
echo "  gsettings set org.gnome.shell.keybindings switch-to-application-8 "[]"";
gsettings set org.gnome.shell.keybindings switch-to-application-8 "[]";
echo "  gsettings set org.gnome.shell.keybindings switch-to-application-9 "[]"";
gsettings set org.gnome.shell.keybindings switch-to-application-9 "[]";
echo "  gsettings set org.gnome.shell.keybindings toggle-application-view "[]"";
gsettings set org.gnome.shell.keybindings toggle-application-view "[]";
echo "  gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>v']"";
gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>v']";
echo "  gsettings set org.gnome.shell.keybindings toggle-overview "[]"";
gsettings set org.gnome.shell.keybindings toggle-overview "[]";
echo "  gsettings set org.gnome.shell.keybindings toggle-quick-settings "['<Super>c']"";
gsettings set org.gnome.shell.keybindings toggle-quick-settings "['<Super>c']";

echo "  gsettings - Changing org.gnome.settings-daemon.plugins.media-keys";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys battery-status "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys battery-status "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys battery-status-static "['XF86Battery']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys battery-status-static "['XF86Battery']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys calculator "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys calculator "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys calculator-static "['XF86Calculator']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys calculator-static "['XF86Calculator']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys control-center "['<Super>i']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys control-center "['<Super>i']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys control-center-static "['XF86Tools']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys control-center-static "['XF86Tools']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys decrease-text-size "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys decrease-text-size "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys eject "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys eject "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys eject-static "['XF86Eject']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys eject-static "['XF86Eject']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys email "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys email "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys email-static "['XF86Mail']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys email-static "['XF86Mail']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys help "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys help "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys hibernate "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys hibernate "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys hibernate-static "['XF86Suspend', 'XF86Hibernate']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys hibernate-static "['XF86Suspend', 'XF86Hibernate']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys home "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys home "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys home-static "['XF86Explorer']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys home-static "['XF86Explorer']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys increase-text-size "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys increase-text-size "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-down "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-down "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-down-static "['XF86KbdBrightnessDown']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-down-static "['XF86KbdBrightnessDown']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-toggle "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-toggle "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-toggle-static "['XF86KbdLightOnOff']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-toggle-static "['XF86KbdLightOnOff']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-up "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-up "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-up-static "['XF86KbdBrightnessUp']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-up-static "['XF86KbdBrightnessUp']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys logout "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys logout "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys magnifier "['<Super>1']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys magnifier "['<Super>1']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys magnifier-zoom-in "['<Super>3']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys magnifier-zoom-in "['<Super>3']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys magnifier-zoom-out "['<Super>2']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys magnifier-zoom-out "['<Super>2']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys media "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys media "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys media-static "['XF86AudioMedia']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys media-static "['XF86AudioMedia']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys mic-mute "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys mic-mute "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys mic-mute-static "['XF86AudioMicMute']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys mic-mute-static "['XF86AudioMicMute']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys next "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys next "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys next-static "['XF86AudioNext', '<Ctrl>XF86AudioNext']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys next-static "['XF86AudioNext', '<Ctrl>XF86AudioNext']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys on-screen-keyboard "['<Ctrl><Super>k']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys on-screen-keyboard "['<Ctrl><Super>k']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys pause "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys pause "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys pause-static "['XF86AudioPause']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys pause-static "['XF86AudioPause']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys play "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys play "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys play-static "['XF86AudioPlay', '<Ctrl>XF86AudioPlay']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys play-static "['XF86AudioPlay', '<Ctrl>XF86AudioPlay']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys playback-forward "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys playback-forward "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys playback-forward-static "['XF86AudioForward']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys playback-forward-static "['XF86AudioForward']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys playback-random "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys playback-random "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys playback-random-static "['XF86AudioRandomPlay']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys playback-random-static "['XF86AudioRandomPlay']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys playback-repeat "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys playback-repeat "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys playback-repeat-static "['XF86AudioRepeat']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys playback-repeat-static "['XF86AudioRepeat']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys playback-rewind "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys playback-rewind "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys playback-rewind-static "['XF86AudioRewind']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys playback-rewind-static "['XF86AudioRewind']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys power "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys power "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys power-static "['XF86PowerOff']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys power-static "['XF86PowerOff']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys previous "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys previous "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys previous-static "['XF86AudioPrev', '<Ctrl>XF86AudioPrev']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys previous-static "['XF86AudioPrev', '<Ctrl>XF86AudioPrev']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys rfkill "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys rfkill "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys rfkill-bluetooth "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys rfkill-bluetooth "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys rfkill-bluetooth-static "['XF86Bluetooth']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys rfkill-bluetooth-static "['XF86Bluetooth']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys rfkill-static "['XF86WLAN', 'XF86UWB', 'XF86RFKill']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys rfkill-static "['XF86WLAN', 'XF86UWB', 'XF86RFKill']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys rotate-video-lock "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys rotate-video-lock "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys rotate-video-lock-static "['<Super>o', 'XF86RotationLockToggle']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys rotate-video-lock-static "['<Super>o', 'XF86RotationLockToggle']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys screenreader "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys screenreader "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>l']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>l']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver-static "['XF86ScreenSaver']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver-static "['XF86ScreenSaver']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys search "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys search "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys search-static "['XF86Search']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys search-static "['XF86Search']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys stop "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys stop "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys stop-static "['XF86AudioStop']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys stop-static "['XF86AudioStop']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys suspend "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys suspend "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys suspend-static "['XF86Sleep']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys suspend-static "['XF86Sleep']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys toggle-contrast "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys toggle-contrast "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-off "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-off "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-off-static "['XF86TouchpadOff']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-off-static "['XF86TouchpadOff']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-on "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-on "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-on-static "['XF86TouchpadOn']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-on-static "['XF86TouchpadOn']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-toggle "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-toggle "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-toggle-static "['XF86TouchpadToggle', '<Ctrl><Super>XF86TouchpadToggle']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-toggle-static "['XF86TouchpadToggle', '<Ctrl><Super>XF86TouchpadToggle']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down-precise "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down-precise "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down-precise-static "['<Shift>XF86AudioLowerVolume', '<Ctrl><Shift>XF86AudioLowerVolume']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down-precise-static "['<Shift>XF86AudioLowerVolume', '<Ctrl><Shift>XF86AudioLowerVolume']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down-quiet "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down-quiet "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down-quiet-static "['XF86AudioLowerVolume']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down-quiet-static "['XF86AudioLowerVolume']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down-static "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down-static "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-mute "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-mute "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-mute-quiet "['XF86AudioMute']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-mute-quiet "['XF86AudioMute']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-mute-quiet-static "['<Alt>XF86AudioMute']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-mute-quiet-static "['<Alt>XF86AudioMute']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-mute-static "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-mute-static "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-step 6";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-step 6;
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up-precise "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up-precise "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up-precise-static "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up-precise-static "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up-quiet "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up-quiet "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up-quiet-static "['XF86AudioRaiseVolume']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up-quiet-static "['XF86AudioRaiseVolume']";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up-static "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up-static "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys www "[]"";
gsettings set org.gnome.settings-daemon.plugins.media-keys www "[]";
echo "  gsettings set org.gnome.settings-daemon.plugins.media-keys www-static "['XF86WWW']"";
gsettings set org.gnome.settings-daemon.plugins.media-keys www-static "['XF86WWW']";

echo "  gsettings - Changing org.gnome.shell.extensions.dash-to-dock";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock activate-single-window true";
gsettings set org.gnome.shell.extensions.dash-to-dock activate-single-window true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock always-center-icons false";
gsettings set org.gnome.shell.extensions.dash-to-dock always-center-icons false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock animation-time 0.1801";
gsettings set org.gnome.shell.extensions.dash-to-dock animation-time 0.1801;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-1 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-1 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-2 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-2 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-3 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-3 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-4 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-4 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-5 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-5 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-6 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-6 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-7 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-7 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-8 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-8 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-9 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-9 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-10 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-10 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-1 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-1 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-2 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-2 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-3 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-3 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-4 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-4 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-5 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-5 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-6 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-6 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-7 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-7 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-8 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-8 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-9 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-9 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-10 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-10 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-1 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-1 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-2 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-2 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-3 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-3 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-4 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-4 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-5 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-5 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-6 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-6 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-7 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-7 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-8 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-8 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-9 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-9 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-10 "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-10 "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock application-counter-overrides-notifications true";
gsettings set org.gnome.shell.extensions.dash-to-dock application-counter-overrides-notifications true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock apply-custom-theme false";
gsettings set org.gnome.shell.extensions.dash-to-dock apply-custom-theme false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock apply-glossy-effect false";
gsettings set org.gnome.shell.extensions.dash-to-dock apply-glossy-effect false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock autohide true";
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock autohide-in-fullscreen false";
gsettings set org.gnome.shell.extensions.dash-to-dock autohide-in-fullscreen false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock background-color '#202020'";
gsettings set org.gnome.shell.extensions.dash-to-dock background-color '#202020';
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.80000000000000004";
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.80000000000000004;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock bolt-support true";
gsettings set org.gnome.shell.extensions.dash-to-dock bolt-support true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'focus-or-appspread'";
gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'focus-or-appspread';
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock custom-background-color true";
gsettings set org.gnome.shell.extensions.dash-to-dock custom-background-color true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-customize-running-dots false";
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-customize-running-dots false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-running-dots-border-color '#ffffff'";
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-running-dots-border-color '#ffffff';
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-running-dots-border-width 0";
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-running-dots-border-width 0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-running-dots-color '#ffffff'";
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-running-dots-color '#ffffff';
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink false";
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock customize-alphas false";
gsettings set org.gnome.shell.extensions.dash-to-dock customize-alphas false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock dance-urgent-applications true";
gsettings set org.gnome.shell.extensions.dash-to-dock dance-urgent-applications true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 40";
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 40;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock default-windows-preview-to-open false";
gsettings set org.gnome.shell.extensions.dash-to-dock default-windows-preview-to-open false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock disable-overview-on-startup true";
gsettings set org.gnome.shell.extensions.dash-to-dock disable-overview-on-startup true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false";
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'";
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM';
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false";
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock force-straight-corner false";
gsettings set org.gnome.shell.extensions.dash-to-dock force-straight-corner false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock height-fraction 0.98999999999999999";
gsettings set org.gnome.shell.extensions.dash-to-dock height-fraction 0.98999999999999999;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock hide-delay 0.00000000000000001";
gsettings set org.gnome.shell.extensions.dash-to-dock hide-delay 0.00000000000000001;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock hide-tooltip false";
gsettings set org.gnome.shell.extensions.dash-to-dock hide-tooltip false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys true";
gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock hotkeys-overlay false";
gsettings set org.gnome.shell.extensions.dash-to-dock hotkeys-overlay false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock hotkeys-show-dock true";
gsettings set org.gnome.shell.extensions.dash-to-dock hotkeys-show-dock true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock icon-size-fixed false";
gsettings set org.gnome.shell.extensions.dash-to-dock icon-size-fixed false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true";
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock intellihide-mode 'ALL_WINDOWS'";
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide-mode 'ALL_WINDOWS';
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock isolate-locations false";
gsettings set org.gnome.shell.extensions.dash-to-dock isolate-locations false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock isolate-monitors false";
gsettings set org.gnome.shell.extensions.dash-to-dock isolate-monitors false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock isolate-workspaces false";
gsettings set org.gnome.shell.extensions.dash-to-dock isolate-workspaces false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock manualhide false";
gsettings set org.gnome.shell.extensions.dash-to-dock manualhide false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock max-alpha 0.80000000000000004";
gsettings set org.gnome.shell.extensions.dash-to-dock max-alpha 0.80000000000000004;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock middle-click-action 'launch'";
gsettings set org.gnome.shell.extensions.dash-to-dock middle-click-action 'launch';
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock min-alpha 0.20000000000000001";
gsettings set org.gnome.shell.extensions.dash-to-dock min-alpha 0.20000000000000001;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock minimize-shift true";
gsettings set org.gnome.shell.extensions.dash-to-dock minimize-shift true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true";
gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock preferred-monitor -2";
gsettings set org.gnome.shell.extensions.dash-to-dock preferred-monitor -2;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock preferred-monitor-by-connector 'primary'";
gsettings set org.gnome.shell.extensions.dash-to-dock preferred-monitor-by-connector 'primary';
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock pressure-threshold 100.0";
gsettings set org.gnome.shell.extensions.dash-to-dock pressure-threshold 100.0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock preview-size-scale 0.0";
gsettings set org.gnome.shell.extensions.dash-to-dock preview-size-scale 0.0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false";
gsettings set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-dominant-color false";
gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-dominant-color false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DOTS'";
gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DOTS';
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock scroll-action 'switch-workspace'";
gsettings set org.gnome.shell.extensions.dash-to-dock scroll-action 'switch-workspace';
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock scroll-switch-workspace true";
gsettings set org.gnome.shell.extensions.dash-to-dock scroll-switch-workspace true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock scroll-to-focused-application true";
gsettings set org.gnome.shell.extensions.dash-to-dock scroll-to-focused-application true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock shift-click-action 'launch'";
gsettings set org.gnome.shell.extensions.dash-to-dock shift-click-action 'launch';
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock shift-middle-click-action 'minimize'";
gsettings set org.gnome.shell.extensions.dash-to-dock shift-middle-click-action 'minimize';
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock shortcut "['<Ctrl><Super>Space']"";
gsettings set org.gnome.shell.extensions.dash-to-dock shortcut "['<Ctrl><Super>Space']";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock shortcut-text "[]"";
gsettings set org.gnome.shell.extensions.dash-to-dock shortcut-text "[]";
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock shortcut-timeout 1";
gsettings set org.gnome.shell.extensions.dash-to-dock shortcut-timeout 1;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-always-in-the-edge true";
gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-always-in-the-edge true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true";
gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock show-delay 0.0";
gsettings set org.gnome.shell.extensions.dash-to-dock show-delay 0.0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock show-dock-urgent-notify true";
gsettings set org.gnome.shell.extensions.dash-to-dock show-dock-urgent-notify true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock show-favorites true";
gsettings set org.gnome.shell.extensions.dash-to-dock show-favorites true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock show-icons-emblems true";
gsettings set org.gnome.shell.extensions.dash-to-dock show-icons-emblems true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock show-icons-notifications-counter false";
gsettings set org.gnome.shell.extensions.dash-to-dock show-icons-notifications-counter false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts true";
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts-network true";
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts-network true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts-only-mounted false";
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts-only-mounted false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock show-running true";
gsettings set org.gnome.shell.extensions.dash-to-dock show-running true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock show-show-apps-button true";
gsettings set org.gnome.shell.extensions.dash-to-dock show-show-apps-button true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false";
gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock show-windows-preview true";
gsettings set org.gnome.shell.extensions.dash-to-dock show-windows-preview true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'DEFAULT'";
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'DEFAULT';
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock unity-backlit-items false";
gsettings set org.gnome.shell.extensions.dash-to-dock unity-backlit-items false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-dock workspace-agnostic-urgent-windows true";
gsettings set org.gnome.shell.extensions.dash-to-dock workspace-agnostic-urgent-windows true;

echo "  gsettings - Changing org.gnome.desktop.peripherals.keyboard";
echo "  gsettings set org.gnome.desktop.peripherals.keyboard delay "uint32 250"";
gsettings set org.gnome.desktop.peripherals.keyboard delay "uint32 250";
echo "  gsettings set org.gnome.desktop.peripherals.keyboard repeat true";
gsettings set org.gnome.desktop.peripherals.keyboard repeat true;
echo "  gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval "uint32 15"";
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval "uint32 15";

echo "  gsettings - Changing org.gnome.shell.extensions.dash-to-panel";
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel activate-single-window true";
gsettings set org.gnome.shell.extensions.dash-to-panel activate-single-window true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel animate-app-switch false";
gsettings set org.gnome.shell.extensions.dash-to-panel animate-app-switch false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel animate-appicon-hover false";
gsettings set org.gnome.shell.extensions.dash-to-panel animate-appicon-hover false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel animate-window-launch false";
gsettings set org.gnome.shell.extensions.dash-to-panel animate-window-launch false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-1 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-1 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-2 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-2 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-3 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-3 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-4 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-4 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-5 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-5 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-6 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-6 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-7 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-7 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-8 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-8 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-9 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-9 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-10 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-10 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-1 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-1 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-10 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-10 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-2 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-2 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-3 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-3 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-4 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-4 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-5 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-5 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-6 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-6 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-7 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-7 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-8 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-8 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-9 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-ctrl-hotkey-kp-9 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-1 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-1 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-10 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-10 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-2 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-2 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-3 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-3 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-4 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-4 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-5 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-5 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-6 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-6 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-7 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-7 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-8 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-8 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-9 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-9 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-1 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-1 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-10 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-10 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-2 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-2 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-3 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-3 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-4 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-4 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-5 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-5 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-6 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-6 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-7 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-7 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-8 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-8 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-9 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-hotkey-kp-9 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-1 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-1 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-10 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-10 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-2 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-2 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-3 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-3 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-4 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-4 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-5 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-5 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-6 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-6 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-7 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-7 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-8 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-8 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-9 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-9 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-1 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-1 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-10 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-10 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-2 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-2 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-3 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-3 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-4 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-4 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-5 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-5 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-6 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-6 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-7 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-7 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-8 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-8 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-9 ['']";
gsettings set org.gnome.shell.extensions.dash-to-panel app-shift-hotkey-kp-9 [''];
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel appicon-margin 0";
gsettings set org.gnome.shell.extensions.dash-to-panel appicon-margin 0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel appicon-padding 4";
gsettings set org.gnome.shell.extensions.dash-to-panel appicon-padding 4;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel appicon-style 'NORMAL'";
gsettings set org.gnome.shell.extensions.dash-to-panel appicon-style 'NORMAL';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel click-action 'CYCLE-MIN'";
gsettings set org.gnome.shell.extensions.dash-to-panel click-action 'CYCLE-MIN';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel context-menu-entries '[{"title":"Files","cmd":"nautilus"},{"title":"Terminal","cmd":"TERMINALSETTINGS"},{"title":"System monitor","cmd":"gnome-system-monitor"},{"title":"Extensions","cmd":"gnome-extensions-app"}]'";
gsettings set org.gnome.shell.extensions.dash-to-panel context-menu-entries '[{"title":"Files","cmd":"nautilus"},{"title":"Terminal","cmd":"TERMINALSETTINGS"},{"title":"System monitor","cmd":"gnome-system-monitor"},{"title":"Extensions","cmd":"gnome-extensions-app"}]';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel customize-click true";
gsettings set org.gnome.shell.extensions.dash-to-panel customize-click true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel desktop-line-custom-color 'rgba(200,200,200,0.2)'";
gsettings set org.gnome.shell.extensions.dash-to-panel desktop-line-custom-color 'rgba(200,200,200,0.2)';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel desktop-line-use-custom-color false";
gsettings set org.gnome.shell.extensions.dash-to-panel desktop-line-use-custom-color false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-1 '#5294e2'";
gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-1 '#5294e2';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-2 '#5294e2'";
gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-2 '#5294e2';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-3 '#5294e2'";
gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-3 '#5294e2';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-4 '#5294e2'";
gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-4 '#5294e2';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-dominant false";
gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-dominant false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-override false";
gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-override false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-unfocused-1 '#5294e2'";
gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-unfocused-1 '#5294e2';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-unfocused-2 '#5294e2'";
gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-unfocused-2 '#5294e2';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-unfocused-3 '#5294e2'";
gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-unfocused-3 '#5294e2';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-unfocused-4 '#5294e2'";
gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-unfocused-4 '#5294e2';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-unfocused-different false";
gsettings set org.gnome.shell.extensions.dash-to-panel dot-color-unfocused-different false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel dot-position 'BOTTOM'";
gsettings set org.gnome.shell.extensions.dash-to-panel dot-position 'BOTTOM';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel dot-size 0";
gsettings set org.gnome.shell.extensions.dash-to-panel dot-size 0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel dot-style-focused 'DASHES'";
gsettings set org.gnome.shell.extensions.dash-to-panel dot-style-focused 'DASHES';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel dot-style-unfocused 'DASHES'";
gsettings set org.gnome.shell.extensions.dash-to-panel dot-style-unfocused 'DASHES';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel enter-peek-mode-timeout 500";
gsettings set org.gnome.shell.extensions.dash-to-panel enter-peek-mode-timeout 500;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel extension-version 70";
gsettings set org.gnome.shell.extensions.dash-to-panel extension-version 70;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel focus-highlight false";
gsettings set org.gnome.shell.extensions.dash-to-panel focus-highlight false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel focus-highlight-color '#EEEEEE'";
gsettings set org.gnome.shell.extensions.dash-to-panel focus-highlight-color '#EEEEEE';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel focus-highlight-dominant false";
gsettings set org.gnome.shell.extensions.dash-to-panel focus-highlight-dominant false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel focus-highlight-opacity 25";
gsettings set org.gnome.shell.extensions.dash-to-panel focus-highlight-opacity 25;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel global-border-radius 0";
gsettings set org.gnome.shell.extensions.dash-to-panel global-border-radius 0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel group-apps true";
gsettings set org.gnome.shell.extensions.dash-to-panel group-apps true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel group-apps-label-font-color '#dddddd'";
gsettings set org.gnome.shell.extensions.dash-to-panel group-apps-label-font-color '#dddddd';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel group-apps-label-font-color-minimized '#dddddd'";
gsettings set org.gnome.shell.extensions.dash-to-panel group-apps-label-font-color-minimized '#dddddd';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel group-apps-label-font-size 14";
gsettings set org.gnome.shell.extensions.dash-to-panel group-apps-label-font-size 14;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel group-apps-label-font-weight 'inherit'";
gsettings set org.gnome.shell.extensions.dash-to-panel group-apps-label-font-weight 'inherit';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel group-apps-label-max-width 160";
gsettings set org.gnome.shell.extensions.dash-to-panel group-apps-label-max-width 160;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel group-apps-underline-unfocused true";
gsettings set org.gnome.shell.extensions.dash-to-panel group-apps-underline-unfocused true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel group-apps-use-fixed-width true";
gsettings set org.gnome.shell.extensions.dash-to-panel group-apps-use-fixed-width true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel group-apps-use-launchers false";
gsettings set org.gnome.shell.extensions.dash-to-panel group-apps-use-launchers false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel hide-overview-on-startup false";
gsettings set org.gnome.shell.extensions.dash-to-panel hide-overview-on-startup false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel highlight-appicon-hover true";
gsettings set org.gnome.shell.extensions.dash-to-panel highlight-appicon-hover true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel highlight-appicon-hover-background-color 'rgba(238, 238, 236, 0.1)'";
gsettings set org.gnome.shell.extensions.dash-to-panel highlight-appicon-hover-background-color 'rgba(238, 238, 236, 0.1)';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel highlight-appicon-hover-border-radius 0";
gsettings set org.gnome.shell.extensions.dash-to-panel highlight-appicon-hover-border-radius 0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel highlight-appicon-pressed-background-color 'rgba(238, 238, 236, 0.18)'";
gsettings set org.gnome.shell.extensions.dash-to-panel highlight-appicon-pressed-background-color 'rgba(238, 238, 236, 0.18)';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel hot-keys false";
gsettings set org.gnome.shell.extensions.dash-to-panel hot-keys false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel hotkey-prefix-text 'Super'";
gsettings set org.gnome.shell.extensions.dash-to-panel hotkey-prefix-text 'Super';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel hotkeys-overlay-combo 'TEMPORARILY'";
gsettings set org.gnome.shell.extensions.dash-to-panel hotkeys-overlay-combo 'TEMPORARILY';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel intellihide false";
gsettings set org.gnome.shell.extensions.dash-to-panel intellihide false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-animation-time 100";
gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-animation-time 100;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-behaviour 'ALL_WINDOWS'";
gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-behaviour 'ALL_WINDOWS';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-close-delay 10";
gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-close-delay 10;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-enable-start-delay 0";
gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-enable-start-delay 0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-hide-from-windows true";
gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-hide-from-windows true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-persisted-state -1";
gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-persisted-state -1;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-pressure-threshold 100";
gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-pressure-threshold 100;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-pressure-time 1000";
gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-pressure-time 1000;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-show-in-fullscreen false";
gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-show-in-fullscreen false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-show-on-notification false";
gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-show-on-notification false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-use-pressure false";
gsettings set org.gnome.shell.extensions.dash-to-panel intellihide-use-pressure false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel isolate-monitors false";
gsettings set org.gnome.shell.extensions.dash-to-panel isolate-monitors false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel isolate-workspaces false";
gsettings set org.gnome.shell.extensions.dash-to-panel isolate-workspaces false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel leave-timeout 100";
gsettings set org.gnome.shell.extensions.dash-to-panel leave-timeout 100;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel leftbox-padding -1";
gsettings set org.gnome.shell.extensions.dash-to-panel leftbox-padding -1;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel leftbox-size 0";
gsettings set org.gnome.shell.extensions.dash-to-panel leftbox-size 0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel middle-click-action 'LAUNCH'";
gsettings set org.gnome.shell.extensions.dash-to-panel middle-click-action 'LAUNCH';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel minimize-shift true";
gsettings set org.gnome.shell.extensions.dash-to-panel minimize-shift true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel multi-monitors true";
gsettings set org.gnome.shell.extensions.dash-to-panel multi-monitors true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel overlay-timeout 750";
gsettings set org.gnome.shell.extensions.dash-to-panel overlay-timeout 750;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel overview-click-to-exit false";
gsettings set org.gnome.shell.extensions.dash-to-panel overview-click-to-exit false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel panel-anchors '{"BOE-0x00000000":"MIDDLE","GSM-0x01010101":"MIDDLE"}'";
gsettings set org.gnome.shell.extensions.dash-to-panel panel-anchors '{"BOE-0x00000000":"MIDDLE","GSM-0x01010101":"MIDDLE"}';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel panel-element-positions '{"BOE-0x00000000":[{"element":"showAppsButton","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"centerMonitor"},{"element":"activitiesButton","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":false,"position":"stackedBR"}]}'";
gsettings set org.gnome.shell.extensions.dash-to-panel panel-element-positions '{"BOE-0x00000000":[{"element":"showAppsButton","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"centerMonitor"},{"element":"activitiesButton","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":false,"position":"stackedBR"}]}';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel panel-element-positions-monitors-sync true";
gsettings set org.gnome.shell.extensions.dash-to-panel panel-element-positions-monitors-sync true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel panel-lengths '{"BOE-0x00000000":100}'";
gsettings set org.gnome.shell.extensions.dash-to-panel panel-lengths '{"BOE-0x00000000":100}';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel panel-position 'TOP'";
gsettings set org.gnome.shell.extensions.dash-to-panel panel-position 'TOP';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel panel-positions '{"BOE-0x00000000":"TOP","GSM-0x01010101":"TOP"}'";
gsettings set org.gnome.shell.extensions.dash-to-panel panel-positions '{"BOE-0x00000000":"TOP","GSM-0x01010101":"TOP"}';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel panel-side-margins 0";
gsettings set org.gnome.shell.extensions.dash-to-panel panel-side-margins 0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel panel-side-padding 0";
gsettings set org.gnome.shell.extensions.dash-to-panel panel-side-padding 0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel panel-size 48";
gsettings set org.gnome.shell.extensions.dash-to-panel panel-size 48;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel panel-sizes '{"BOE-0x00000000":32}'";
gsettings set org.gnome.shell.extensions.dash-to-panel panel-sizes '{"BOE-0x00000000":32}';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel panel-top-bottom-margins 0";
gsettings set org.gnome.shell.extensions.dash-to-panel panel-top-bottom-margins 0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel panel-top-bottom-padding 0";
gsettings set org.gnome.shell.extensions.dash-to-panel panel-top-bottom-padding 0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel peek-mode true";
gsettings set org.gnome.shell.extensions.dash-to-panel peek-mode true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel peek-mode-opacity 40";
gsettings set org.gnome.shell.extensions.dash-to-panel peek-mode-opacity 40;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel prefs-opened false";
gsettings set org.gnome.shell.extensions.dash-to-panel prefs-opened false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel preview-custom-opacity 80";
gsettings set org.gnome.shell.extensions.dash-to-panel preview-custom-opacity 80;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel preview-middle-click-close true";
gsettings set org.gnome.shell.extensions.dash-to-panel preview-middle-click-close true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel preview-use-custom-opacity true";
gsettings set org.gnome.shell.extensions.dash-to-panel preview-use-custom-opacity true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel primary-monitor 'BOE-0x00000000'";
gsettings set org.gnome.shell.extensions.dash-to-panel primary-monitor 'BOE-0x00000000';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel progress-show-bar true";
gsettings set org.gnome.shell.extensions.dash-to-panel progress-show-bar true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel progress-show-count true";
gsettings set org.gnome.shell.extensions.dash-to-panel progress-show-count true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel scroll-icon-action 'CYCLE_WINDOWS'";
gsettings set org.gnome.shell.extensions.dash-to-panel scroll-icon-action 'CYCLE_WINDOWS';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel scroll-icon-delay 0";
gsettings set org.gnome.shell.extensions.dash-to-panel scroll-icon-delay 0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel scroll-panel-action 'SWITCH_WORKSPACE'";
gsettings set org.gnome.shell.extensions.dash-to-panel scroll-panel-action 'SWITCH_WORKSPACE';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel scroll-panel-delay 0";
gsettings set org.gnome.shell.extensions.dash-to-panel scroll-panel-delay 0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel scroll-panel-show-ws-popup true";
gsettings set org.gnome.shell.extensions.dash-to-panel scroll-panel-show-ws-popup true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel secondarymenu-contains-appmenu true";
gsettings set org.gnome.shell.extensions.dash-to-panel secondarymenu-contains-appmenu true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel secondarymenu-contains-showdetails false";
gsettings set org.gnome.shell.extensions.dash-to-panel secondarymenu-contains-showdetails false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel shift-click-action 'MINIMIZE'";
gsettings set org.gnome.shell.extensions.dash-to-panel shift-click-action 'MINIMIZE';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel shift-middle-click-action 'LAUNCH'";
gsettings set org.gnome.shell.extensions.dash-to-panel shift-middle-click-action 'LAUNCH';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel shortcut-num-keys 'BOTH'";
gsettings set org.gnome.shell.extensions.dash-to-panel shortcut-num-keys 'BOTH';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel shortcut-overlay-on-secondary false";
gsettings set org.gnome.shell.extensions.dash-to-panel shortcut-overlay-on-secondary false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel shortcut-previews false";
gsettings set org.gnome.shell.extensions.dash-to-panel shortcut-previews false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel shortcut-text ''";
gsettings set org.gnome.shell.extensions.dash-to-panel shortcut-text '';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel shortcut-timeout 2000";
gsettings set org.gnome.shell.extensions.dash-to-panel shortcut-timeout 2000;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel show-activities-button false";
gsettings set org.gnome.shell.extensions.dash-to-panel show-activities-button false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel show-apps-icon-file ''";
gsettings set org.gnome.shell.extensions.dash-to-panel show-apps-icon-file '';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel show-apps-icon-side-padding 8";
gsettings set org.gnome.shell.extensions.dash-to-panel show-apps-icon-side-padding 8;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel show-apps-override-escape true";
gsettings set org.gnome.shell.extensions.dash-to-panel show-apps-override-escape true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel show-favorites false";
gsettings set org.gnome.shell.extensions.dash-to-panel show-favorites false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel show-favorites-all-monitors true";
gsettings set org.gnome.shell.extensions.dash-to-panel show-favorites-all-monitors true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel show-running-apps true";
gsettings set org.gnome.shell.extensions.dash-to-panel show-running-apps true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel show-showdesktop-delay 1000";
gsettings set org.gnome.shell.extensions.dash-to-panel show-showdesktop-delay 1000;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel show-showdesktop-hover false";
gsettings set org.gnome.shell.extensions.dash-to-panel show-showdesktop-hover false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel show-showdesktop-time 300";
gsettings set org.gnome.shell.extensions.dash-to-panel show-showdesktop-time 300;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel show-tooltip false";
gsettings set org.gnome.shell.extensions.dash-to-panel show-tooltip false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel show-window-previews false";
gsettings set org.gnome.shell.extensions.dash-to-panel show-window-previews false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel show-window-previews-timeout 400";
gsettings set org.gnome.shell.extensions.dash-to-panel show-window-previews-timeout 400;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel showdesktop-button-width 8";
gsettings set org.gnome.shell.extensions.dash-to-panel showdesktop-button-width 8;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel status-icon-padding -1";
gsettings set org.gnome.shell.extensions.dash-to-panel status-icon-padding -1;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel stockgs-force-hotcorner false";
gsettings set org.gnome.shell.extensions.dash-to-panel stockgs-force-hotcorner false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel stockgs-keep-dash true";
gsettings set org.gnome.shell.extensions.dash-to-panel stockgs-keep-dash true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel stockgs-keep-top-panel false";
gsettings set org.gnome.shell.extensions.dash-to-panel stockgs-keep-top-panel false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel stockgs-panelbtn-click-only false";
gsettings set org.gnome.shell.extensions.dash-to-panel stockgs-panelbtn-click-only false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel target-prefs-page ''";
gsettings set org.gnome.shell.extensions.dash-to-panel target-prefs-page '';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel taskbar-locked false";
gsettings set org.gnome.shell.extensions.dash-to-panel taskbar-locked false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel trans-bg-color '#000'";
gsettings set org.gnome.shell.extensions.dash-to-panel trans-bg-color '#000';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel trans-dynamic-anim-target 0.80000000000000004";
gsettings set org.gnome.shell.extensions.dash-to-panel trans-dynamic-anim-target 0.80000000000000004;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel trans-dynamic-anim-time 300";
gsettings set org.gnome.shell.extensions.dash-to-panel trans-dynamic-anim-time 300;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel trans-dynamic-behavior 'ALL_WINDOWS'";
gsettings set org.gnome.shell.extensions.dash-to-panel trans-dynamic-behavior 'ALL_WINDOWS';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel trans-dynamic-distance 20";
gsettings set org.gnome.shell.extensions.dash-to-panel trans-dynamic-distance 20;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel trans-gradient-bottom-color '#000'";
gsettings set org.gnome.shell.extensions.dash-to-panel trans-gradient-bottom-color '#000';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel trans-gradient-bottom-opacity 0.20000000000000001";
gsettings set org.gnome.shell.extensions.dash-to-panel trans-gradient-bottom-opacity 0.20000000000000001;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel trans-gradient-top-color '#000'";
gsettings set org.gnome.shell.extensions.dash-to-panel trans-gradient-top-color '#000';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel trans-gradient-top-opacity 0.0";
gsettings set org.gnome.shell.extensions.dash-to-panel trans-gradient-top-opacity 0.0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel trans-panel-opacity 0.0";
gsettings set org.gnome.shell.extensions.dash-to-panel trans-panel-opacity 0.0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel trans-use-custom-bg false";
gsettings set org.gnome.shell.extensions.dash-to-panel trans-use-custom-bg false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel trans-use-custom-gradient false";
gsettings set org.gnome.shell.extensions.dash-to-panel trans-use-custom-gradient false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel trans-use-custom-opacity false";
gsettings set org.gnome.shell.extensions.dash-to-panel trans-use-custom-opacity false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel trans-use-dynamic-opacity false";
gsettings set org.gnome.shell.extensions.dash-to-panel trans-use-dynamic-opacity false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel tray-padding -1";
gsettings set org.gnome.shell.extensions.dash-to-panel tray-padding -1;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel tray-size 0";
gsettings set org.gnome.shell.extensions.dash-to-panel tray-size 0;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-animation-time 260";
gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-animation-time 260;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-aspect-ratio-x 16";
gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-aspect-ratio-x 16;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-aspect-ratio-y 9";
gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-aspect-ratio-y 9;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-custom-icon-size 16";
gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-custom-icon-size 16;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-fixed-x false";
gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-fixed-x false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-fixed-y true";
gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-fixed-y true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-hide-immediate-click false";
gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-hide-immediate-click false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-manual-styling false";
gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-manual-styling false;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-padding 8";
gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-padding 8;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-show-title true";
gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-show-title true;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-size 240";
gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-size 240;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-title-font-color '#dddddd'";
gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-title-font-color '#dddddd';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-title-font-size 14";
gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-title-font-size 14;
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-title-font-weight 'inherit'";
gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-title-font-weight 'inherit';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-title-position 'TOP'";
gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-title-position 'TOP';
echo "  gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-use-custom-icon-size false";
gsettings set org.gnome.shell.extensions.dash-to-panel window-preview-use-custom-icon-size false;

echo "  gsettings - Changing org.gnome.shell.extensions.tophat";
echo "  gsettings set org.gnome.shell.extensions.tophat cpu-display 'both'";
gsettings set org.gnome.shell.extensions.tophat cpu-display 'both';
echo "  gsettings set org.gnome.shell.extensions.tophat cpu-normalize-proc-use true";
gsettings set org.gnome.shell.extensions.tophat cpu-normalize-proc-use true;
echo "  gsettings set org.gnome.shell.extensions.tophat cpu-show-cores true";
gsettings set org.gnome.shell.extensions.tophat cpu-show-cores true;
echo "  gsettings set org.gnome.shell.extensions.tophat cpu-sort-cores false";
gsettings set org.gnome.shell.extensions.tophat cpu-sort-cores false;
echo "  gsettings set org.gnome.shell.extensions.tophat fs-display 'both'";
gsettings set org.gnome.shell.extensions.tophat fs-display 'both';
echo "  gsettings set org.gnome.shell.extensions.tophat fs-hide-in-menu '/boot/efi'";
gsettings set org.gnome.shell.extensions.tophat fs-hide-in-menu '/boot/efi';
echo "  gsettings set org.gnome.shell.extensions.tophat group-procs true";
gsettings set org.gnome.shell.extensions.tophat group-procs true;
echo "  gsettings set org.gnome.shell.extensions.tophat mem-abs-units true";
gsettings set org.gnome.shell.extensions.tophat mem-abs-units true;
echo "  gsettings set org.gnome.shell.extensions.tophat mem-display 'both'";
gsettings set org.gnome.shell.extensions.tophat mem-display 'both';
echo "  gsettings set org.gnome.shell.extensions.tophat meter-fg-color 'rgb(222,221,218)'";
gsettings set org.gnome.shell.extensions.tophat meter-fg-color 'rgb(222,221,218)';
echo "  gsettings set org.gnome.shell.extensions.tophat mount-to-monitor '/home'";
gsettings set org.gnome.shell.extensions.tophat mount-to-monitor '/home';
echo "  gsettings set org.gnome.shell.extensions.tophat network-device 'Automatic'";
gsettings set org.gnome.shell.extensions.tophat network-device 'Automatic';
echo "  gsettings set org.gnome.shell.extensions.tophat network-usage-unit 'bytes'";
gsettings set org.gnome.shell.extensions.tophat network-usage-unit 'bytes';
echo "  gsettings set org.gnome.shell.extensions.tophat position-in-panel 'right'";
gsettings set org.gnome.shell.extensions.tophat position-in-panel 'right';
echo "  gsettings set org.gnome.shell.extensions.tophat refresh-rate 'medium'";
gsettings set org.gnome.shell.extensions.tophat refresh-rate 'medium';
echo "  gsettings set org.gnome.shell.extensions.tophat show-cpu true";
gsettings set org.gnome.shell.extensions.tophat show-cpu true;
echo "  gsettings set org.gnome.shell.extensions.tophat show-disk true";
gsettings set org.gnome.shell.extensions.tophat show-disk true;
echo "  gsettings set org.gnome.shell.extensions.tophat show-fs true";
gsettings set org.gnome.shell.extensions.tophat show-fs true;
echo "  gsettings set org.gnome.shell.extensions.tophat show-icons true";
gsettings set org.gnome.shell.extensions.tophat show-icons true;
echo "  gsettings set org.gnome.shell.extensions.tophat show-mem true";
gsettings set org.gnome.shell.extensions.tophat show-mem true;
echo "  gsettings set org.gnome.shell.extensions.tophat show-menu-actions true";
gsettings set org.gnome.shell.extensions.tophat show-menu-actions true;
echo "  gsettings set org.gnome.shell.extensions.tophat show-net true";
gsettings set org.gnome.shell.extensions.tophat show-net true;
echo "  gsettings set org.gnome.shell.extensions.tophat use-system-accent false";
gsettings set org.gnome.shell.extensions.tophat use-system-accent false;

echo "  GNOME Configuration Complete!"
