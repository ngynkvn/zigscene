# Desktop pet

[Project home](../README.md) · [All docs](README.md) · [User guide](usage.md)

Desktop-pet mode puts a small, transparent visualizer above your other windows.
It starts system-audio capture automatically, so music playing in another app
drives the scene.

## Start on Windows

From the folder containing the executable, run this in PowerShell:

```powershell
.\zigscene.exe --desktop-pet
```

Windows captures the default playback device through WASAPI loopback. To choose
a different device, right-click the pet, stop capture, select the output in
**Audio devices**, then start capture again. Right-click the scene to return to the pet.
If capture cannot start, the Audio devices panel opens. Read the notice in the
player; use **Expand player** if it is hidden.

You can also pass an index from `--list-audio-devices`:

```powershell
.\zigscene.exe --desktop-pet --audio-device=2
```

## Move it and open controls

| Action | Control |
| --- | --- |
| Move the pet | Hold the left mouse button and drag |
| Open the full controls window | Right-click |
| Return to the pet | Right-click the scene outside the controls |
| Quit | Press **Esc**, or close the controls window |

The compact view is a 400 × 400 borderless window. The header, side panel,
player, and FPS counter are hidden. Hover over it for a control hint.
It receives mouse input inside its window so you can drag it.

The controls window provides the usual scene, Lua, audio-device, and playback
settings. Dropping an audio file switches from live capture to that file.
Use **Capture / M** in the controls window to return to system audio.
Passing an audio filename with `--desktop-pet` starts that file instead; add
`--system-audio` explicitly if you want live capture to take priority.
The controls keep their right-click shortcuts for resetting values and saving
swatches. Your selected tab is retained when you reopen the controls.

## Preferences and other platforms

Compact mode forces a transparent background, disables background noise, and
keeps the window on top. If your FPS limit is uncapped, the pet uses 60 FPS.
These presentation overrides last only for the session; they do not replace
your saved opacity, noise, FPS limit, or player-visibility preferences. Changes
you make in the controls window save normally. Each launch places the pet near
the bottom-right of the current monitor.

Native source builds can use `zig build run -- --desktop-pet` on Linux and
macOS too. System-audio routing follows the [capture setup](usage.md#platform-setup):
Linux needs a monitor input; macOS needs a routed loopback input. An explicit
`--input-audio` selects an input instead of system audio. The browser build
does not provide desktop-pet mode.
