# CLAUDE.md

## Project Overview

ZigScene is a real-time audio visualization application written in Zig using raylib for graphics and audio. Users drag and drop audio files onto the window to see interactive visualizations including waveforms, FFT spectrums, and 3D bubble geometry. Parameters are tunable at runtime through an immediate-mode GUI.

## Build & Run

Requires **Zig nightly/master** (currently built against `0.14.0-dev.2605+136c5a916`). Stable Zig releases will not work.

```bash
zig build              # Build the project
zig build run          # Build and run
zig build test         # Run all unit tests
zig build check        # Check build + run tests (no artifacts)
zig build -Doptimize=ReleaseFast  # Optimized build
```

### Tracy Profiler (optional)

```bash
zig build -Dtracy_enable=true   # Enable Tracy integration
```

### Cross-compilation & Release

```bash
zig build release-build                          # Build for all release targets
just release-win32                               # Windows release zip
just web-build                                   # WebAssembly via Emscripten
```

### Dependency Management

```bash
just update-deps   # Fetch latest raylib + raygui from GitHub
```

## Project Structure

```
src/
├── main.zig                    # Entry point: event loop, render pipeline
├── raylib.zig                  # Raylib C FFI wrapper with convenience helpers
├── RingBuffer.zig              # Generic ring buffer (with inline tests)
├── graphics.zig                # Graphics module aggregator
├── graphics/visualizers/
│   ├── bubble.zig              # 3D bubble visualization
│   ├── spectrum.zig            # FFT spectrum bars
│   └── waveform.zig            # Waveform line + bar visualizers
├── audio/
│   ├── playback.zig            # Music loading/playback (with inline tests)
│   ├── processor.zig           # Audio callback: FFT, beat detection, RMS
│   └── analysis/
│       ├── fft.zig             # Cooley-Tukey FFT (with inline tests)
│       └── beat_detector.zig   # Beat detection algorithm
├── core/
│   ├── config.zig              # All tunable parameters (window, audio, visuals)
│   ├── init.zig                # Window/audio device initialization
│   ├── input.zig               # Keyboard, mouse, file drop, scroll handling
│   ├── debug.zig               # FPS counter and beat timeline overlay
│   └── event.zig               # Event dispatcher (comptime inline dispatch)
├── gui.zig                     # GUI frame, tab management, animated transitions
├── gui/
│   ├── controls.zig            # Scalar and Color control type definitions
│   ├── color_picker.zig        # Custom HSV color picker widget
│   ├── layout.zig              # Layout definitions
│   └── state.zig               # GUI state
├── ext/
│   ├── convert.zig             # Type conversion utilities
│   ├── structs.zig             # Rectangle struct helpers
│   ├── color.zig               # HSV/RGB color conversion
│   └── vector.zig              # Vector math library (2D, 3D, 4D, complex)
└── shader/
    ├── shader.zig              # Shader loading and uniform management
    ├── chromatic.fs.glsl       # Chromatic aberration + noise fragment shader
    ├── chromatic.vs.glsl       # Vertex shader
    ├── base.fs.glsl            # Base fragment shader
    └── base.vs.glsl            # Base vertex shader

deps/
├── raylib/                     # Raylib graphics/audio library (local dependency)
├── tracy/                      # Tracy profiler (optional, compiles as stub when disabled)
└── build/                      # Build utilities (Emscripten support)

tests/
└── c-interop/                  # C interop tests

.github/workflows/
├── test.yml                    # CI: build + test on every push (ubuntu, zig master)
└── release.yml                 # CD: build macOS aarch64 + Linux x86_64 on GitHub release
```

## Architecture

### Render Pipeline

```
main loop iteration:
  1. Update music stream
  2. Process input (keyboard, mouse, file drop)
  3. Render to offscreen texture:
     a. 2D: waveform lines, waveform bars, FFT spectrum
     b. 3D: bubble visualization (with camera)
  4. Draw to screen with shader pass (chromatic aberration, noise)
  5. Draw GUI overlay (debug info, parameter controls)
```

### Audio Pipeline

The audio processor runs as a C callback on the audio thread (`processor.zig`):
- Stereo-to-mono conversion
- Exponential attack/release envelope follower
- FFT via Cooley-Tukey algorithm
- Beat detection
- RMS energy calculation

**Performance constraint**: The audio callback must not allocate. It uses fixed-size buffers only.

### Configuration System

`core/config.zig` is the single source of truth for all tunable parameters. Each config section (Audio, Shader, Visualizer.*) exposes `Scalars` and `Colors` arrays that the GUI reads at comptime to generate control widgets.

## Testing

Tests are inline within source files using Zig's `test` blocks. Key tested modules:
- `RingBuffer.zig` - capacity, read/write, wrap-around
- `audio/playback.zig` - string parsing utilities
- `audio/analysis/fft.zig` - FFT correctness

The root test in `main.zig` pulls in all modules via `_ = module;` references.

```bash
zig build test                 # Run tests
zig build test --summary all   # Detailed test output (used in CI)
```

### CI

Every push triggers `.github/workflows/test.yml`:
- Ubuntu runner with system audio/graphics dev libraries
- Zig master via `mlugg/setup-zig`
- Runs `zig build test --summary all`

## Code Conventions

- **Zig style**: follows standard Zig naming (camelCase for functions/variables, PascalCase for types/namespaces)
- **Module pattern**: each file is a module; public API via `pub` declarations
- **Config-driven**: visual parameters live in `config.zig`, not scattered across modules
- **Comptime metaprogramming**: GUI controls are generated from config struct field metadata at compile time
- **Tracy instrumentation**: performance-sensitive sections use `tracy.traceNamed(@src(), "name")` with defer `.end()`
- **Raylib wrapper**: `raylib.zig` wraps the C API; prefer using it over raw C calls
- **Inline tests**: tests go in the same file as the code they test, using `test "name" {}` blocks
- **No runtime allocation in hot paths**: audio callback and render loop avoid allocator usage
- **HSV color model**: colors throughout the system use HSV (stored as Vector3: hue 0-360, saturation 0-1, value 0-1)

## Dependencies

| Dependency | Location | Purpose |
|------------|----------|---------|
| raylib | `deps/raylib/` | Graphics, audio, window management, input |
| raygui | via raylib dep | Immediate-mode GUI widgets |
| tracy | `deps/tracy/` | Optional frame profiler (compiles as no-op stub when disabled) |

All dependencies are local path references in `build.zig.zon`. No network fetches during build.

## Keyboard Controls (Runtime)

| Key | Action |
|-----|--------|
| C | Toggle perspective/orthographic camera |
| 1/2/3 | Switch GUI tabs |
| Space | Increase audio attack envelope |
| F | Toggle fullscreen |
| P | Play/pause music |
| D | Toggle debug display (FPS, beat timeline) |
| Arrow Keys | Rotate 3D view |
| Mouse Wheel | Zoom / rotate camera |
