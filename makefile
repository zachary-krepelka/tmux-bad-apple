# FILENAME: makefile
# AUTHOR: Zachary Krepelka
# DATE: Sunday, November 2nd, 2025
# ABOUT: Bad Apple!! but it's a terminal multiplexer
# ORIGIN: https://github.com/zachary-krepelka/tmux-bad-apple.git
# UPDATED: Friday, February 27th, 2026 at 9:31 PM

# Variables --------------------------------------------------------------- {{{1

DIMEN_0 := 132x43
SCALE_0 := 6
SPEED_0 := 5

DIMEN_1 := 132x43
SCALE_1 := 6
SPEED_1 := 1

DIMEN_2 := 132x43
SCALE_2 := 6
SPEED_2 := 6

DIMEN_3 := 132x43
SCALE_3 := 2
SPEED_3 := 3

# BA stands for bad apple
# IA stands for internet archive
# 3D stands for three-dimensional

BA_IA_ID     := bad-apple-resources
BA_IA_FILE   := bad_apple.mp4
BA3D_IA_ID   := Touhou_Bad_Apple_3D_Animated_
BA3D_IA_FILE := Touhou_Bad_Apple_3D_Animated_-pLmx6_I1PPQ.mp4

# On some systems, agg is installed as asciinema-agg.

AGG := $(shell command -v agg || command -v asciinema-agg)

# Rules ------------------------------------------------------------------- {{{1

.PHONY: help
help:
	@## display this help message
	@awk -f scripts/utils/makefile-documenter.awk $(MAKEFILE_LIST)

.PHONY: deps
deps:
	@## check for missing dependencies

	@# The command-line programs in this repository will report an
	@# error if a dependency is missing.  We can check for missing
	@# binaries by doing a dry run of each program.  If we pass the
	@# `-h` flag for help and receive an error instead, then we
	@# know that something is missing.  Note that the help message
	@# is printed to stdout, whereas errors are printed to stderr.

	@bash scripts/conv.sh -h > /dev/null || true
	@bash scripts/view.sh -h > /dev/null || true
	@bash docs/exhibits/playwright.sh -h > /dev/null || true

	@# Note that this does not catch binaries required by this makefile.

.PHONY: tree
tree:
	@## present documentation on each file
	tree -C --filesfirst --infofile=docs/project.info | less -RS +k

.PHONY: demo1
demo1: media/finch.tpic
	@## show a picture of a bird
	bash scripts/view.sh $<

media/finch.tpic: media/finch.png
	bash scripts/conv.sh -fs6 $< $@

media/finch.png: | media
	wget -qP media https://eater.net/downloads/finch.png

media:
	mkdir -p media

.PHONY: demo2
demo2: media/bad-apple.tvid
	@## play bad apple
	bash scripts/view.sh $<

media/bad-apple.tvid: media/bad-apple.mp4
	bash scripts/conv.sh -fas3 $< $@

media/bad-apple.mp4: tools/ia | media
	./tools/ia download --no-directories $(BA_IA_ID) $(BA_IA_FILE)
	mv $(BA_IA_FILE) $@ && touch $@

tools/ia: | tools
	# https://archive.org/developers/internetarchive/cli.html
	curl -LOs --output-dir tools https://archive.org/download/ia-pex/ia
	chmod +x tools/ia

tools:
	mkdir -p tools

.PHONY: demo3
demo3: media/bad-apple-3d.tvid
	@## play bad apple in color
	bash scripts/view.sh $<

media/bad-apple-3d.tvid: media/bad-apple-3d.mp4
	bash scripts/conv.sh -fas3 $< $@

media/bad-apple-3d.mp4: tools/ia | media
	./tools/ia download --no-directories $(BA3D_IA_ID) $(BA3D_IA_FILE)
	mv $(BA3D_IA_FILE) $@ && touch $@

.PHONY: keybinds
keybinds: media/finch.tpic media/bad-apple.tvid media/bad-apple-3d.tvid

	@## set up quick-access shortcuts for each demo

	# Just a demonstration. You should define your own in ~/.tmux.conf.
	# Use absolute paths unless relative to the root of this project.

	bash bad-apple.tmux

	tmux set -g @media1 media/finch.tpic        # prefix + a 1
	tmux set -g @media2 media/bad-apple.tvid    # prefix + a 2
	tmux set -g @media3 media/bad-apple-3d.tvid # prefix + a 3

	tmux set -g @mediaconf2 '-s'
	tmux set -g @mediaconf3 '-s'

.PHONY: readme
readme: $(foreach i,0 1 2 3,docs/exhibits/exhibit$(i).gif)
	@## generate embedded media for the README file
	# each gif must be under 10 MB to play on GitHub
	ls -lh $^

docs/exhibits/exhibit%.gif: docs/exhibits/exhibit%.cast
	$(AGG) --speed $(SPEED_$*) $< $@
	gifsicle --optimize=3 --batch $@

# .PRECIOUS: docs/exhibits/exhibit%.cast # uncomment to keep casts
docs/exhibits/exhibit%.cast: docs/exhibits/exhibit%.script docs/exhibits/recording.tmux.conf
	bash $(@D)/playwright.sh -f -c $(@D)/recording.tmux.conf -d $(DIMEN_$*) $< $@

docs/exhibits/exhibit0.script: media/exhibit0.tvid
docs/exhibits/exhibit1.script: media/exhibit1.tpic
docs/exhibits/exhibit2.script: media/exhibit2.tvid
docs/exhibits/exhibit3.script: media/exhibit3.tvid

media/exhibit0.tvid: media/bad-apple.mp4
	bash scripts/conv.sh -fas$(SCALE_0) $< $@

media/exhibit1.tpic: media/finch.png
	bash scripts/conv.sh -fs$(SCALE_1) $< $@

media/exhibit2.tvid: media/bad-apple-3d.mp4
	bash scripts/conv.sh -fas$(SCALE_2) $< $@

media/exhibit3.tvid: media/bad-apple.mp4
	bash scripts/conv.sh -fas$(SCALE_3) $< $@

.PHONY: clean
clean:
	@## remove intermediate files
	rm -rf media tools

.PHONY: destroy
destroy:
	@## remove end deliverables
	rm -f docs/exhibits/*.gif

# vim: tw=80 ts=8 sw=8 noet fdm=marker
