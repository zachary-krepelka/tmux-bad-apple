get_progress() {
	tmux -L media-player show-buffer -b progress 2>/dev/null || echo 0
}

sleep_until_percent () {

	local OPTIND epsilon=0.1

	while getopts e: option
	do
		case "$option" in
			e) epsilon="$OPTARG";;
		esac
	done

	shift $((OPTIND - 1))

	local target="$1"

	while test $(get_progress) -lt $target
	do sleep $epsilon
	done
}

status 'This is a demonstration of tmux-bad-apple by @zachary-krepelka.'

shared_target_percent=9

prompt '$ '
