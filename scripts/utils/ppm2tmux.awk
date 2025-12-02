#!/usr/bin/env -S awk -f

# FILENAME: ppm2tmux.awk
# AUTHOR: Zachary Krepelka
# DATE: Wednesday, October 29th, 2025
# USAGE: convert -compress none $image ppm:- | awk -f ppm2tmux.awk
# ORIGIN: https://github.com/zachary-krepelka/tmux-bad-apple.git

BEGIN {
	RS="( |\n)+"
	tmux_cmd = "set -pt0:0.%d window-style 'bg=#%02x%02x%02x'\n"
}

NR > 4 {
	color[channel = record++ % 3] = $0

	if (channel == 2) {
		printf tmux_cmd, pixel++, color[0], color[1], color[2]
	}
}
