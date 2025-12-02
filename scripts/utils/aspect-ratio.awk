#!/usr/bin/env -S awk -f

# FILENAME: aspect-ratio.awk
# AUTHOR: Zachary Krepelka
# DATE: Sunday, November 2nd, 2025
# USAGE: echo 1920x1080 | awk -f aspect-ratio.awk
# ORIGIN: https://github.com/zachary-krepelka/tmux-bad-apple.git

function gcd(a, b) {
	while (b != 0) {
		tmp = b
		b = a % b
		a = tmp
	}
	return a
}

# https://en.wikipedia.org/wiki/Greatest_common_divisor#Euclidean_algorithm

BEGIN {
	 FS="x"
	OFS=":"
}

{
	width  = $1
	height = $2

	reduced_width  =  width  / gcd(width, height)
	reduced_height =  height / gcd(width, height)

	print reduced_width, reduced_height
}
