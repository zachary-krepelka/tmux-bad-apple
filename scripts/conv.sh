#!/usr/bin/env bash

# FILENAME: conv.sh
# AUTHOR: Zachary Krepelka
# DATE: Tuesday, October 28th, 2025
# ABOUT: Tmux Bad Apple Media Converter
# ORIGIN: https://github.com/zachary-krepelka/tmux-bad-apple.git
# UPDATED: Tuesday, January 6th, 2026 at 2:13 AM

# Functions --------------------------------------------------------------- {{{1

program="${0##*/}"

usage() {
	cat <<-USAGE
	Tmux Bad Apple Media Converter

	Usage:
	  bash $program [options] <input> <output>

	  where <input> is [<image> | <video>]

	Options:
	  -s NUM  specifies the [s]cale of the output media
	  -f      [f]orcibly overwrite existing output file
	  -a      alert when done
	          relevant for videos which take longer

	Documentation:
	  -h  display this [h]elp message and exit
	  -H  read documentation for this script then exit

	Examples:
	  bash $program finch.png finch.tpic
	  bash $program -a -s 3 bad-apple.webm bad-apple.tvid
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

check_external_dependencies() {

	local missing= dependencies=(
		awk cat convert cut dirname
		ffmpeg ffprobe file identify jq
		less mktemp pod2text rm tar tput
		whiptail
	)

	for cmd in "${dependencies[@]}"
	do
		if ! command -v "$cmd" &>/dev/null
		then missing+="$cmd, "
		fi
	done

	if test -n "$missing"
	then error 1 "missing dependencies: ${missing%, }"
	fi
}

check_internal_dependencies() {

	local missing= dependencies=(
		utils/ppm2tmux.awk
		utils/aspect-ratio.awk
	)

	for file in "${dependencies[@]}"
	do
		if ! test -f "$location/$file"
		then missing+="${file##*/}, "
		fi
	done

	if test -n "$missing"
	then error 2 "missing comfiponents: ${missing%, }"
	fi
}

cleanup() {
	rm -rf "$workspace"
}

# Precondition Checks ----------------------------------------------------- {{{1

check_external_dependencies # must be called before any external command

location="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

check_internal_dependencies # declaration of $location must be sandwiched

# Command-line Argument Parsing ------------------------------------------- {{{1

alert=false
force=false
scale=1

while getopts 'hHa2fs:' option
do
	case "$option" in
		h) usage; exit 0;;
		H) documentation; exit 0;;
		a) alert=true;;
		f) force=true;;
		s)
			if [[ $OPTARG =~ ^[1-9][0-9]*$ ]]
			then scale=$OPTARG
			else error 3 '-s expects a natural number'
			fi
		;;
	esac
done

shift $((OPTIND-1))

if test $# -ne 2
then error 4 'exactly two arguments are required'
fi

input="$1" output="$2"

if ! test -f "$input"
then error 5 'input is not a file'
fi

if ! $force && test -f "$output"
then error 6 'output file exists, use -f to overwrite'
fi

# Main Processing --------------------------------------------------------- {{{1

workspace="$(mktemp -d)"

media_type="$(file -b --mime-type "$input" | cut -d/ -f1)"

if test "$media_type" = image
then
	aspect_ratio=$(identify -format %wx%h "$input" |
		awk -f "$location/utils/aspect-ratio.awk")

	width=$(( scale * $(cut -d: -f1 <<< $aspect_ratio)))
	height=$((scale * $(cut -d: -f2 <<< $aspect_ratio)))

	convert "$input" -compress none -resize ${width}x$height ppm:- 2>/dev/null |
		awk -f "$location/utils/ppm2tmux.awk" \
			> "$workspace/visual-data.tmux"

	cat <<-JSON > "$workspace/meta-data.json"
	{
	  "medium": "image",
	  "width": $width,
	  "height": $height
	}
	JSON

elif test "$media_type" = video
then
	ffprobe \
		-v quiet \
		-print_format json \
		-show_streams \
		-select_streams v:0 \
		-count_packets \
		"$input" |
	jq \
		--arg scale $scale \
		-f "$location/utils/make-meta.jq" \
			> "$workspace/meta-data.json"

	OoM=$(jq .order_of_magnitude "$workspace/meta-data.json")

	echo please wait

	# TODO document exit codes

	ffmpeg -v quiet -i "$input" "$workspace/frame-%0${OoM}d.png" || exit 126
	ffmpeg -v quiet -i "$input" -vn "$workspace/audio-data.mp3"  || exit 125

	geometry=$(jq -r '"\(.width)x\(.height)"' "$workspace/meta-data.json")
	total_iterations=$(jq .frames "$workspace/meta-data.json")
	current_iteration=0

	for frame in "$workspace"/frame*
	do
		percentage=$((++current_iteration * 100 / total_iterations))

		echo $percentage

		# TODO functionize this, since you use it twice

		convert "$frame" -resize $geometry -compress none ppm:- 2>/dev/null |
			awk -f "$location/utils/ppm2tmux.awk" \
					>> "$workspace/visual-data.tmux"

		rm "$frame"

	done | whiptail --gauge "Processing Video Frames..." 6 50 0

else
	cleanup
	error 7 'input file is not an image or video'
fi

tar -c --xform 'sd.*/dd' -f "$output" "$workspace"/* 2> /dev/null

cleanup # TODO trap this

if $alert
then tput bel
fi

# Documentation ----------------------------------------------------------- {{{1

# https://charlotte-ngs.github.io/2015/01/BashScriptPOD.html
# http://bahut.alma.ch/2007/08/embedding-documentation-in-shell-script_16.html

: <<='cut'
=pod

=head1 NAME

conv.sh - Tmux Bad Apple Media Converter

=head1 SYNOPSIS

 bash conv.sh [options] <input> <output>

 where <input> is [<image> | <video>]

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

=item 2 if components are missing

=item 3 if B<-s> received an invalid option argument

=item 4 if the wrong number of positional arguments are passed

=item 5 if the input argument is not a file

=item 6 if the output argument already exists as a file

=item 7 if the input file is not an image or video

=back

=head1 AUTHOR

Zachary Krepelka L<https://github.com/zachary-krepelka>

=cut

# vim: tw=80 ts=8 sw=8 noet fdm=marker
