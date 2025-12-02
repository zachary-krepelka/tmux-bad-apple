#!/usr/bin/env -S awk -f

# FILENAME: makefile-documenter.awk
# AUTHOR: Zachary Krepelka
# DATE: Saturday, November 22nd, 2025
# USAGE: awk -f makefile-documenter.awk makefile
# ORIGIN: https://github.com/zachary-krepelka/tmux-bad-apple.git

################################################

# There is a Stack Overflow post which discusses
# how to document a makefile.
#
#	https://stackoverflow.com/a/47107132
#
# It proposes to document makefiles in this
# fashion, using sed to extract the docs.
#
#	target: prerequisites ## documentation
#		recipe
#
# I do not like this approach because it does
# not respect the 80 column rule.  Putting the
# documentation string on the same line as the
# target and prerequisites can lead to long
# lines, which is undesirable.  Here is my
# revised approach.
#
#	target: prerequisites
#		@## documentation
#		recipe

################################################

match($0, /^([a-z0-9\/\-\.]+):/, capture) {
	target = capture[1]
	flag = 1
	next
}

flag {
	if (match($0, /^\t@## (.*)$/, capture)) {
		targets[++n] = target
		comments[n] = capture[1]
		flag = 0
	}
}

BEGIN {
	printf "Usage:\n  make [target]\n\nTargets:\n"
}

END {
	pad = 0
	for (i = 1; i <= n ; i++) {
		len = length(targets[i])
		if (len > pad)
			pad = len
	}
	for (i = 1; i <= n ; i++)
		printf "  %-" pad "s  %s\n", targets[i], comments[i]
}
