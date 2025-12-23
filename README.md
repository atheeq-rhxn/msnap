# Mango utils

Utilities that interact with **mango IPC (mmsg)** to provide a better experience for common tasks like screenshots and screencasts.

## Project Status

> ⚠️ **Early stage**
> Currently, the only functionality directly interacting with **mango IPC (mmsg)** is **current window screenshots**. Full integration is deferred until mangowc’s new IPC implementation is available.
> All dependencies are chosen to work well with **mangowc (wlroots)**.

## Dependencies

### `mcast`

* **Required**: `wf-recorder`, `slurp`, `notify-send`

### `mshot`

* **Required**: `grim`, `slurp`, `wl-copy`, `notify-send`
* **Optional**: `satty` (for annotations)

## Installation

Run the following command to clone the repository, install binaries to `~/.local/bin`, and set up default configurations in `~/.config/mango-utils`:

```sh
curl -fsSL https://raw.githubusercontent.com/atheeq-rhxn/mango-utils/main/install.sh | sh

```

*Note: Ensure `~/.local/bin` is in your `PATH`.*

## Usage

### Commands and Options

| Tool | Flag | Argument | Description |
| --- | --- | --- | --- |
| **mcast** | `-r`, `--region` | - | Record a selected screen region |
|  | `-o`, `--output` | `DIRECTORY` | Set the output directory |
|  | `-f`, `--filename` | `NAME` | Set the output filename/pattern |
| **mshot** | `-r`, `--region` | - | Screenshot a selected region |
|  | `-w`, `--window` | - | Capture the active window via `mmsg` |
|  | `-p`, `--pointer` | - | Include mouse pointer in capture |
|  | `-a`, `--annotate` | - | Open in `satty` for annotation |
|  | `-o`, `--output` | `DIRECTORY` | Set the output directory |
|  | `-f`, `--filename` | `NAME` | Set the output filename/pattern |
|  | `--no-copy` | - | Skip copying to clipboard |


## Mangowc Example Keybindings

```ini
# Fullscreen (copied to clipboard and saved)
bind=none,Print,spawn_shell,mshot

# Selected region
bind=SHIFT,Print,spawn_shell,mshot -r

# Active window
bind=ALT,Print,spawn_shell,mshot -w

# Region with immediate annotation
bind=SHIFT+ALT,Print,spawn_shell,mshot -ra
```
> Note: currently keybind for stopping screen recording not implemented. If needed to try screenrecording do from the tty.

## Configuration

Default settings are stored in `~/.config/mango-utils/`:

* **`mcast.conf`**: Sets `output_dir` (default: `~/Videos/Screencasts`) and `filename_pattern`.
* **`mshot.conf`**: Sets `output_dir` (default: `~/Pictures/Screenshots`), `filename_pattern`, and `pointer_default`.

## Development

Tools are built using **[bashly](https://bashly.dev/)**. To regenerate a tool after modifying its source:

```sh
# From the tool's directory (mcast/ or mshot/)
bashly generate
```
