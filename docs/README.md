<!--
	FILENAME: README.md
	AUTHOR: Zachary Krepelka
	DATE: Saturday, November 1st, 2025
	ABOUT: Bad Apple!! but it's a terminal multiplexer
	ORIGIN: https://github.com/zachary-krepelka/tmux-bad-apple.git
	UPDATED: Friday, November 21st, 2025 at 5:10 AM
-->

# Tmux Bad Apple

![exhibit0.gif](exhibits/exhibit0.gif)

## Contents

- [Introduction](#introduction)
- [Background](#background)
- [Features](#features)
- [Flaws](#flaws)
- [Showcase](#showcase)
- [Requirements](#requirements)
- [Installation](#installation)
- [Overview](#overview)
- [Usage](#usage)
- [Configuration](#configuration)

## Introduction

`tmux-bad-apple` is a rudimentary, terminal-based image viewer and video player
implemented using [tmux][1], an open-source terminal multiplexer for \*nix
operating systems.  Only capable of rendering images and videos in low
resolutions, you wouldn't legitimately use this, although you might throw it in
your `~/.tmux.conf` as a party trick.  Rather, `tmux-bad-apple` was written as
an exercise in recreational programming with the self-imposed constraint that
every pixel must be a tmux pane.  For the unacquainted:

> tmux is a program which runs in a terminal and allows multiple other terminal
> programs to be run inside it.  Each program inside tmux gets its own terminal
> managed by tmux, which can be accessed from the single terminal where tmux is
> running - this called multiplexing and tmux is a terminal multiplexer.  ...
> Every terminal inside tmux belongs to one pane, this is a rectangular area
> which shows the content of the terminal inside tmux.  ...  Each pane appears
> in one window.  A window is made up of one or more panes which together cover
> its entire area - so multiple panes may be visible at the same time.

## Background

`tmux-bad-apple` is named after the video that it was initially implemented to
render.  [Bad Apple!!][2] is a fan-made promotional video for the Japanese
video-game franchise [Touhou][3]. The video is well-known on the internet and
has taken on a life of its own outside of its original context. In particular,
the video gave rise to [a popular internet challenge][4] where individuals reproduce
the animation through unconventional mediums, often (but not exclusively) via
computer programming.  Thereon, the [Wikipedia article][5] writes the following.

> The shadow-art video was ported to several second-generation video game
> consoles and graphing calculators--presumed to be incapable of playing back
> full-motion video--for retrocomputing demoscene competitions.  Peter Dell, a
> programmer who contributed to one such port, described the video as having
> become a graphical equivalent to "Hello, World!" programs.

This repository is my effort to participate in this challenge.

## Features

Here are the high points.

- renders images and videos
- has a (non-adjustable) video progress bar
- plays back audio and incorporates an audio visualizer
- provides customizable shortcuts to user-supplied media
- features command-line niceties for a well-rounded user experience
  - thorough error handling
  - command-line help messages
  - man-page-like reference documentation
- does not interfere with the user's existing tmux configuration and server
  state

## Flaws

For transparency, here are the low points.

- media has to be converted into a custom file format
  - user may have to wait for a loading bar to finish
- non-auto scaling
  - does not automatically adjust images and videos to fit the screen
  - the user has to think about what media size fits in their terminal
  - resizing media entails reconverting it from its source
- audio-visual synchronization is a matter of trial and error
  - the user has to 'adjust knobs' to get it right
- playback performance worsens with larger video resolutions

## Showcase

This section attempts to demonstrate the project and its features.

> [!IMPORTANT]
> Disclaimer: some of the GIFs presented in this README have been sped up and do
> not reflect actual playback performance.

> [!NOTE]
> To meet GitHub's filesize limit for gif playback, the following gifs do not
> play the full videos.

### Exhibit 1

This exhibit showcases a static image being rendered.  This is the same image
seen in Ben Eater's YouTube video [The world's worst video card?][7].

![exhibit1.gif](exhibits/exhibit1.gif)

### Exhibit 2

This exhibit showcases the video progress bar and the audio visualizer while
playing the [colored version of Bad Apple!!][8].  Wait until the end.

![exhibit2.gif](exhibits/exhibit2.gif)

### Exhibit 3

To drive home the point that each pixel is its own terminal, this exhibit
showcases the program [cmatrix][9] sunning in each pane.

![exhibit3.gif](exhibits/exhibit3.gif)

## Requirements

The following command identifies binaries required for this project that are
missing on your system.

```
make deps
```

Issue it in the repo's root after cloning.  Install any missing binaries with
your package manager.

> [!WARNING]
> This does not catch missing binaries required by the makefile itself.

For completeness, I enumerate *all* binaries used below in alphabetical order,
although some are not strictly nessecary.

> agg asciinema awk bash cat cava chmod column convert curl cut dc dirname
> ffmpeg ffprobe file gifsicle identify jq less ls mktemp mv play pod2text
> realpath rm sleep split tar time tmux touch tput tree wget whiptail

These are usually installed using the following identifiers to your package
manager.

- `imagemagik` will install `convert` and `identify`.
- `ffmpeg` will install `ffmpeg` and `ffprobe`.
- `sox` will install `play`.

The rest are installed by name if they are not already present on your system.

> [!WARNING]
> GNU variants of programs are preferred where applicable, e.g., prefer GNU awk
> to other implementations.  Compatibility is not promised for non-GNU program
> implementations.

## Installation

You are encouraged to clone this repository and mess around with it directly.
You will be dealing with command-line programs.

```bash
git clone https://github.com/zachary-krepelka/tmux-bad-apple.git
```

Once you have done this and understand how the project works, you can install it
persistently as a tmux plugin, either manually or using the [Tmux Plugin
Manager][10] platform.  Doing so will provide a convenience wrapper around a
shell script.  This is discussed further in the configuration section.

### Automated installation

With the Tmux Plugin Manager installed, all you have to do is write the
following line to your `~/.tmux.conf` and subsequently press `prefix + I` from
within tmux.  This will handle the installation for you.

```tmux.conf
set -g @plugin 'zachary-krepelka/tmux-bad-apple'
```

### Manual installation

Clone this repo into a directory of your choice, say
`~/.tmux/plugins/bad-apple`.

```bash
git clone https://github.com/zachary-krepelka/tmux-bad-apple.git ~/.tmux/plugins/bad-apple
```

Add this line to your `~/.tmux.conf`, changing the directory accordingly.

```tmux.conf
run-shell ~/.tmux/plugins/bad-apple/bad-apple.tmux
```

Reload the tmux configuration file by typing `tmux source-file ~/.tmux.conf`.

## Overview

Two major shell scripts comprise the backbone of this project. They are
user-facing, command-line programs.

1. `view.sh` is the actual image viewer / video player.  However, it only
   accepts a custom file format.

2. `conv.sh` converts an existing image or video into a file format that
   `view.sh` can understand.

A command-line help message is obtained for either script by passing the `-h`
flag.  Complete reference documentation for either script can be read in the
terminal by passing the `-H` flag.  That's a capital H.

> [!TIP]
> This README file intends to introduce the project altogether, but it does not
> explain every detail.  You should consult the reference documentation to
> understand how each script operates.  Note that the reference documentation is
> still under construction.

You can learn about the other files by typing `make tree`, but that is
unnecessary.

## Getting Started

You can test the waters by trying the demos.  This alleviates the immediate need
to acquire your own media files.

1. `make demo1` shows a picture of a bird
2. `make demo2` plays bad apple
3. `make demo3` plays bad apple in color

To use your own media files, follow these steps.

1. Acquire an image or a video, say `flower.jpg`.

2. Convert the image into a tmux media file.

   ```bash
   bash conv.sh flower.jpg flower.tpic
   ```

   Here `tpic` is a custom file extension. You can think of it as standing for
   *tmux picture*. A video would have the extension `tvid` for *tmux video*.  Of
   course, the extension is not mandatory, but it will help you differentiate
   the file from others.

3. Open the converted file with the tmux media viewer.

   ```bash
   bash view.sh flower.tpic
   ```

    A popup will appear displaying the image.  You can close it by pressing
    `prefix + d`.  Videos close automatically when playback ends, but you can
    dismiss the popup early by pressing `prefix + d` as well.  For a video, you
    can also use `prefix + n` and `prefix + p` to cycle through the video
    progress bar, the audio visualizer, and the video player itself.

4. Optionally, configure your `~/.tmux.conf` to open this media file with a
   quick-access key binding if you intend to have it on hand in the future.  See
   the configuration section for details.

You may notice that the resulting image is very small. This is an intentional
design decision to ensure that the image will fit in your terminal.  You can
change the size of an image or video with the `-s NUM` flag to `conv.sh`. Here
`s` actually stands for *scale* rather than *size*.  The scale of an image or
video is a parameter that specifies that media's width-and-height dimension as
an integer  multiple of that media's aspect ratio.  By default, `conv.sh`
outputs media with a scale of one.  Here is a table that breaks this down for
some common aspect ratios. A script is provided to generate this table for any
aspect ratio if yours is not listed.

<!-- Read from this pipeline as a starting point.

echo -e '1:1\n4:3\n16:9' |
  awk -f scripts/utils/aspect-scaler.awk |
  column -t -o ' | '

-->

| r\s  | 1    | 2     | 3     | 4     | 5     | 6     | 7      | 8      | 9      |
|------|------|-------|-------|-------|-------|-------|--------|--------|--------|
| 1:1  | 1x1  | 2x2   | 3x3   | 4x4   | 5x5   | 6x6   | 7x7    | 8x8    | 9x9    |
| 4:3  | 4x3  | 8x6   | 12x9  | 16x12 | 20x15 | 24x18 | 28x21  | 32x24  | 36x27  |
| 16:9 | 16x9 | 32x18 | 48x27 | 64x36 | 80x45 | 96x54 | 112x63 | 128x72 | 144x81 |

> [!NOTE]
> Since each pixel is a tmux pane with a certain number of rows and columns, the
> actual character dimension of the popup window will be much larger.

## Usage

Here is the command-line help message for `conv.sh`.

<!-- read !bash scripts/conv.sh -h -->

```text
Tmux Bad Apple Media Converter

Usage:
  bash conv.sh [options] <input> <output>

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
  bash conv.sh finch.png finch.tpic
  bash conv.sh -a -s 3 bad-apple.webm bad-apple.tvid
```

Here is the command-line help message for `view.sh`.

<!-- read !bash scripts/view.sh -h -->

```text
Tmux Bad Apple Media Viewer

Usage:
  bash view.sh [-hH] [-c <cmd>] [-p <NxM>] <image>
  bash view.sh [-hHdm] [-c <cmd>] [-p <NxM>] [-t <tempo>]
               [-s | -r <rate>] <video>

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
  bash view.sh finch.tpic
  bash view.sh -ms bad-apple.tvid
```

The `makefile` also has a command-line help mesage.

<!-- read! make help -->

```text
Usage:
  make [target]

Targets:
  help      display this help message
  deps      check for missing dependencies
  tree      present documentation on each file
  demo1     show a picture of a bird
  demo2     play bad apple
  demo3     play bad apple in color
  keybinds  set up quick-access shortcuts for each demo
  readme    generate embedded media for the README file
  clean     remove intermediate files
  destroy   remove end deliverables
```

## Configuration

This project includes a supplemental wrapper around `view.sh` that allows it to
be invoked on predefined media using tmux keybinds.  This enables the project to
be distributed as a tmux plugin managed by the tmux plugin manager.  However, it
is not enough to install the plugin this way.  You have to clone the repository
and work with its command-line programs in advance to configure its use as a
plugin.

Once you have created a tmux media file using `conv.sh`, either an image or a
video, you can map it to one of nine shortcuts.  These are `prefix + a 1` all
the way up to `prefix + a 9`, which would be typed by pressing the prefix key,
then the letter `a`, and then a number[^1].  The reason I chose this key
sequence is because when the default prefix key of `C-b` is used, the sequence
becomes `C-b a [n]`, which can be mnemonized as `b`ad `a`pple.  I call these
quick access keys, and by default, all nine are unmapped to.

You can map a tmux media file to a quick-access key by assigning the path of
that media file to one of nine variables in your `~/.tmux.conf`.  These are
`@media1` all the way up to `@media9`.  Flags to `view.sh` can be stored in
`@mediaconf1` up to `@mediaconf9`.

To continue our example from the getting started section, suppose that we have a
tmux media file called `flower.tpic`. Here are the steps we can take to map this
file to one of our  quick access keys, let's say `prefix + a 1`.

1. Ensure this project is installed as a tmux plugin by following the
   installation instructions.

2. Put the file `flower.tpic` in a persistant location and note its absolute
   path.  You might put it in the media folder that was cloned along with this
   repo, but that is up to you.

3. Add a line like this one to your `~/.tmux.conf`.  Change the path
   accordingly.

   ```tmux
   set -g @media1 /absolute/path/to/flower.tpic
   ```

   You can also set an option `@mediaconf1` to contain command-line options to
   `view.sh`, but this is more relevant for videos to configure the audio tempo
   and frame rate syncroniaztion factor on a video-by-video basis.

4. Resource your configuration file with this command to your shell.

   ```bash
   tmux source-file ~/.tmux.conf
   ```

5. Give it a try with `prefix + a 1`.

On one final note, there is also `prefix + a 0` which prompts for an arbitrary
media file to play relative to the current directory.

<!-- References -->

[^1]: This is analogous to the `prefix + [n]` used to select a window by index.

[1]: https://en.wikipedia.org/wiki/Tmux
[2]: https://www.youtube.com/watch?v=FtutLA63Cp8
[3]: https://en.wikipedia.org/wiki/Touhou_Project
[4]: https://www.google.com/search?q=bad+apple+but&udm=7
[5]: https://en.wikipedia.org/wiki/Bad_Apple!!
[6]: https://asciinema.org
[7]: https://www.youtube.com/watch?v=l7rce6IQDWs
[8]: https://www.youtube.com/watch?v=iV5A-VzKWvw
[9]: https://github.com/abishekvashok/cmatrix
[10]: https://github.com/tmux-plugins/tpm
