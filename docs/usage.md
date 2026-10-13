# User guide

[Project home](../README.md) · [All docs](README.md) ·
[Lua scenes](scripting.md) · [Development](development.md)

Use zigscene with a track or live audio, then adjust the scene from the tabs.
For installation, start with [Getting started](../README.md#getting-started).

**On this page:** [Playback](#play-a-track) · [Capture](#capture-live-audio) ·
[Customization](#customize-the-scene) · [Shortcuts](#shortcuts) ·
[Saved settings](#saved-settings) · [Troubleshooting](#troubleshooting)

## Play a track

Choose **Open audio** (or **Ctrl/Cmd+O**) to browse for an MP3, WAV, or OGG, or
drop one onto the window. On minimal Linux desktops without a graphical
chooser, Open audio provides a full-path entry instead.

Opening or dropping a new file switches back
from live capture to file playback. If you drop several audio files at once,
only the last one loads. FLAC support is disabled in the bundled raylib build.

The player at the bottom of the window provides:

| Control | Action |
| --- | --- |
| Round **Play / Pause** button, **Space**, or **P** | Pause or resume the loaded track |
| **Open audio** | Choose another track |
| **Volume** | Change the output volume |
| Waveform | Drag to seek; hover to preview a time |
| **Devices** | Choose the live-capture source |
| **Capture / M** | Start or stop the selected capture source |

The track name and playback state appear beside the play button. Elapsed and
total time sit at either end of the waveform (on the waveform in small windows).
Loading and capture errors appear in the player with a **Dismiss** button.

Click **Hide player** at the top-right of the player to give the scene more
space. Playback and the **P** / **M** shortcuts keep working. **Expand
player** at the right of the status bar brings the controls back; it highlights
when there is an audio notice. Native builds remember whether the player is hidden.

### Read the seek waveform

The outline preserves sample peaks; the brighter body shows RMS, a measure of
average signal level. Its colors show frequency bands:

| Color | Band |
| --- | --- |
| Red | Low: below 250 Hz |
| Green | Mid: 250 Hz–4 kHz |
| Blue | High: above 4 kHz |

Colored thickness shows each band's relative RMS. Filters overlap around the
crossovers. The preview uses the source file's sample rate and up to 8,192 bins,
then combines bins for the display without skipping transients.

Native MP3/WAV/OGG previews build in the background. A preview may take a moment
to appear, especially after switching tracks. For decoding and caching details,
see [Audio and the seek waveform](../ARCHITECTURE.md#audio-and-the-seek-waveform).

## Capture live audio

The welcome screen's **Capture system audio** starts the automatic system source.
If it cannot start, the device panel opens so you can choose a source.

1. Click **Devices** beside the capture button.
2. Choose **System audio** or **Input**, then select a device by name.
3. Click **Capture / M**, or press **M**, to start. Use it again to stop.

Stop capture before changing devices. Use **Refresh devices** after connecting
hardware. The button and **M** reuse your selection for the rest of the session.
When capture stops, the previous file resumes if it was playing before capture
started.

### Platform setup

| Platform | System audio source |
| --- | --- |
| Windows | The selected playback device's loopback stream |
| Linux | A monitor input; automatic selection looks for `Monitor` in the name |
| macOS | A virtual loopback input, with system sound routed into it |
| Browser | Live capture is unavailable; drop an audio file instead |

On macOS, choose your installed loopback input (such as BlackHole) in **Devices**.
On Linux, select a different monitor/input if automatic selection is silent.

### Command line

From a source checkout:

```sh
zig build run -- --system-audio
zig build run -- --input-audio
zig build run -- --list-audio-devices
zig build run -- --system-audio --audio-device=0
```

For a downloaded binary, pass the same flags directly to the executable.
Command-line selections also appear in the **Devices** panel.

## Customize the scene

| Tab / key | Controls |
| --- | --- |
| **Hide / 1** | Hide the side panel |
| **Shape / 2** | Layer geometry and shader effects |
| **Color / 3** | Expandable hue, saturation, brightness, and saved swatches |
| **Motion / 4** | Volume, waveform smoothing/strength, energy gain, compression, rise/fall times, and beat decay |
| **Scene / 5** | Layer visibility, Lua examples, and script parameters |
| **Settings / 6** | FPS limit, opacity, volume, UI size, FPS display, and always-on-top |
| **Looks / 7** | Choose a starter look; save, load, and duplicate named looks |
| **Layers / 8** | Search controls, solo a layer, and reset groups |

Hover over a layer's settings to highlight it in the scene. The highlight stays
active while dragging a slider; hidden layers stay hidden. **Show all / Hide
all** in Scene controls the built-in layers. See [Lua scenes](scripting.md) to
try a custom visualizer.

Beats and sharp increases in audio level react on the first analyzed frame.
**Swell rise** in Motion controls gradual increases; **Fall time** controls the
decay. Waveform smoothing preserves the leading edge of hits. Holding
**Shift+Space** applies deliberately heavier waveform smoothing.

### Explore and save a look

Open **Looks / 7** and try **Calm**, **Pulse**, or **Sculpture**. Each row shows a
small palette-and-layer preview; Lua looks use a generic scene symbol.

Enter a name and choose **Save as** to create a saved look. Existing names are
protected: select that look and choose **Replace** to overwrite it. Click a saved
look to restore its visual settings, Lua scene reference, and parameters.
**Duplicate** makes a separate copy. The library holds 24 saved looks in addition
to the three starters.
Native builds save immediately to `presets.json` beside `settings.conf`; browser
presets last for the session. External Lua files are referenced by absolute path,
so keep those files available. A missing or invalid scene keeps the current look.
Window, interface, volume, and capture-device settings are excluded.

Use **Undo / Redo** in the status bar or the keyboard shortcuts to explore visual
changes. History holds up to 63 edits, groups a completed slider drag into one
edit, and includes switching starter or saved looks, including their Lua scenes
and parameters. Directly loading or reloading a Lua file starts a new history.
A teal dot marks controls changed from their defaults. Click the reset arrow
beside a changed value or right-click the control to reset it; section
**Reset** buttons restore a group. Lua-owned host controls display **Lua** and
remain locked; adjust the scene's exposed parameters instead.

**Layers / 8** opens first and collects each layer's controls into collapsible
Shape, Color, and Global response groups. Use the arrows or click the layer name
to choose a layer. Search by label or setting path. **Solo** temporarily shows
only the selected enabled built-in layer, without changing saved visibility.
In **Scene**, the eye icon shows or hides a layer; click the layer's name to
open its inspector. Solo clears when the scene changes.

In **Color**, expand a color to edit all three HSV components. Click a swatch to
apply it; right-click a swatch to save the current color. The eight shared swatches
save alongside presets on native builds. Spectrum tips and body have separate colors.

### Panel and UI size

Scroll with the wheel, scrollbar, or **Page Up / Page Down**. Tabs remember their
scroll position within the session. The scene fits between the header, panel,
and player. Drag the scene with the left mouse button to turn the halo in any
direction. **Fit scene** restores the built-in camera and halo after zooming,
rotating, or turning; Lua scenes manage their own cameras. Opening or hiding the panel slides the scene.

Choose 75%, 100%, 125%, or 150% UI size in **Settings**. Text, controls, and mouse
targets scale together and fit smaller windows. Resize a panel by dragging its
right edge, bottom edge, or bottom-right grip. **Reset UI size and panel** restores
the default layout.

Small windows use a narrower inspector and a shorter player automatically.
**Tab / Shift+Tab** moves focus between visible buttons, text fields, and numeric
controls. **Enter / Space** activates a focused button. On a numeric control,
use the arrow keys to adjust, **Shift** for finer changes, **Home / End** for the
range limits, or **Enter** to type a value. Hover for labels and control hints.

### Window and background

- **Window opacity** changes the opacity of the whole native window.
- **Background opacity** changes only the scene background. Normal launches start
  at `1` (fully opaque), even after a translucent session. Lower it to reveal the
  desktop. It is also available in Shape.
- **Always on top** keeps the native window above other windows and defaults to
  off. Turn it on when you want zigscene to stay above other windows.
- **FPS limit** sets the frame cap; `0` means uncapped, the default.

Enable **Show FPS** in Settings to display FPS and frame time. Click it or press **D** for
CPU diagnostics. See [Profiling and diagnostics](development.md#profiling-and-diagnostics)
for what those timings measure.

## Shortcuts

| Key or gesture | Action |
| --- | --- |
| **1–8** | Select a tab, as listed [above](#customize-the-scene) |
| **Ctrl/Cmd+Z** | Undo a visual edit |
| **Ctrl/Cmd+Shift+Z** or **Ctrl/Cmd+Y** | Redo a visual edit |
| Right-click a control | Restore its default value |
| **Space / P** | Play/pause a loaded file (Space activates a focused control) |
| **Ctrl/Cmd+O** | Open an audio file |
| **Tab / Shift+Tab** | Move keyboard focus forward/backward |
| **Enter / Space** | Activate the focused button |
| **Page Up / Page Down** | Scroll the side panel |
| **M** | Start/stop the selected capture source |
| Hold **Shift+Space** | Temporarily apply heavier waveform smoothing |
| **F5** | Reload the selected Lua scene |
| **F** | Toggle borderless window mode |
| **C** | Switch the built-in camera between perspective and orthographic |
| **Left / Right** | Rotate the built-in 3D scene when no UI control has keyboard focus |
| Vertical wheel over the scene | Move the camera closer/farther (stops short of the scene center) |
| Horizontal wheel over the scene | Rotate the built-in 3D scene |
| Left-drag on the scene | Turn the halo in any direction |
| Wheel over a panel | Scroll its controls |
| **D** or click the FPS counter | Toggle diagnostics |

Playback, camera, and smoothing shortcuts are ignored while editing a numeric
value or text field. Tab finishes text entry and advances focus.
Holding Shift+Space does not change the saved smoothing setting.

## Saved settings

Native host settings save when the app closes: volume, layer controls, colors,
panel sizes, player visibility, UI scale, FPS limit, window opacity, and always-on-top.
Normal launches reset background opacity to `1`; desktop-pet mode keeps its
transparent presentation.

| Platform | Settings file |
| --- | --- |
| Linux | `$XDG_CONFIG_HOME/zigscene/settings.conf`, or `~/.config/zigscene/settings.conf` |
| Windows | `%APPDATA%\zigscene\settings.conf` |
| macOS | `~/Library/Application Support/zigscene/settings.conf` |
| Browser | No settings file; preferences last for the session |

The file contains `name=value` lines using the [settings reference](scripting.md#settings-reference)
paths. Booleans are saved as `0` or `1`. Unknown or malformed entries are ignored;
valid numbers are clamped to supported ranges. On Linux, an empty or relative
`XDG_CONFIG_HOME` falls back to `~/.config`.

Use **Reset all settings** at the top of **Settings / 6** to restore the original
visual, audio, window, and layout defaults. It unloads the active Lua scene, resets
the camera, and clears solo mode and edit history. Native builds save the reset
immediately. Saved presets and swatches stay in your library, and the current
audio source keeps playing. **Reset UI size and panel** resets only the layout.

Lua-owned overrides are restored before saving, so they do not replace your
preferences. UI edits do not rewrite a Lua source file. Script parameter sliders
survive reload by ID; save a preset to restore them across app restarts. Capture-device
selection also lasts only for the session.

## Troubleshooting

### A file does not load

Use an MP3, WAV, or OGG file and read the error in the player. The bundled build
does not enable FLAC. Dropping another file retries playback. A failed load keeps the current audio source.

### Capture fails or is silent

Stop capture, open **Devices**, refresh the list, and select the correct source.
Check the [platform setup](#platform-setup), particularly monitor inputs on Linux
and loopback routing on macOS. If a device was disconnected, refresh and select
an available device before restarting capture.

### A Lua scene fails

Open **Scene / 5** to read the error. Compile/setup failures keep the previous
scene running; runtime failures return to the built-in scene and restore the
script's settings. Fix the file and save or press **F5** to retry. See
[Reloading and errors](scripting.md#reloading-and-errors).

### macOS blocks the downloaded app

If the binary is quarantined and you trust the release you downloaded, remove
the quarantine attribute from that binary, then run it again:

```sh
xattr -d com.apple.quarantine ./zigscene-macos-aarch64
./zigscene-macos-aarch64
```

### Settings do not survive a restart

Close the app normally so it can save, then check the platform's
[settings path](#saved-settings) and that its directory is writable. Browser
settings and capture-device selections are session-only. A Lua scene may also
apply its own overrides when loaded.
