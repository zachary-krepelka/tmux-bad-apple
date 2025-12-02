#!/usr/bin/env -S awk -f

# FILENAME: aspect-scaler.awk
# AUTHOR: Zachary Krepelka
# DATE: Friday, November 28th, 2025
# USAGE: awk -f aspect-scaler.awk aspect-ratios.txt | column -t
# ORIGIN: https://github.com/zachary-krepelka/tmux-bad-apple.git

BEGIN {
	FS  = ":"

	# Provide default values when unspecified on the command line

	if (min < 1)
		min = 1

	if (max < 1)
		max = 9

	# Print out the column headings of a table

	printf "r\\s" # dual-label corner cell: aspect [r]atio per [s]cale

	for (scale = min; scale <= max; scale++)
		printf " %d", scale

	printf "\n"
}
{
	ratio  = $0
	width  = $1
	height = $2

	# Print out each row of the table

	printf "%s", ratio

  	for (scale = min; scale <= max; scale++) {

		printf " %sx%s", scale * width, scale * height

	}

	printf "\n"
}
