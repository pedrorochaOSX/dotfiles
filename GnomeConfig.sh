#!/usr/bin/env sh

set -e


download_latest_asset() {
  repo="$1"
  pattern="$2"

  echo "-> Querying latest release for $repo..."
  download_url=$(curl -s "https://api.github.com/repos/$repo/releases/latest" \
    | sed -n 's/.*"browser_download_url": *"\([^"\\]*\)".*/\1/p' \
    | grep -E "$pattern" \
    | head -n1)

  if [ -z "$download_url" ]; then
    echo "Could not find a matching asset for $repo (pattern: $pattern)"
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
  curl -L -s -o "$asset_zip" "$download_url"

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

  if command -v gnome-extensions >/dev/null 2>&1; then
    echo "-> Enabling $ext_name..."
    gnome-extensions enable "$ext_name" || true
  else
    echo "Note: install 'gnome-extensions' (gnome-extensions-app) to enable $ext_name automatically."
  fi
}

install_extension_from_github "micheleg/dash-to-dock" "dash-to-dock.*\\.zip" "dash-to-dock@micxgx.gmail.com" || \
  echo "Warning: Dash-to-Dock installation failed or asset not found."

install_extension_from_github "fflewddur/tophat" "tophat.*\\.zip" "tophat@fflewddur.github.io" || \
  echo "Warning: TopHat installation failed or asset not found."

install_extension_from_github "home-sweet-gnome/dash-to-panel" "dash-to-panel.*\\.zip" "dash-to-panel@jderose9.github.com" || \
  echo "Warning: Dash-to-Panel installation failed or asset not found."

echo "  GNOME extension installation steps finished."

echo "  gsettings - Changing org.gnome.desktop.wm.keybindings";
gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "['<Super>w']";
gsettings set org.gnome.desktop.wm.keybindings always-on-top "[]";
gsettings set org.gnome.desktop.wm.keybindings begin-move "[]";
gsettings set org.gnome.desktop.wm.keybindings begin-resize "['<Super>r']";
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']";
gsettings set org.gnome.desktop.wm.keybindings cycle-group "[]";
gsettings set org.gnome.desktop.wm.keybindings cycle-group-backward "[]";
gsettings set org.gnome.desktop.wm.keybindings cycle-panels "[]";
gsettings set org.gnome.desktop.wm.keybindings cycle-panels-backward "[]";
gsettings set org.gnome.desktop.wm.keybindings cycle-windows "['<Alt>Escape']";
gsettings set org.gnome.desktop.wm.keybindings cycle-windows-backward "['<Shift><Alt>Escape']";
gsettings set org.gnome.desktop.wm.keybindings lower "[]";
gsettings set org.gnome.desktop.wm.keybindings maximize "[]";
gsettings set org.gnome.desktop.wm.keybindings maximize-horizontally "[]";
gsettings set org.gnome.desktop.wm.keybindings maximize-vertically "[]";
gsettings set org.gnome.desktop.wm.keybindings minimize "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-center "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-corner-ne "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-corner-nw "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-corner-se "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-corner-sw "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-side-e "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-side-n "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-side-s "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-side-w "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-up "['<Shift><Super>Up']";
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-down "['<Shift><Super>Down']";
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-left "['<Shift><Super>Left']";
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-right "['<Shift><Super>Right']";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-7 "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-8 "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-9 "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-10 "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-11 "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-12 "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-last "[]";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "['<Shift><Super>s']";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "['<Shift><Super>f']";
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "[]";
gsettings set org.gnome.desktop.wm.keybindings panel-main-menu "['<Alt>F1']";
gsettings set org.gnome.desktop.wm.keybindings panel-run-dialog "[]";
gsettings set org.gnome.desktop.wm.keybindings raise "[]";
gsettings set org.gnome.desktop.wm.keybindings raise-or-lower "[]";
gsettings set org.gnome.desktop.wm.keybindings set-spew-mark "[]";
gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']";
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']";
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab']";
gsettings set org.gnome.desktop.wm.keybindings switch-group "['<Alt>Tab']";
gsettings set org.gnome.desktop.wm.keybindings switch-group-backward "['<Shift><Alt>Tab']";
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Super>space', 'XF86Keyboard']";
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Shift><Super>space', '<Shift>XF86Keyboard']";
gsettings set org.gnome.desktop.wm.keybindings switch-panels "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-panels-backward "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-9 "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-10 "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-11 "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-12 "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-last "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Super>s']";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Super>f']";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-windows "[]";
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "[]";
gsettings set org.gnome.desktop.wm.keybindings toggle-above "[]";
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>x']";
gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Super>e', '<Super>Up', '<Super>KP_5']";
gsettings set org.gnome.desktop.wm.keybindings toggle-on-all-workspaces "[]";
gsettings set org.gnome.desktop.wm.keybindings unmaximize "[]";

echo "  gsettings - Changing org.gnome.mutter.keybindings";
gsettings set org.gnome.mutter.keybindings cancel-input-capture "['<Super><Shift>Escape']";
gsettings set org.gnome.mutter.keybindings rotate-monitor "['XF86RotateWindows']";
gsettings set org.gnome.mutter.keybindings switch-monitor "['<Super>p', 'XF86Display']";
gsettings set org.gnome.mutter.keybindings toggle-tiled-left "['<Super>Left']";
gsettings set org.gnome.mutter.keybindings toggle-tiled-right "['<Super>Right']";

echo "  gsettings - Changing org.gnome.shell.keybindings";
gsettings set org.gnome.shell.keybindings focus-active-notification "[]";
gsettings set org.gnome.shell.keybindings open-new-window-application-1 "[]";
gsettings set org.gnome.shell.keybindings open-new-window-application-2 "[]";
gsettings set org.gnome.shell.keybindings open-new-window-application-3 "[]";
gsettings set org.gnome.shell.keybindings open-new-window-application-4 "[]";
gsettings set org.gnome.shell.keybindings open-new-window-application-5 "[]";
gsettings set org.gnome.shell.keybindings open-new-window-application-6 "[]";
gsettings set org.gnome.shell.keybindings open-new-window-application-7 "[]";
gsettings set org.gnome.shell.keybindings open-new-window-application-8 "[]";
gsettings set org.gnome.shell.keybindings open-new-window-application-9 "[]";
gsettings set org.gnome.shell.keybindings screenshot "[]";
gsettings set org.gnome.shell.keybindings screenshot-window "[]";
gsettings set org.gnome.shell.keybindings shift-overview-down "[]";
gsettings set org.gnome.shell.keybindings shift-overview-up "[]";
gsettings set org.gnome.shell.keybindings show-screen-recording-ui "[]";
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Super>a']";
gsettings set org.gnome.shell.keybindings switch-to-application-1 "[]";
gsettings set org.gnome.shell.keybindings switch-to-application-2 "[]";
gsettings set org.gnome.shell.keybindings switch-to-application-3 "[]";
gsettings set org.gnome.shell.keybindings switch-to-application-4 "[]";
gsettings set org.gnome.shell.keybindings switch-to-application-5 "[]";
gsettings set org.gnome.shell.keybindings switch-to-application-6 "[]";
gsettings set org.gnome.shell.keybindings switch-to-application-7 "[]";
gsettings set org.gnome.shell.keybindings switch-to-application-8 "[]";
gsettings set org.gnome.shell.keybindings switch-to-application-9 "[]";
gsettings set org.gnome.shell.keybindings toggle-application-view "[]";
gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>v']";
gsettings set org.gnome.shell.keybindings toggle-overview "[]";
gsettings set org.gnome.shell.keybindings toggle-quick-settings "['<Super>b']";

echo "  gsettings - Changing org.gnome.settings-daemon.plugins.media-keys";
gsettings set org.gnome.settings-daemon.plugins.media-keys battery-status "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys battery-status-static "['XF86Battery']";
gsettings set org.gnome.settings-daemon.plugins.media-keys calculator "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys calculator-static "['XF86Calculator']";
gsettings set org.gnome.settings-daemon.plugins.media-keys control-center "['<Super>i']";
gsettings set org.gnome.settings-daemon.plugins.media-keys control-center-static "['XF86Tools']";
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']";
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name "Open GNOME Characters";
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "gnome-characters";
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding "<Super>c";
gsettings set org.gnome.settings-daemon.plugins.media-keys decrease-text-size "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys eject "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys eject-static "['XF86Eject']";
gsettings set org.gnome.settings-daemon.plugins.media-keys email "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys email-static "['XF86Mail']";
gsettings set org.gnome.settings-daemon.plugins.media-keys help "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys hibernate "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys hibernate-static "['XF86Suspend', 'XF86Hibernate']";
gsettings set org.gnome.settings-daemon.plugins.media-keys home "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys home-static "['XF86Explorer']";
gsettings set org.gnome.settings-daemon.plugins.media-keys increase-text-size "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-down "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-down-static "['XF86KbdBrightnessDown']";
gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-toggle "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-toggle-static "['XF86KbdLightOnOff']";
gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-up "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys keyboard-brightness-up-static "['XF86KbdBrightnessUp']";
gsettings set org.gnome.settings-daemon.plugins.media-keys logout "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys magnifier "['<Super>1']";
gsettings set org.gnome.settings-daemon.plugins.media-keys magnifier-zoom-in "['<Super>3']";
gsettings set org.gnome.settings-daemon.plugins.media-keys magnifier-zoom-out "['<Super>2']";
gsettings set org.gnome.settings-daemon.plugins.media-keys media "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys media-static "['XF86AudioMedia']";
gsettings set org.gnome.settings-daemon.plugins.media-keys mic-mute "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys mic-mute-static "['XF86AudioMicMute']";
gsettings set org.gnome.settings-daemon.plugins.media-keys next "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys next-static "['XF86AudioNext', '<Ctrl>XF86AudioNext']";
gsettings set org.gnome.settings-daemon.plugins.media-keys on-screen-keyboard "['<Ctrl><Super>k']";
gsettings set org.gnome.settings-daemon.plugins.media-keys pause "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys pause-static "['XF86AudioPause']";
gsettings set org.gnome.settings-daemon.plugins.media-keys play "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys play-static "['XF86AudioPlay', '<Ctrl>XF86AudioPlay']";
gsettings set org.gnome.settings-daemon.plugins.media-keys playback-forward "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys playback-forward-static "['XF86AudioForward']";
gsettings set org.gnome.settings-daemon.plugins.media-keys playback-random "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys playback-random-static "['XF86AudioRandomPlay']";
gsettings set org.gnome.settings-daemon.plugins.media-keys playback-repeat "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys playback-repeat-static "['XF86AudioRepeat']";
gsettings set org.gnome.settings-daemon.plugins.media-keys playback-rewind "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys playback-rewind-static "['XF86AudioRewind']";
gsettings set org.gnome.settings-daemon.plugins.media-keys power "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys power-static "['XF86PowerOff']";
gsettings set org.gnome.settings-daemon.plugins.media-keys previous "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys previous-static "['XF86AudioPrev', '<Ctrl>XF86AudioPrev']";
gsettings set org.gnome.settings-daemon.plugins.media-keys rfkill "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys rfkill-bluetooth "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys rfkill-bluetooth-static "['XF86Bluetooth']";
gsettings set org.gnome.settings-daemon.plugins.media-keys rfkill-static "['XF86WLAN', 'XF86UWB', 'XF86RFKill']";
gsettings set org.gnome.settings-daemon.plugins.media-keys rotate-video-lock "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys rotate-video-lock-static "['<Super>o', 'XF86RotationLockToggle']";
gsettings set org.gnome.settings-daemon.plugins.media-keys screen-brightness-cycle "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys screen-brightness-cycle-static "['XF86MonBrightnessCycle']";
gsettings set org.gnome.settings-daemon.plugins.media-keys screen-brightness-down "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys screen-brightness-down-static "['XF86MonBrightnessDown']";
gsettings set org.gnome.settings-daemon.plugins.media-keys screen-brightness-up "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys screen-brightness-up-static "['XF86MonBrightnessUp']";
gsettings set org.gnome.settings-daemon.plugins.media-keys screenreader "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>l']";
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver-static "['XF86ScreenSaver']";
gsettings set org.gnome.settings-daemon.plugins.media-keys search "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys search-static "['XF86Search']";
gsettings set org.gnome.settings-daemon.plugins.media-keys stop "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys stop-static "['XF86AudioStop']";
gsettings set org.gnome.settings-daemon.plugins.media-keys suspend "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys suspend-static "['XF86Sleep']";
gsettings set org.gnome.settings-daemon.plugins.media-keys toggle-contrast "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-off "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-off-static "['XF86TouchpadOff']";
gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-on "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-on-static "['XF86TouchpadOn']";
gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-toggle "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys touchpad-toggle-static "['XF86TouchpadToggle', '<Ctrl><Super>XF86TouchpadToggle']";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down-precise "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down-precise-static "['<Shift>XF86AudioLowerVolume', '<Ctrl><Shift>XF86AudioLowerVolume']";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down-quiet "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down-quiet-static "['XF86AudioLowerVolume']";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-down-static "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-mute "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-mute-quiet "['XF86AudioMute']";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-mute-quiet-static "['<Alt>XF86AudioMute']";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-mute-static "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-step 6;
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up-precise "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up-precise-static "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up-quiet "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up-quiet-static "['XF86AudioRaiseVolume']";
gsettings set org.gnome.settings-daemon.plugins.media-keys volume-up-static "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys www "[]";
gsettings set org.gnome.settings-daemon.plugins.media-keys www-static "['XF86WWW']";

echo "  gsettings - Changing org.gnome.shell.extensions.dash-to-dock";
gsettings set org.gnome.shell.extensions.dash-to-dock activate-single-window true;
gsettings set org.gnome.shell.extensions.dash-to-dock always-center-icons false;
gsettings set org.gnome.shell.extensions.dash-to-dock animation-time 0.1801;
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-1 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-2 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-3 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-4 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-5 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-6 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-7 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-8 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-9 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-ctrl-hotkey-10 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-1 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-2 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-3 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-4 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-5 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-6 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-7 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-8 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-9 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-hotkey-10 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-1 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-2 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-3 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-4 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-5 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-6 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-7 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-8 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-9 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock app-shift-hotkey-10 "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock application-counter-overrides-notifications true;
gsettings set org.gnome.shell.extensions.dash-to-dock apply-custom-theme false;
gsettings set org.gnome.shell.extensions.dash-to-dock apply-glossy-effect false;
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true;
gsettings set org.gnome.shell.extensions.dash-to-dock autohide-in-fullscreen false;
gsettings set org.gnome.shell.extensions.dash-to-dock background-color '#202020';
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.80000000000000004;
gsettings set org.gnome.shell.extensions.dash-to-dock bolt-support true;
gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'focus-or-appspread';
gsettings set org.gnome.shell.extensions.dash-to-dock custom-background-color true;
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-customize-running-dots false;
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-running-dots-border-color '#ffffff';
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-running-dots-border-width 0;
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-running-dots-color '#ffffff';
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink false;
gsettings set org.gnome.shell.extensions.dash-to-dock customize-alphas false;
gsettings set org.gnome.shell.extensions.dash-to-dock dance-urgent-applications true;
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 40;
gsettings set org.gnome.shell.extensions.dash-to-dock default-windows-preview-to-open false;
gsettings set org.gnome.shell.extensions.dash-to-dock disable-overview-on-startup true;
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false;
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM';
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false;
gsettings set org.gnome.shell.extensions.dash-to-dock force-straight-corner false;
gsettings set org.gnome.shell.extensions.dash-to-dock height-fraction 0.98999999999999999;
gsettings set org.gnome.shell.extensions.dash-to-dock hide-delay 0.00000000000000001;
gsettings set org.gnome.shell.extensions.dash-to-dock hide-tooltip false;
gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys true;
gsettings set org.gnome.shell.extensions.dash-to-dock hotkeys-overlay false;
gsettings set org.gnome.shell.extensions.dash-to-dock hotkeys-show-dock true;
gsettings set org.gnome.shell.extensions.dash-to-dock icon-size-fixed false;
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true;
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide-mode 'ALL_WINDOWS';
gsettings set org.gnome.shell.extensions.dash-to-dock isolate-locations false;
gsettings set org.gnome.shell.extensions.dash-to-dock isolate-monitors false;
gsettings set org.gnome.shell.extensions.dash-to-dock isolate-workspaces false;
gsettings set org.gnome.shell.extensions.dash-to-dock manualhide false;
gsettings set org.gnome.shell.extensions.dash-to-dock max-alpha 0.80000000000000004;
gsettings set org.gnome.shell.extensions.dash-to-dock middle-click-action 'launch';
gsettings set org.gnome.shell.extensions.dash-to-dock min-alpha 0.20000000000000001;
gsettings set org.gnome.shell.extensions.dash-to-dock minimize-shift true;
gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true;
gsettings set org.gnome.shell.extensions.dash-to-dock preferred-monitor -2;
gsettings set org.gnome.shell.extensions.dash-to-dock preferred-monitor-by-connector 'primary';
gsettings set org.gnome.shell.extensions.dash-to-dock pressure-threshold 100.0;
gsettings set org.gnome.shell.extensions.dash-to-dock preview-size-scale 0.0;
gsettings set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false;
gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-dominant-color false;
gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DOTS';
gsettings set org.gnome.shell.extensions.dash-to-dock scroll-action 'switch-workspace';
gsettings set org.gnome.shell.extensions.dash-to-dock scroll-switch-workspace true;
gsettings set org.gnome.shell.extensions.dash-to-dock scroll-to-focused-application true;
gsettings set org.gnome.shell.extensions.dash-to-dock shift-click-action 'launch';
gsettings set org.gnome.shell.extensions.dash-to-dock shift-middle-click-action 'minimize';
gsettings set org.gnome.shell.extensions.dash-to-dock shortcut "['<Ctrl><Super>Space']";
gsettings set org.gnome.shell.extensions.dash-to-dock shortcut-text "[]";
gsettings set org.gnome.shell.extensions.dash-to-dock shortcut-timeout 1;
gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-always-in-the-edge true;
gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true;
gsettings set org.gnome.shell.extensions.dash-to-dock show-delay 0.0;
gsettings set org.gnome.shell.extensions.dash-to-dock show-dock-urgent-notify true;
gsettings set org.gnome.shell.extensions.dash-to-dock show-favorites true;
gsettings set org.gnome.shell.extensions.dash-to-dock show-icons-emblems true;
gsettings set org.gnome.shell.extensions.dash-to-dock show-icons-notifications-counter false;
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts true;
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts-network true;
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts-only-mounted false;
gsettings set org.gnome.shell.extensions.dash-to-dock show-running true;
gsettings set org.gnome.shell.extensions.dash-to-dock show-show-apps-button true;
gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false;
gsettings set org.gnome.shell.extensions.dash-to-dock show-windows-preview true;
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'DEFAULT';
gsettings set org.gnome.shell.extensions.dash-to-dock unity-backlit-items false;
gsettings set org.gnome.shell.extensions.dash-to-dock workspace-agnostic-urgent-windows true;

echo "  gsettings - Changing org.gnome.desktop.peripherals.keyboard";
gsettings set org.gnome.desktop.peripherals.keyboard delay "uint32 250";
gsettings set org.gnome.desktop.peripherals.keyboard repeat true
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval "uint32 15";