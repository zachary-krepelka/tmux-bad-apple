#!/usr/bin/env bash

# FILENAME: bad-apple.tmux
# AUTHOR: Zachary Krepelka
# DATE: Saturday, November 15th, 2025
# ABOUT: Bad Apple!! but it's a terminal multiplexer
# ORIGIN: https://github.com/zachary-krepelka/tmux-bad-apple.git
# UPDATED: Friday, November 21st, 2025 at 7:30 AM

location="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

tmux bind-key -N 'Tmux Bad Apple Media Viewer' a switch-client -T media-player

key_descr='Tmux Bad Apple Media Viewer Quick Access'

for n in {1..9}
do
	tmux source-file - <<-CONFIG
	bind-key -N '$key_descr Number $n' -T media-player $n {
	    if-shell -F '#{@media$n}' {
	        run-shell -c '$location' "
			bash scripts/view.sh #{@mediaconf$n} '#{@media$n}'
		"
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
