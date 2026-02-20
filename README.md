# msnap

Screenshot and Screencast utils that aims to provide a better experience with mangowc.


https://github.com/user-attachments/assets/53a4c616-3a6f-4400-ae9c-a15e277e710f


---

## Project Status

> ⚠️ **Early stage**
> Most of the things are functional but not guaranteed!!
> All dependencies are chosen to work well with **mangowc (wlroots)**.
> A potential new mango ipc implementation is awaited before proper status.

## Dependencies

### `mcast`

* **Required**:
  - [`gpu-screen-recorder`](https://git.dec05eba.com/gpu-screen-recorder/)
  - [`slurp`](https://github.com/emersion/slurp)
  - [`notify-send`](https://gitlab.gnome.org/GNOME/libnotify)

### `mshot`

* **Required**: [`grim`](https://gitlab.freedesktop.org/emersion/grim), [`slurp`](https://github.com/emersion/slurp), [`wl-copy`](https://github.com/bugaevc/wl-clipboard), [`notify-send`](https://gitlab.gnome.org/GNOME/libnotify)
* **Optional**: [`wayfreeze`](https://github.com/Jappie3/wayfreeze) (for freezing screen), [`satty`](https://github.com/gabm/Satty) (for annotations)

> **Note:** `wayfreeze` must be in your global PATH.

### `gui`

GUI using `mcast` & `mshot` 

* **Required**: [`quickshell` (qs)](https://github.com/quickshell-mirror/quickshell)

## Installation

Run the following command to clone the repository, install binaries to `~/.local/bin`, and set up all configurations in `~/.config/msnap`:

```sh
curl -fsSL https://raw.githubusercontent.com/atheeq-rhxn/msnap/main/install.sh | sh

```

*Note: Ensure `~/.local/bin` is in your `PATH`.*

## Usage

### Commands and Options

| Tool | Flag | Argument | Description |
| --- | --- | --- | --- |
| **mcast** | *(no flags)* | - | Record full screen |
|  | `-r`, `--region` | - | Record a selected screen region |
|  | `-g`, `--geometry` | `SPEC` | Record region with direct geometry in "x,y wxh" format |
|  | `-t`, `--toggle` | - | Toggle recording on/off |
|  | `-o`, `--output` | `DIRECTORY` | Set the output directory |
|  | `-f`, `--filename` | `NAME` | Set the output filename/pattern |
|  | `-a`, `--audio` | - | Record system audio |
|  | `-m`, `--mic` | - | Record microphone |
|  | `-A`, `--audio-device` | `DEVICE` | System audio device (default: default_output) |
|  | `-M`, `--mic-device` | `DEVICE` | Microphone device (default: default_input) |
| **mshot** | *(no flags)* | - | Screenshot full screen |
|  | `-r`, `--region` | - | Screenshot a selected region |
|  | `-g`, `--geometry` | `SPEC` | Capture region with direct geometry in "x,y wxh" format |
|  | `-w`, `--window` | - | Capture the active window via `mmsg` |
|  | `-p`, `--pointer` | - | Include mouse pointer in capture |
|  | `-a`, `--annotate` | - | Open in `satty` for annotation |
|  | `-o`, `--output` | `DIRECTORY` | Set the output directory |
|  | `-f`, `--filename` | `NAME` | Set the output filename/pattern |
|  | `--no-copy` | - | Skip copying to clipboard |
|  | `-F`, `--freeze` | - | Freeze the screen before capturing (requires `wayfreeze`) |

### `gui`

Launch the GUI:

```sh
qs -p ~/.config/msnap/gui
```

**Keyboard Shortcuts:**

| Key | Action |
|-----|--------|
| `H` / `L` | Navigate capture modes (left/right) |
| `J` / `K` | Switch mode (Screenshot/Record) |
| `Tab` | Toggle mode |
| `Enter` / `Space` | Execute action |
| `Shift+Enter` | Quick capture (skip menu and execute immediately) |
| `P` | Toggle pointer (screenshot only) |
| `E` | Toggle annotation (screenshot only) |
| `A` | Toggle system audio (recording only) |
| `M` | Toggle microphone (recording only) |
| `Escape` | Close / Stop recording |

When recording, a red indicator appears in the top-right corner; hover and click it to stop.

## Mangowc Configuration

Example keybinds:
```ini
# gui 
bind=none,Print,spawn,qs -p ~/.config/msnap/gui

# Screenshot: Selected region
bind=SHIFT,Print,spawn_shell,mshot -r

# Screencast: Toggle region recording
bind=SHIFT,ALT,spawn_shell,mcast --toggle --region
```

**Note:** Add the following rule to prevent the `gui` layer from being animated or blurred:

```ini
layerrule=layer_name:msnap,noanim:1,noblur:1
```

## Configuration

Default settings are stored in `~/.config/msnap/`:

* **`mcast.conf`**: Sets `output_dir` (default: `~/Videos/Screencasts`) and `filename_pattern`.
* **`mshot.conf`**: Sets `output_dir` (default: `~/Pictures/Screenshots`), `filename_pattern`, and `pointer_default`.
* **`gui.conf`**: Theme (colors, accents, alphas) and behaviour (quick_capture).

## Development

Tools are built using **[bashly](https://bashly.dev/)**. To regenerate a tool after modifying its source:

```sh
# From the tool's directory (mcast/ or mshot/)
bashly generate
```
