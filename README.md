# Mango utils

Utilities that interact with **mango IPC (mmsg)** to provide a better experience for common tasks like screenshots and screencasts.

## Project Status

> ⚠️ **Early stage**
> Most of the things are functional but not guaranteed!!
> All dependencies are chosen to work well with **mangowc (wlroots)**.
> A potential new mango ipc implementation is awaited before proper status.

## Dependencies

### `mcast`

* **Required**:
  - One of: `gpu-screen-recorder(default)`, `wf-recorder`, `wl-screenrec`
  - `slurp`
  - `notify-send`

### `mshot`

* **Required**: `grim`, `slurp`, `wl-copy`, `notify-send`
* **Optional**: `still`(for freezing screen), `satty` (for annotations)

### `mutil`

* **Required**: `quickshell` (qs)

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
|  | `-g`, `--geometry` | `SPEC` | Record region with direct geometry in "x,y wxh" format |
|  | `-b`, `--backend` | `RECORDER` | Backend:<br>wf-recorder<br>wl-screenrec<br>gpu-screen-recorder |
|  | `-t`, `--toggle` | - | Toggle recording on/off |
|  | `-o`, `--output` | `DIRECTORY` | Set the output directory |
|  | `-f`, `--filename` | `NAME` | Set the output filename/pattern |
| **mshot** | `-r`, `--region` | - | Screenshot a selected region |
|  | `-g`, `--geometry` | `SPEC` | Capture region with direct geometry in "x,y wxh" format |
|  | `-w`, `--window` | - | Capture the active window via `mmsg` |
|  | `-p`, `--pointer` | - | Include mouse pointer in capture |
|  | `-a`, `--annotate` | - | Open in `satty` for annotation |
|  | `-o`, `--output` | `DIRECTORY` | Set the output directory |
|  | `-f`, `--filename` | `NAME` | Set the output filename/pattern |
|  | `--no-copy` | - | Skip copying to clipboard |
|  | `-F`, `--freeze` | - | Freeze the screen before capturing (requires `still`) |

### `mutil`

A GUI tool for screenshots and screencasts using QuickShell:

```sh
qs - c mutil.qml
```

## Mangowc Example Keybinds

```ini
# mutil GUI combines mshot & mcast
bind=none,Print,spawn,qs -c mutil

# Screenshot: Selected region
bind=SHIFT,Print,spawn_shell,mshot -r

# Screencast: Toggle region recording
bind=ALT,F12,spawn_shell,mcast --toggle --region
```

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
