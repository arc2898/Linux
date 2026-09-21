# termimg-go

A terminal-based image and video viewer for Linux, rendering media directly in the terminal using ANSI escape sequences and Unicode characters. Built with Go and ffmpeg for lightweight, portable media viewing without a graphical backend.

## Overview

`termimg-go` enables viewing images and videos directly in the terminal. It supports:

- **Image rendering**: Truecolor, 256-color, and ASCII modes
- **Video playback**: Frame-by-frame decoding via ffmpeg with play/pause, seek, and speed control
- **Terminal integration**: Raw keyboard input, automatic terminal size detection, and seamless rendering
- **Cross-terminal compatibility**: Automatic color mode detection (truecolor → 256-color → ASCII fallback)

## Features

| Feature | Description |
|---|---|
| **Image modes** | Auto/truecolor/256-color/ASCII rendering with adaptive color palettes |
| **Video playback** | Seek, play/pause, speed control (0.25×–4×), loop support |
| **Keyboard controls** | Full navigation via vi-style keys (h/j/k/l, space, q, etc.) |
| **Terminal aware** | Automatic resize handling, dynamic canvas fitting |
| **No external Go deps** | Single binary, easy to build and deploy |
| **Format support** | Images: JPEG, PNG, GIF, BMP, TIFF; Videos: MP4, MKV, WebM, MOV, AVI, and more |

## Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| OS | Linux | Linux (any distro) |
| Terminal | Any ANSI-capable terminal | Truecolor-capable (e.g., foot, alacritty, kitty, wezterm) |
| Go | 1.22+ | Latest stable |
| ffmpeg | Required for video | Latest stable (with common codecs) |
| ffprobe | Required for video metadata | Included with ffmpeg |

### Debian/Ubuntu setup

```sh
sudo apt update
sudo apt install ffmpeg golang-go
```
### Build from Source

```sh

go build -trimpath -ldflags='-s -w' -o termimg-go .
```
### Install locally

```sh

install -Dm755 termimg-go "$HOME/.local/bin/termimg-go"
```
### Install system-wide

```sh

sudo install -Dm755 termimg-go /usr/local/bin/termimg-go
```
### Usage
## Basic invocation

```sh

./termimg-go
./termimg-go photo.jpg
./termimg-go clip.mp4
./termimg-go photo.jpg clip.mp4 another.png
```
### Directory mode

```sh

./termimg-go ./media
```
# Plays all supported media files in the directory, in lexicographic order.
Command-line options
Option	Description	Default
--loop	Loop videos and wrap navigation at ends	false
--fps N	Override video frame rate (frames/sec)	0 (auto-probe)
--mode MODE	Renderer: auto, color256, color, ascii	auto
--help	Show usage summary	—
## Examples

```sh

# Play video with loop
./termimg-go --loop clip.mp4

# Force truecolor rendering
./termimg-go --mode color photo.jpg

# Override FPS for variable-rate files
./termimg-go --fps 30 clip.mp4

# ASCII-only mode for capture logs or basic terminals
./termimg-go --mode ascii photo.jpg
```
## Controls
# Key	Action
q, Esc	Quit application
h, H, p, P	Previous media
l, L, n, N, Enter	Next media
Space	Play / pause video
0	Restart current video
+, =	Increase playback speed (max 4×)
-, _	Decrease playback speed (min 0.25×)
r, R	Re-read terminal dimensions
c	Cycle render mode (auto → color256 → color → ascii → loop)
## Image mode

    Images display once and remain paused
    Fits within terminal while preserving aspect ratio
    Use c to cycle through render modes

## Video mode

    Press Space to play/pause
    Use 0 to seek to start
    +/- adjust speed
    Position seek: scroll through frames; use r after seeking if display seems stale

## Supported Formats
# Images

JPEG, PNG, GIF, BMP, TIFF (including BigTIFF)
# Videos

MP4, MKV, WebM, MOV, AVI, M4V, FLV, WMV, MPEG, TS, 3GP, OGV

Actual codec support depends on the installed ffmpeg build.
Configuration

The application auto-detects terminal capabilities:

    COLORTERM env var: truecolor/24bit → truecolor mode
    TERM env var: 256color → 256-color mode
    Falls back to ASCII for basic terminals

Force a specific mode with --mode color256, --mode color, or --mode ascii.
Development
Prerequisites

    Go 1.22+
    ffmpeg and ffprobe in PATH
    Git (for cloning)

### Build & test

```sh

go fmt ./...
go vet ./...
go test ./...
```
### Directory structure

text

termimg/
├── main.go          # Entry point and application logic
├── go.mod           # Module definition
├── termimg-go.md    # Additional documentation (transcluded above)
└── README.md        # This file

## Releasing

```sh

GOOS=linux GOARCH=amd64 go build -trimpath -ldflags='-s -w' -o termimg-go-linux-amd64
```
## License

Unless a LICENSE file is present in this repository, this project is provided as-is for educational and personal use. See the source code headers for any embedded third-party notices (e.g., ffmpeg GPL linking).

Built with Go. Depends on ffmpeg for video decoding. Designed for maximum portability across Linux terminals.
