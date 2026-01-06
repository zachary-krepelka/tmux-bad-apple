#!/usr/bin/env bash

# FILENAME: view.sh
# AUTHOR: Zachary Krepelka
# DATE: Tuesday, October 28th, 2025
# ABOUT: Tmux Bad Apple Media Viewer
# ORIGIN: https://github.com/zachary-krepelka/tmux-bad-apple.git
# UPDATED: Tuesday, January 6th, 2026 at 2:16 AM

# Functions --------------------------------------------------------------- {{{1

program="${0##*/}"
padding="${program//?/ }"

usage() {
	cat <<-USAGE
	Tmux Bad Apple Media Viewer

	Usage:
	  bash $program [-hH] [-c <cmd>] [-p <NxM>] <image>
	  bash $program [-hHdm] [-c <cmd>] [-p <NxM>] [-t <tempo>]
	       $padding [-s | -r <rate>] <video>

	  where <image> and <video> are in special file formats

	Options:
	  -p <NxM>    set dimensions of each [p]ane (default: 3x1)
	  -c <cmd>    set [c]ommand to run in each pane
	  -m          [m]ute audio
	  -s          enable frame rate [s]ynchronization
	  -r <rate>   set frame [r]ate adjustment factor
	              best if 0 < RATE < 1  (default: 1)
	  -t <tempo>  set audio [t]empo (default: 1)
	  -d          reports playback [d]uration before exiting

	Documentation:
	  -h  display this [h]elp message and exit
	  -H  read documentation for this script then exit

	Examples:
	  bash $program finch.tpic
	  bash $program -ms bad-apple.tvid
	USAGE
}

documentation() {
	pod2text "$0" | less -Sp '^[^ ].*$' +k
}

error() {
	local code="$1" message="$2"
	echo "$program: error: $message" >&2
	exit "$code"
}

check_dependencies() {

	local missing= dependencies=(
		cat cava cut dc jq less
		play pod2text sleep
		split tar time tmux
		whiptail
	)

	for cmd in "${dependencies[@]}"
	do
		if ! type -P "$cmd" &>/dev/null
		then missing+="$cmd, "
		fi
	done

	if test -n "$missing"
	then error 1 "missing dependencies: ${missing%, }"
	fi
}

validate_geometry() {

	# TODO maybe this could be replaced with '#{window_bigger}'?

	local \
		candidate_width=$1 \
		candidate_height=$2 \
		maximum_width=$(tmux display -p '#{client_width}') \
		maximum_height=$(tmux display -p '#{client_height}')

	test $candidate_width  -gt $maximum_width  && return 1
	test $candidate_height -gt $maximum_height && return 2

	return 0
}

validate_file_format() {

	# The supported file format is a tarball containing the following files.

	# 	1) meta-data.json     image or video
	# 	2) visual-data.tmux   image or video
	# 	3) audio-data.mp3              video only

	local candidate_file="$1"

	for component in meta-data.json visual-data.tmux
	do tar -t -f "$candidate_file" $component &> /dev/null || return 1
	done

	if test "$(tar -xOf "$input" meta-data.json | jq -r .medium)" = video
	then tar -t -f "$candidate_file" audio-data.mp3 || return 1
	fi

	return 0
}

# Command-line Argument Parsing ------------------------------------------- {{{1

check_dependencies # must be called before any external command

frame_rate_synchronization_enabled=false
frame_rate_adjustment_factor=1
report_duration=false
mute=false
tempo=1

pane_cols=3
pane_rows=1
cmd=

while getopts 'hHc:dmp:r:st:' option
do
	case "$option" in
		h) usage; exit 0;;
		H) documentation; exit 0;;
		c) cmd="$OPTARG";;
		d) report_duration=true;;
		m) mute=true;;
		p)
			if [[ $OPTARG =~ ^[1-9][0-9]*x[1-9][0-9]*$ ]]
			then
				pane_cols=$(cut -dx -f1 <<< $OPTARG)
				pane_rows=$(cut -dx -f2 <<< $OPTARG)
			else
				error 7 'invalid pane dimensions'
			fi
		;;
		r)
			frame_rate_synchronization_enabled=true
			if [[ $OPTARG =~ ^[+-]?([0-9]+\.?|[0-9]*\.[0-9]+)$ ]]
			then frame_rate_adjustment_factor=$OPTARG
                        else error 8 'invalid frame rate adjustment factor'
                        fi
		;;
		s)
			frame_rate_synchronization_enabled=true
			frame_rate_adjustment_factor=1
			;;
		t)
			if [[ $OPTARG =~ ^[+-]?([0-9]+\.?|[0-9]*\.[0-9]+)$ ]]
			then tempo=$OPTARG
                        else error 9 'invalid audio tempo'
                        fi
		;;
	esac
done

shift $((OPTIND-1))

if test $# -ne 1
then error 2 'exactly one argument is required'
fi

input="$1"

if ! test -f "$input"
then error 3 'input is not a file'
fi

validate_file_format "$input" || error 4 'invalid file format'

if test -z "$TMUX"
then error 5 'this script must run inside of a tmux client'
fi

# Variables --------------------------------------------------------------- {{{1

server=media-player # This is the the name of the server socket file.

media_type=$(tar -xOf "$input" meta-data.json | jq -r .medium)

wind_cols=$(tar -xOf "$input" meta-data.json | jq .width)  #| measured in panes
wind_rows=$(tar -xOf "$input" meta-data.json | jq .height) #|

pixels=$((wind_cols * wind_rows)) # remember each pane consitutes a pixel

wind_width=$(( wind_cols * pane_cols + wind_cols - 1)) #| measured in characters
wind_height=$((wind_rows * pane_rows + wind_rows - 1)) #|

popup_width=$((wind_width + 2))   #| measured in characters
popup_height=$((wind_height + 2)) #|

validate_geometry $popup_width $popup_height ||
	error 6 'the media is too large for your terminal, try zooming out'

# Server Initialization --------------------------------------------------- {{{1

tmux -L $server -f /dev/null new -d -x $wind_width -y $wind_height

tmux -L $server source - << CONFIG

# replace the initial pane with a pane having no command running in it

	split-window -d ''; kill-pane

# prevent panes from closing when cmds exit, first window only

	set -w remain-on-exit on
	set -w remain-on-exit-format ''

# prevent the client from resizing the window

	set window-size manual

# cleanup after detaching

	set-hook -t=0: client-detached kill-server

# hide visual clutter

	set status off
	set pane-border-style fg=black
	set pane-active-border-style fg=black

CONFIG

# Grid Construction ------------------------------------------------------- {{{1

for ((i = 0, pane = 0; i < wind_rows; i++, pane++))
do
	if ((i != wind_rows - 1))
	then tmux -L $server splitw -t $pane -dvbl$pane_rows ''
	fi

	for ((j = 0; j < wind_cols - 1; j++, pane++))
	do tmux -L $server splitw -t $pane -dhbl$pane_cols ''
	done
done

# NOTE This is done afterwards to ensure that
# the commands start at approximately the same
# time.

if test -n "$cmd"
then
	for ((i = 0; i < pixels; i++))
	do tmux -L $server respawnp -t $i "$cmd"
	done
fi

tmux popup -w $popup_width -h $popup_height -E "tmux -L $server attach" &

# Image Handling ---------------------------------------------------------- {{{1

if test "$media_type" = image
then
	tar -xOf "$input" visual-data.tmux | tmux -L $server source -
	exit
fi

# Video Handling ---------------------------------------------------------- {{{1

# $media_type must be video if this is reached

frame_rendering_cmd="tmux -L $server source -"

if $frame_rate_synchronization_enabled
then
	frames_per_second=$(\
		tar -xOf "$input" meta-data.json | jq .frames_per_second)

	# frame_time  = 1 / frames_per_second * frame_rate_adjustment_factor
	# render_time = (determined on the fly)
	# delay_time  = frame_time - render_time

	precision=4

	frame_time=$(dc -e "$precision k
		1 $frames_per_second / $frame_rate_adjustment_factor * p q")

	render_time="\$(command time -f %e $frame_rendering_cmd 2>&1)"

	# NOTE we explicitly use the binary file 'time' as apposed to the shell
	# keyword 'time'.  Prefixing the word `time` with the shell builtin
	# `command` prevents it from being resolved as a shell keyword.  Try
	# 'type -a time' in bash for context.

	delay_time="\$(dc -e \"$precision k $frame_time $render_time - p q\")"

	frame_rendering_cmd="sleep -- $delay_time 2> /dev/null || exit 0"

	# NOTE $delay_time is negative when $render_time exceeds $frame_time.
	# The sleep command errors on negative durations. We need it to have a
	# successful exit status; otherwise, GNU split will exit prematurely.
	# Thus, we suppress stderr and force an exit code of zero.
fi

if $report_duration
then termination_cmd="tmux -L $server command-prompt -1p\$SECONDS kill-server"
else termination_cmd="tmux -L $server kill-server"
fi

frames=$(tar -xOf "$input" meta-data.json | jq .frames)

OoM=$(tar -xOf "$input" meta-data.json | jq .order_of_magnitude)

# TODO implement a frame seeking mechanism by injecting a head or tail command
# between the tar and split commands. You will need to adjust the progress bar
# logic by adding an offset to the current file index.

video_playback_cmd="
	tar -xOf '$input' visual-data.tmux |
		split -da$OoM -l $pixels --filter '
			$frame_rendering_cmd;
			echo \$(((10#\${FILE#x}+1) * 100 / $frames))' |
		whiptail --gauge 'Video Progress Bar...' 6 $((wind_width-4)) 0;
	$termination_cmd"

audio_playback_cmd="
	tar -xOf '$input' audio-data.mp3 |
		play -t mp3 - speed $tempo"

audio_visualization_cmd=cava

tmux -L $server neww -d "$video_playback_cmd"

if ! $mute
then
	tmux -L $server neww -d              "$audio_playback_cmd"
	tmux -L $server splitw -Zt0:2.0 "$audio_visualization_cmd"
fi

# Documentation ----------------------------------------------------------- {{{1

# https://charlotte-ngs.github.io/2015/01/BashScriptPOD.html
# http://bahut.alma.ch/2007/08/embedding-documentation-in-shell-script_16.html

: <<='cut'
=pod

=head1 NAME

view.sh - Tmux Bad Apple Media Viewer

=head1 SYNOPSIS

 bash view.sh [-hH] [-c <cmd>] [-p <NxM>] <image>
 bash view.sh [-hHdm] [-c <cmd>] [-p <NxM>] [-t <tempo>] [-s | -r <rate>] <video>

=head1 DESCRIPTION

This documentation is still under construction.

=head1 OPTIONS

=over

=item B<-h>

Display a [h]elp message and exit.

=item B<-H>

Display this documentation in a pager and exit after the user quits.  The
documentation is divided into sections.  Each section header is matched with a
search pattern, meaning that you can use navigation commands like C<n> and its
counterpart C<N> to go to the next or previous section respectively.

The uppercase -H is to parallel the lowercase -h.

=back

=head1 DIAGNOSTICS

The program exits with the following status codes.

=over

=item 0 if okay

=item 1 if dependencies are missing

=item 2 if the wrong number of positional arguments are passed

=item 3 if the input argument is not a file

=item 4 if the input file is not in the correct file format

=item 5 if this script is not run inside of a tmux client

=item 6 if the media is too large to display in the terminal

=item 7 if pane dimensions specified with B<-p> are invalid

=item 8 if frame rate adjustment factor specified with B<-r> is invalid

=item 9 if audio tempo specified with B<-t> is invalid

=back

=head1 AUTHOR

Zachary Krepelka L<https://github.com/zachary-krepelka>

=cut

# vim: tw=80 ts=8 sw=8 noet fdm=marker
