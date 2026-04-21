#!/usr/bin/env bash

# FILENAME: bad-apple.tmux
# AUTHOR: Zachary Krepelka
# DATE: Saturday, November 15th, 2025
# ABOUT: Bad Apple!! but it's a terminal multiplexer
# ORIGIN: https://github.com/zachary-krepelka/tmux-bad-apple.git
# UPDATED: Tuesday, April 21st, 2026 at 12:56 PM

show_command_on_error=false

location="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

tmux bind-key -N 'Tmux Bad Apple Media Viewer' a switch-client -T media-player

key_descr='Tmux Bad Apple Media Viewer Quick Access'

for n in {1..9}
do
	cmd="bash scripts/view.sh #{?@mediaconf$n,#{@mediaconf$n} ,}#{@media$n}"

	if ! $show_command_on_error
	then cmd+=' || true'
	fi

	tmux source-file - <<-CONFIG
	bind-key -N '$key_descr Number $n' -T media-player $n {
	    if-shell -F '#{@media$n}' {
	        run-shell -E -c '$location' '$cmd'
	    } {
	        display-message 'tmux-bad-apple: \
		you have not set a path for this quick access item'
	    }
	}
	CONFIG
done

tmux source-file - <<CONFIG
bind-key -N 'Tmux Bad Apple File Selector' -T media-player 0 {
	command-prompt -p 'Enter a tmux media file:,Flags?' {
		run-shell "
			cd '#{pane_current_path}' &&
			bash '$location/scripts/view.sh' %2 %1
		"
	}
}
CONFIG

# vim: tw=80 ts=8 sw=8 noet
