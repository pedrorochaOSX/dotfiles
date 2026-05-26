#!/usr/bin/env sh

set -e

mkdir -p ~/.config/ghostty

cat <<'EOF' > ~/.config/ghostty/config
background = #050505
foreground = #FFFFFF
font-family = "JetBrainsMono Nerd Font Mono"
maximize
window-decoration = "none"
confirm-close-surface = false
window-vsync = false
EOF

echo "Ghostty configuration complete."
