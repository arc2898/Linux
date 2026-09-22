# tview-go: Complete Instructions

## 1. What This Project Does

`tview-go` is a Linux terminal viewer for images and videos. It draws media directly into an ANSI-compatible terminal instead of opening a graphical window.

The program is a single Go package with no external Go dependencies. It uses the Go standard library for image decoding, terminal input, file discovery, timing, and ANSI output. It uses the external `ffmpeg` and `ffprobe` commands for video decoding and video metadata.

The executable can:

- Open one image, one video, or several media files.
- Read supported files from a directory, one directory level at a time.
- Show images using truecolor ANSI output, 256-color ANSI output, or grayscale ASCII.
- Play videos by repeatedly asking `ffmpeg` for one PNG frame at a time.
- Move between media files with keyboard commands.
- Pause, restart, loop, and change the playback speed of videos.
- Fit rendered media to the current terminal dimensions while preserving the aspect ratio.

The project does not use a graphical backend, terminal image protocol, hardware video decoder, or Go package manager dependency beyond the standard library.

## 2. Repository Contents

| File | Purpose |
|---|---|
| `main.go` | Complete application source, including discovery, decoding, rendering, input, and playback. |
| `go.mod` | Defines the module as `github.com/manus-ai/tview-go` and requires Go 1.22 or newer. |
| `README.md` | Short project overview and usage reference. |
| `tview-go.md` | Earlier project documentation with build and usage notes. |
| `FULL_INSTRUCTIONS.md` | Detailed instructions and source-level behavior reference. |
| `tview-go` | A prebuilt Linux x86-64 executable, when present. It is not required if the program is built from source. |

The Git checkout may also contain changes outside this directory. Do not remove or restore unrelated changes when working on this project.

## 3. Requirements

### Operating system

The program is designed for Linux. It relies on the `stty` command and Unix terminal behavior for raw keyboard input and terminal-size detection.

### Go

Go 1.22 or newer is required by `go.mod`.

Check the installed version:

```sh
go version
```

### Runtime commands

`ffmpeg` and `ffprobe` must both be available on `PATH`, even when opening only an image. The program checks for both commands during startup before it loads any media.

On Debian or Ubuntu:

```sh
sudo apt update
sudo apt install ffmpeg
```

The Debian and Ubuntu `ffmpeg` package normally provides both `ffmpeg` and `ffprobe`.

Verify them with:

```sh
command -v ffmpeg
command -v ffprobe
ffmpeg -version
ffprobe -version
```

### Terminal

Run the program in an interactive terminal. It must be able to:

- Accept ANSI escape sequences.
- Accept one-byte keyboard input.
- Support the `stty` command.
- Display Unicode half-block characters for color rendering.

A truecolor terminal gives the best result. A terminal advertising `256color` can use the 256-color renderer. A basic terminal can use ASCII mode.

## 4. Building From Source

Change to the project directory first:

```sh
cd /workspaces/Linux/tview
```

Build a development binary:

```sh
go build -o tview-go .
```

Build a smaller, reproducible-style release binary:

```sh
go build -trimpath -ldflags='-s -w' -o tview-go .
```

The `-o tview-go` option writes the executable into the project directory. The source package is named `main`, so the output name is chosen by the `-o` option rather than by the module name.

Install the binary for the current user:

```sh
install -Dm755 tview-go "$HOME/.local/bin/tview-go"
```

Make sure the local binary directory is on `PATH`:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

To install system-wide:

```sh
sudo install -Dm755 tview-go /usr/local/bin/tview-go
```

Confirm the installed command:

```sh
tview-go --help
```

## 5. Running the Viewer

The executable requires at least one path argument.

Open one image:

```sh
./tview-go photo.jpg
```

Open one video:

```sh
./tview-go clip.mp4
```

Open several files:

```sh
./tview-go photo.jpg clip.mp4 another.png
```

Open the supported media files in a directory:

```sh
./tview-go ./media
```

Directory discovery is not recursive. Files in nested subdirectories are ignored. Files are sorted lexicographically after all command-line paths have been expanded.

Paths containing spaces should be quoted:

```sh
./tview-go "holiday photos/photo 01.jpg"
```

The command-line help is available without opening media:

```sh
./tview-go --help
```

If no path is supplied, the program prints usage information and exits with status 2. If paths are supplied but no recognized media files are found, it exits with an error.

## 6. Command-Line Options

### `--loop`

Loop the current video after it reaches its duration:

```sh
./tview-go --loop clip.mp4
```

Without `--loop`, playback stops on the final decoded position. Previous and next navigation always wraps around the media list; `--loop` controls video playback, not list navigation.

### `--fps N`

Override the detected video frame rate:

```sh
./tview-go --fps 30 clip.mp4
```

The value is applied to every video in the loaded list. It controls playback timing; it does not change the source video or encode a new file. Values greater than zero are accepted. If the option is omitted, the program uses the first video stream's `avg_frame_rate`, falling back to 25 frames per second when the metadata is missing or invalid.

### `--mode MODE`

Select the renderer:

```sh
./tview-go --mode auto photo.jpg
./tview-go --mode color photo.jpg
./tview-go --mode color256 photo.jpg
./tview-go --mode ascii photo.jpg
```

Accepted values are:

| Value | Behavior |
|---|---|
| `auto` | Select truecolor, 256-color, or ASCII based on terminal environment variables. |
| `color` | Use ANSI truecolor (`24-bit`) output. `truecolor` and `ansi` are aliases. |
| `color256` | Use the ANSI 256-color palette. `256` and `ansi256` are aliases. |
| `ascii` | Use a grayscale character ramp with no color escape sequences. `plain` is an alias. |

In `auto` mode, `COLORTERM=truecolor` or `COLORTERM=24bit`, or `TERM` containing `direct`, selects truecolor. Otherwise, `TERM` containing `256color` selects 256-color. All other environments use ASCII.

## 7. Keyboard Controls

| Key | Action |
|---|---|
| `q`, `Q`, `Esc` | Quit and restore the terminal settings. |
| `h`, `H`, `p`, `P` | Show the previous media item. |
| `l`, `L`, `n`, `N`, `Enter` | Show the next media item. |
| `Space` | Toggle play or pause for the current video. It has no effect on images. |
| `0` | Return the current video to the beginning and start playback. It has no effect on images. |
| `+`, `=` | Increase playback speed by 0.25, up to 4.00x. |
| `-`, `_` | Decrease playback speed by 0.25, down to 0.25x. |
| `r`, `R` | Re-read the terminal size and render again. |

The source does not implement a `c` key for cycling render modes, frame-by-frame seeking, or arbitrary timestamp seeking. Earlier documentation may mention those features, but they are not part of the current keyboard handler.

## 8. Image Behavior

The program recognizes these image extensions during file discovery:

```text
.jpg .jpeg .png .gif .bmp .tif .tiff
```

The current source imports Go decoders for JPEG, PNG, and GIF. Therefore JPEG, PNG, and GIF files are the image formats that can currently be decoded by `image.Decode`. BMP and TIFF extensions are recognized but can fail during loading because no BMP or TIFF decoder is registered.

Images are decoded once when selected and remain paused. They are scaled to fit the available terminal area while preserving their aspect ratio. The final two terminal rows are reserved for the status line and help text.

Transparent pixels are composited over a near-black background before they are converted to terminal colors.

GIF input is decoded through the standard image decoder and is treated as a still image for this viewer; it is not played as an animated image sequence.

## 9. Video Behavior

The program recognizes these video extensions:

```text
.mp4 .mkv .webm .mov .avi .m4v .flv .wmv .mpeg .mpg .ts .3gp .ogv
```

For every recognized video, `ffprobe` reads:

- The container duration.
- The first stream marked as a video stream.
- That stream's average frame rate.

When a frame is needed, the program invokes `ffmpeg` with a timestamp and asks it to write one PNG frame to standard output. The Go program decodes that PNG in memory and renders it. This is simple and portable, but it starts an `ffmpeg` process for each frame and may be slow for high-resolution or long-GOP videos.

At startup, videos begin in the playing state. Press `Space` to pause or resume. Playback advances the position by `1 / fps * speed` seconds on each update. The event loop checks for a new frame roughly every 25 milliseconds, so the actual terminal refresh rate can be lower than the requested source frame rate.

When a non-looping video reaches its duration, playback stops near the final frame. With `--loop`, the position returns to zero and playback continues.

## 10. Rendering Details

### Truecolor mode

The truecolor renderer uses the Unicode upper-half block character `▀`. The top image pixel is written as the foreground color and the lower image pixel as the background color. One terminal row therefore represents two image-pixel rows.

The renderer emits ANSI sequences of the form:

```text
ESC[38;2;R;G;Bm
ESC[48;2;R;G;Bm
```

### 256-color mode

The 256-color renderer uses the same half-block technique. RGB values are mapped to the six-by-six-by-six ANSI color cube or to the grayscale ANSI range, whichever is closer to the source color.

### ASCII mode

The ASCII renderer converts each sampled pixel to luminance using weighted red, green, and blue values. It maps that luminance onto this ramp:

```text
 .:-=+*#%@
```

ASCII mode avoids color escape sequences and is the most suitable mode when terminal escape sequences are unsupported or output is being captured into a text log.

## 11. Terminal Lifecycle

Before entering the viewer loop, the program:

1. Saves the current terminal settings with `stty -g`.
2. Disables canonical input and input echo.
3. Hides the cursor.
4. Clears the screen and renders the current item.

When the program exits normally, it restores the saved terminal settings, shows the cursor, resets ANSI attributes, clears the screen, and moves the cursor to the home position.

Because terminal settings are changed, use the program from an interactive terminal rather than piping input to it. If a process is interrupted in a way that prevents its cleanup code from running, restore the terminal manually with:

```sh
stty sane
```

The `stty sane` command may reset more terminal settings than this application changed, but it is a practical recovery command.

## 12. Source Walkthrough

The implementation is intentionally contained in `main.go`.

### Types and constants

- `mediaKind` distinguishes images from videos.
- `renderMode` selects truecolor, 256-color, or ASCII output.
- `media` stores a path, media type, duration, and frame rate.
- `viewer` stores the media list, selected index, decoded frame, playback state, terminal size, and renderer.
- `probeResult` matches the small JSON structure returned by `ffprobe`.

### `main`

`main` defines flags, validates the input list, discovers media, checks external dependencies, chooses the renderer, reads the terminal size, loads the first item, enters raw terminal mode, and starts the render loop.

### `discover`

`discover` accepts files and directories. A directory is read with `os.ReadDir`, only direct non-directory entries are considered, and all paths are sorted before they become viewer items. Image extensions create image entries. Video extensions are passed to `probe` immediately.

### `probe` and `parseRate`

`probe` invokes `ffprobe` in JSON mode. It parses duration and frame-rate metadata. `parseRate` handles values such as `30000/1001` and falls back to a numeric value when no fraction is present.

### `loadCurrent` and `loadVideoFrame`

`loadCurrent` resets position and play state. Images are opened and decoded with `image.Decode`. Videos start playing and immediately load a frame. `loadVideoFrame` handles end-of-video behavior, invokes `ffmpeg`, and decodes the PNG frame from standard output.

### `run` and `handleKey`

`run` polls for keyboard input, advances video playback, and periodically redraws paused content. `handleKey` implements all supported controls and then renders the updated state.

### `refreshSize`

`refreshSize` runs `stty size`. If the command fails or returns invalid dimensions, the viewer uses an 80-column by 24-row fallback canvas.

### Rendering functions

`render` clears the terminal, renders the decoded image, and prints status information. `renderImage` dispatches to the selected renderer. `renderColor256`, `renderASCII`, `rgbToANSI256`, `pixelColor`, and the color helper functions perform sampling, scaling, color conversion, and transparency handling.

### `rawTerminal` and `readKey`

`rawTerminal` saves and modifies terminal settings. `readKey` uses `syscall.Select` with a zero timeout to perform non-blocking input checks, then reads one byte from standard input.

## 13. Validation and Development Commands

Format the source:

```sh
gofmt -w main.go
```

Check for static issues:

```sh
go vet ./...
```

Run tests:

```sh
go test ./...
```

Build and run the command:

```sh
go build -o tview-go .
./tview-go --help
```

The repository currently has no Go test files. `go test ./...` still verifies that all packages compile, but it does not exercise terminal interaction, media decoding, or rendering behavior.

For a release-style Linux build:

```sh
GOOS=linux GOARCH=amd64 go build -trimpath -ldflags='-s -w' -o tview-go-linux-amd64 .
```

## 14. Troubleshooting

### `ffmpeg is required` or `ffprobe is required`

Install the `ffmpeg` package and confirm both commands are on `PATH`:

```sh
command -v ffmpeg
command -v ffprobe
```

The dependency check runs for image-only sessions too, so both commands are required before startup.

### `stdin is not a terminal`

Run the executable directly in an interactive terminal. Do not pipe a file into it or run it in a context without a terminal attached to standard input.

### Colors look wrong or escape sequences are visible

Try ASCII mode:

```sh
./tview-go --mode ascii image.png
```

For a terminal with 256-color support, use:

```sh
./tview-go --mode color256 image.png
```

For a truecolor terminal, use:

```sh
./tview-go --mode color image.png
```

### The image is blank or too small

Press `r` to refresh the detected terminal dimensions. Confirm that the terminal is at least 10 columns wide and 5 rows high; otherwise the program uses its 80 by 24 fallback dimensions.

### A BMP or TIFF file is rejected

The current file-extension table recognizes BMP and TIFF, but the source only registers JPEG, PNG, and GIF decoders. Convert the file to PNG or JPEG, or add and import suitable Go image decoders in `main.go` before using those extensions.

### Video playback is slow

This implementation launches `ffmpeg` and decodes a new PNG for each displayed frame. Use a smaller video, lower the terminal resolution, use a lower frame-rate override, or consider implementing a persistent decoder if performance is important.

### The terminal is left in an unusual state

Run:

```sh
stty sane
```

Then start a new terminal session if the display remains inconsistent.

### A video cannot be probed or decoded

Check the file independently:

```sh
ffprobe -v error -show_format -show_streams clip.mp4
ffmpeg -v error -i clip.mp4 -frames:v 1 /tmp/tview-test.png
```

The installed ffmpeg build determines which containers and codecs are available. A recognized filename extension does not guarantee that the local ffmpeg build can decode the file.

## 15. Known Limitations

- Linux and Unix-style terminal behavior are assumed.
- `ffmpeg` and `ffprobe` are required before every session, including image-only sessions.
- Directory scanning is one level deep and ignores nested directories.
- BMP and TIFF are recognized by extension but are not currently registered with Go's image decoder.
- Animated GIFs are shown as still images.
- Video playback starts a new `ffmpeg` process for each frame.
- There is no timestamp seek command or frame-step command.
- There is no runtime command to change renderer mode; choose it with `--mode` before startup.
- Terminal resizing is detected only at startup or when `r` is pressed.
- The program expects a usable interactive terminal on standard input.
- There are no automated tests for media decoding, ANSI rendering, raw terminal behavior, or playback timing.

## 16. Safe Extension Points

Changes should remain focused in `main.go` unless the project grows. Common extension points are:

1. Add image formats by importing a decoder package and registering the matching extension only when the decoder is actually available.
2. Add controls in `handleKey`, then update the help line in `render` and the command-line usage text in `main`.
3. Add recursive directory discovery in `discover` while preserving deterministic sorting.
4. Improve playback performance by keeping a decoder process alive rather than invoking `ffmpeg` for every frame.
5. Add tests around pure functions such as `parseRate`, `formatTime`, `truncate`, `rgbToANSI256`, and media-extension filtering before changing terminal behavior.

When changing controls or supported formats, update `README.md`, `tview-go.md`, and this file together so the project documentation remains consistent with the source.
