<!--
	FILENAME: DESIGN.md
	AUTHOR: Zachary Krepelka
	DATE: Saturday, November 8th, 2025
	ABOUT: Bad Apple!! but it's a terminal multiplexer
	ORIGIN: https://github.com/zachary-krepelka/tmux-bad-apple.git
	UPDATED: Monday, December 1st, 2025 at 10:01 PM
-->

# Design

This document outlines my design for this project.

## Starting

The user must be in a tmux client. When the user runs the program:

- a popup opens in the user's client
- a new tmux server starts with one session
- that session is attached in the popup

Creating a separate server ensures that we do not interfere with the
user's default server and its configuration.

## Stopping

- the user can dismiss the popup with `CTRL + D`
- the popup automatically closes when video playback ends
- the dedicated server terminates when the popup closes

## Watchmaker Analogy

A watchmaker creates a timepiece and winds it into motion but remains
uninvolved in its affairs thereafter.  This program should function like
a watchmaker.  It should terminate as soon as the popup is launched,
while allowing the popup to continue video playback thereafter.  The
rendering process for videos should be tied to the popup's nested
client, not to the program itself.  The program simply sets up and
spawns that process.  A similar behavior should be entailed for images.

## Images

When the input to the program is an image:

- the session will contain one window
- the window is split into a grid of panes, with each pane constituting
  a pixel
- the rendering logic is handled in the same process as the program
- the pop up stays open until the user detaches the nested client, but
  the program terminates as soon as rendering is complete

## Videos

When the input to the program is a video:

- the session will contain three windows
  - The first window displays the video. It is split into a grid of
    panes, with each pane constituting a pixel.
  - The second window contains the process that handles the render
    logic.
    - It contains a video progress bar, which serves as a visual
      front-end to the rendering process.
  - The third window contains the process that plays the video's audio.
    - A second pane contains an audio visualizer and it is zoomed in.
- because the render logic process is handed off into a tmux pane, the
  script exits as soon as this setup is complete.
- after delegating these processes to the tmux server, the script exits
  while the pop up stays open until either
  - the user detaches the nested client, or
  - the video comes to an end.

## File Format

The program reads a custom file format. It is a tarball with the
following files.

- `meta-data.json` which contains information essential to processing
- `visual-data.tmux` which encodes the image/video in tmux's
  configuration language
- `audio-data.mp3` if the media type is a video
