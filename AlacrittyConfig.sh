#!/usr/bin/env sh

cat <<'EOF' > ~/.alacritty.toml
[window]
	padding = { x = 2, y = 2 }
	decorations = "None"
	startup_mode = "Maximized"
	decorations_theme_variant = "Dark"
[font]
	normal = { family = "JetBrainsMono Nerd Font Mono", style = "Regular" }
	bold = { family = "JetBrainsMono Nerd Font Mono", style = "Bold" }
[colors]
	[colors.primary]
		foreground = "#FFFFFF"
		background = "#050505"
		dim_foreground = "#000000"
[cursor]
	style = { shape = "Block", blinking = "Always" }
	blink_interval = 500
	blink_timeout = 7
[keyboard]
	bindings = [
		{ key = "n", mods = "Control|Shift", action = "CreateNewWindow" },
		{ key = "PageUp", mods = "Shift", action = "ScrollPageUp" },
		{ key = "PageDown", mods = "Shift", action = "ScrollPageDown" },
		{ key = "Up", mods = "Shift", action = "ScrollLineUp" },
		{ key = "Down", mods = "Shift", action = "ScrollLineDown" },
	]
EOF