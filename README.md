# zigscene

Audio visualization experiment using zig and raylib.

Built against Zig `0.16.0`.

## Getting Started

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

The deployable browser files are written to `zig-out/web`. Browser builds
support dropped audio files; native system audio capture is unavailable in a
browser.

## Usage

`zig build run`, then drag and drop an audio file onto the window. Press **M** to
capture system playback audio instead. Press **M** again to stop capture. Dropping
a file switches back to file playback. When capture stops, the previous file
resumes if it was playing before capture started.

The studio interface uses labeled tabs and scrollable settings panels. Open
**Settings** in the header (or press **6**) for FPS presets/custom limits, window
and background opacity, master volume, UI size, and the FPS counter toggle.
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
scene elements. The motion tab controls master volume, energy gain, compression,
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
