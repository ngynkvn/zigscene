# zigscene

An audio visualizer built with Zig and raylib, with customizable built-in layers
and programmable Lua scenes.

Built against Zig `0.16.0`.

## Getting Started

### Download a release

Download the archive for your platform from [Releases](https://github.com/ngynkvn/zigscene/releases).
The macOS and Linux `.tar.gz` archives preserve executable permissions, so no
`chmod +x` is needed after extraction.

On macOS (Apple Silicon), run these commands from the download directory:

```bash
tar -xzf zigscene-macos-aarch64.tar.gz
./zigscene-macos-aarch64
```

If macOS blocks the downloaded binary because it is quarantined, and you trust
the release you downloaded, clear the quarantine attribute on that binary and
run it again:

```bash
xattr -d com.apple.quarantine ./zigscene-macos-aarch64
./zigscene-macos-aarch64
```

On Linux (x86_64):

```bash
tar -xzf zigscene-linux-x86_64.tar.gz
./zigscene-linux-x86_64
```

On Windows, extract `zigscene-windows-x86_64.zip` and run `zigscene.exe` inside
the extracted folder.

### Build from source

You should have:

- This repository:

  ```bash
  git clone https://github.com/ngynkvn/zigscene
  cd zigscene
  ```

- `zig` available in PATH.
  - Ensure `zig version` outputs `0.16.0`

```bash
# Build the project
zig build

# Build and run
zig build run

# Build with release optimization
zig build -Doptimize=ReleaseFast

# Run with application and audio analysis optimizations too
zig build run -Doptimize=ReleaseFast

# Run tests
zig build test
```

### Web build

Install and activate the [Emscripten SDK](https://emscripten.org/docs/getting_started/downloads.html), then run:

```bash
zig build web -Dtarget=wasm32-emscripten -Doptimize=ReleaseSafe \
  --sysroot "$EMSDK/upstream/emscripten"

# Serve the generated bundle locally with emrun
zig build web-run -Dtarget=wasm32-emscripten -Doptimize=ReleaseSafe \
  --sysroot "$EMSDK/upstream/emscripten"
```

The web target is experimental; this overhaul targets the native app. Lua scenes
are currently native only. The deployable browser files are written to
`zig-out/web`. Browser builds
support dropped audio files; native system audio capture is unavailable in a
browser.

## Usage

`zig build run`, then drag and drop an audio file onto the window. Press **M** to
capture system playback audio instead. Press **M** again to stop capture. Dropping
a file switches back to file playback. When capture stops, the previous file
resumes if it was playing before capture started.

The studio interface uses labeled tabs and scrollable settings panels. Open
**Settings** in the header (or press **6**) for FPS presets/custom limits, window
and background opacity, master volume, UI size, the FPS counter toggle, and
**Always on top** (native only, on by default). Turn it off to let other windows
cover zigscene.
Choose 75%, 100%, 125%, or 150% UI size; text, controls, and mouse targets scale
together, automatically fitting smaller windows. Drag a panel's right or bottom
edge, or its bottom-right grip, to resize it. **Reset UI size and panel** restores
the default layout. These preferences apply for the current session.
Use the wheel or drag the scrollbar to explore each panel. The playback bar provides
Play/Pause, System audio capture, and a Volume slider. Drag the waveform to seek;
the elapsed/total timer sits on the waveform, with the track name above it. Hover
over the waveform to preview a seek time. The waveform preserves linear sample
peaks with a brighter RMS body and up to 8,192 analysis bins, reduced to display
pixels without skipping transients. Its three colors show low frequencies (red,
below 250 Hz), mids (green, 250 Hz–4 kHz), and highs (blue, above 4 kHz), using
filters at the file's sample rate. Colored layer thickness reflects relative band
RMS; filter transitions overlap around the crossover frequencies. Tabs remember their scroll positions,
and Scene provides Show all / Hide all controls. Hover over an element's settings
to highlight it in the scene; the highlight stays active while dragging a slider.
Hidden layers stay hidden, and global controls do not single out a layer.
Audio loading and capture failures appear in the playback bar with a Dismiss button.

Use **1** to hide the settings, **2** for shape and shader controls, **3** for
colors, **4** for motion and audio response, and **5** to show or hide individual
scene elements and load/customize Lua scenes. The motion tab controls master volume, energy gain, compression,
rise and fall times, and beat pulse decay. The frequency halo has its own radius, depth, spin,
and hue controls. Hold **Space** to temporarily smooth the waveform more heavily.
Settings has a Window opacity slider for the entire window. The
Background opacity slider in Settings (also available in Shape) controls only the window background;
reduce it from the default opaque navy to reveal the desktop.
The upper-right counter shows FPS and frame time by default. Click it or press **D**
to open CPU timings for audio/update, scene drawing, UI, and presentation/wait,
plus mouse and audio response values. Rendering is uncapped by default; set
**Settings → Window → FPS limit** to cap it (0 means unlimited). Presentation/wait
includes any requested frame-limit sleep, so it is not a GPU-only measurement.

The seek waveform is cached at display resolution and rebuilt only when the
track or display size changes. Development builds keep the application's Debug
checks while optimizing raylib; use `-Draylib-optimize=Debug` when debugging the
graphics backend itself.

You can start capture from the command line:

```bash
zig build run -- --system-audio
zig build run -- --input-audio
zig build run -- --list-audio-devices
zig build run -- --system-audio --audio-device=0
```

On Windows, system audio uses the playback device's loopback stream. On Linux,
it selects the first input device with `Monitor` in its name; use
`--list-audio-devices` and `--audio-device=N` to choose a different device.
On macOS, select a virtual loopback input using `--audio-device=N`.

## Programmable scenes

Use **Scene / 5** to try **Palette** (animates built-in layers), **Orbit** (custom
2D), or **Sculpture** (custom 3D). Their parameters appear as sliders in the panel.
To edit a scene, drop a `.lua` file or launch with one:

```bash
zig build run -- --scene=src/scripting/examples/orbit.lua
zig build run -- --scene=src/scripting/examples/sculpture.lua song.wav
```

Lua is embedded; you do not need to install it separately. Each script returns a
table and chooses how it composes with the app:

```lua
return {
    name = "My pulse",
    mode = "replace", -- "overlay" extends the built-in scene instead
    config = {
        window = { fps_limit = 120, always_on_top = false },
        shader = { chroma_factor = 0, noise_factor = 0 },
    },
    draw = function(ctx)
        gfx.circle(ctx.width * 0.6, ctx.height * 0.4,
            60 + ctx.audio.energy * 120, gfx.hsv(ctx.time * 20, 0.7, 1))
    end,
}
```

Scripts can provide `setup`, `update`, and `draw` callbacks; read waveform samples,
spectrum, beats, energy, time, mouse input and playback progress; change host
settings; and draw 2D/3D primitives. A `params` list adds custom sliders. The player,
seek waveform, settings UI and post-processing stay available in both modes.

Native files reload automatically when saved, or manually with **F5** / **Reload**.
Compile/setup errors keep the previous scene running and show the error in Scene.
Runtime errors return to the built-in scene and restore script-owned settings.
**Use built-in** unloads the script. Reload preserves sliders by parameter ID;
ordinary Lua state resets. Browser examples work too, but edited files must be
dropped again because browsers receive a copy of each file.

Read the [Lua scene guide and full API reference](docs/scripting.md) for callbacks,
parameters, drawing functions, all config paths, examples and runtime limits.
See [ARCHITECTURE.md](ARCHITECTURE.md) for the application/audio/render pipeline,
Lua–Zig boundary, transactional reloading, module ownership, builds and tests.

## Screenshots

<div style="display: flex; flex-wrap: wrap; gap: 10px;">
    <img src="https://github.com/user-attachments/assets/c87094ec-866d-4cd1-ad56-1fe32f4a6de0" alt="example" style="width: 40%;"/>
    <img src="https://github.com/user-attachments/assets/c61581d6-0686-4786-9f4f-2cdd4cfb98dc" alt="example" style="width: 47%;"/>
    <img src="https://github.com/user-attachments/assets/125bb810-4936-4b71-9610-727efa382211" alt="example" style="width: 40%;"/>
    <img src="https://github.com/user-attachments/assets/4e427ed1-1396-4c51-a5fe-27ca09f74000" alt="example" style="width: 46%;"/>
</div>

[1]: https://github.com/marler8997/zigup?tab=readme-ov-file#how-to-install
[2]: https://github.com/tristanisham/zvm?tab=readme-ov-file#installing-zvm

## UI font

The interface embeds Lato Regular by the Lato Project Authors, distributed under
the SIL Open Font License. See [the bundled license](src/gui/assets/OFL.txt).


## Lua license

The build embeds Lua 5.4.9 from [lua.org](https://www.lua.org/), distributed under
the MIT license. See [the bundled copyright and license](docs/licenses/Lua.txt).
