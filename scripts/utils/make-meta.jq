#!/usr/bin/env -S jq --arg scale 1 -f

# FILENAME: make-meta.jq
# AUTHOR: Zachary Krepelka
# DATE: Friday, October 31st, 2025
# USAGE: ffprobe -v quiet
#                -print_format json
#                -show_streams
#                -select_streams v:0
#                -count_packets $video | ./make-meta.jq
# ORIGIN: https://github.com/zachary-krepelka/tmux-bad-apple.git

def digits(number):
	number | log10 | floor | . + 1;

def extract(ratio; delim; term):
	ratio | split(delim) | .[term] | tonumber;

def numerify(ratio; delim):
	ratio | split(delim) | map(tonumber) | .[0] / .[1] | round;

.streams[0].display_aspect_ratio as $aspect_ratio |
(.streams[0].nb_read_packets | tonumber) as $frames |
($scale | tonumber) as $scale |
{
	media: "video",
	width: (extract($aspect_ratio; ":"; 0) * $scale),
	height: (extract($aspect_ratio; ":"; 1) * $scale),
	frames: $frames,
	order_of_magnitude: digits($frames),
	frames_per_second: numerify(.streams[0].avg_frame_rate; "/"),
	frame_rate_adjustment_factor: 1
}
