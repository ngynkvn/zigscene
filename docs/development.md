# Development

[Project home](../README.md) · [All docs](README.md) ·
[Architecture](../ARCHITECTURE.md) · [Lua scenes](scripting.md)

Use **Zig 0.16.0**. Run the commands below from the repository root.

**On this page:** [Setup](#setup) · [Native builds](#native-builds) ·
[Tests](#tests) · [Web build](#web-build) · [Release builds](#release-builds) ·
[Diagnostics](#profiling-and-diagnostics) · [Code changes](#where-to-change-the-code)

## Setup

Clone the repository and check your Zig version:

```sh
git clone https://github.com/ngynkvn/zigscene
cd zigscene
zig version # should print 0.16.0
```

The build fetches its pinned dependencies; no separate Lua interpreter is needed.
See [build.zig.zon](../build.zig.zon) for dependencies and
[build.zig](../build.zig) for build options.

### Linux dependencies

On Ubuntu, the CI build installs these development packages:

```sh
sudo apt install -y \
  libasound2-dev libx11-dev libxrandr-dev libxi-dev \
  libgl1-mesa-dev libglu1-mesa-dev libxcursor-dev libxinerama-dev \
  libwayland-dev libxkbcommon-dev
```

The native development build selects X11. The release build step uses raylib's
default backend configuration, which also needs Wayland development tools.
See [CI](../.github/workflows/test.yml) for the current build environment.

## Native builds

| Command | Result |
| --- | --- |
| `zig build` | Debug application in `zig-out/bin` |
| `zig build run` | Build and launch |
| `zig build run -- song.wav` | Launch with a track |
| `zig build run -- --scene=src/scripting/examples/orbit.lua song.wav` | Launch with a Lua scene and track |
| `zig build -Doptimize=ReleaseSafe` | Optimized application with safety checks |
| `zig build run -Doptimize=ReleaseFast` | Build and run with ReleaseFast optimization |
| `zig build check` | Compile the native app and run both test roots |

Debug builds retain application checks while compiling raylib and Lua with
ReleaseSafe optimization. To debug raylib without that optimization, use
`zig build -Draylib-optimize=Debug`.

### Isolate preferences for manual checks

The native app saves settings on exit. On Linux, use a scratch config directory
so test runs do not overwrite your usual settings. This example also mutes output:

```sh
mkdir -p /tmp/zigscene-check/zigscene
printf 'audio.volume=0\n' > /tmp/zigscene-check/zigscene/settings.conf
XDG_CONFIG_HOME=/tmp/zigscene-check zig build run -- song.wav
```

On other platforms, use a test account or back up the
[settings file](usage.md#saved-settings) before a manual run.

## Tests

Run these checks before recording a change:

```sh
zig fmt --check src
zig build test --summary all
zig build
zig build release-build
```

There are two test roots:

| Root | Coverage |
| --- | --- |
| [`src/main.zig`](../src/main.zig) | Raylib-linked audio/preview, capture selection, UI geometry, viewport, preferences, and Lua integration |
| [`src/audio_test.zig`](../src/audio_test.zig) | Queue ordering, CLI, motion, geometry, FFT, beat detection, and frame analysis without raylib |

**Register tests explicitly.** Add a file to a root's `test` block when adding
its tests; an ordinary transitive import does not ensure they run. The headless
suite does not open a window or audio device. Raylib file-decoding tests disable
its stdout trace logging because Zig uses stdout for its test-runner protocol.

For visual or input changes, also run the app and check the affected controls,
window sizes, and built-in/Lua scenes. CPU tests cannot verify GPU output.

CI runs Linux tests, native and Windows release builds, a macOS release build,
and a web build with bundle validation. See the
[test workflow](../.github/workflows/test.yml).

## Web build

Install and activate the [Emscripten SDK](https://emscripten.org/docs/getting_started/downloads.html).
The repository's CI uses Emscripten `6.0.5`. With `EMSDK` set:

```sh
zig build web -Dtarget=wasm32-emscripten -Doptimize=ReleaseSafe \
  --sysroot "$EMSDK/upstream/emscripten"

# Build and serve locally with emrun
zig build web-run -Dtarget=wasm32-emscripten -Doptimize=ReleaseSafe \
  --sysroot "$EMSDK/upstream/emscripten"
```

The deployable bundle is written to `zig-out/web`. Serve it over HTTP rather than
opening the HTML file directly.

The browser target is experimental. It supports dropped audio files, but Lua
scenes, native live capture, native window management, and saved preferences are
unavailable. Playback refills and preview generation run on the browser thread.
Keep native thread/file paths guarded for Emscripten.

## Release builds

`zig build release-build` builds ReleaseSafe binaries for the host and
x86_64 Windows, under target-specific directories in `zig-out`. Additional Linux
cross-targets are currently disabled because of the raylib display dependencies;
the release workflow builds Linux natively.

Publishing a GitHub release triggers the [release workflow](../.github/workflows/release.yml).
It packages macOS Apple Silicon and Linux x86_64 binaries as `.tar.gz`, Windows
x86_64 as `.zip`, and the web bundle as `.zip`. Unix archives retain executable
permissions.

## Profiling and diagnostics

Press **D** or click the FPS counter to see CPU timings for audio/update, scene
drawing, UI, and presentation/wait. Lua update and command generation are part of
audio/update; executing Lua drawing commands is part of scene drawing.
Presentation/wait includes frame-cap sleep, so it is not GPU-only timing.

Use a consistent optimization mode, track, source/device rate, and window size
when comparing runs. Measure memory and timing rather than extrapolating from
track duration. On Linux, `/proc/self/status` exposes peak resident memory as
`VmHWM`; its reported file length is zero, so read its contents rather than
allocating from the file length.

The [audio experiment](audio-experiment.md) includes an offline frame-analysis
benchmark command and its original measurements. Those results describe that
analysis pass, not overall application performance.

## Where to change the code

Start with the [module map](../ARCHITECTURE.md#module-map). The architecture guide
also describes [frame flow](../ARCHITECTURE.md#frame-flow),
[audio workers](../ARCHITECTURE.md#audio-and-the-seek-waveform),
[Lua ownership](../ARCHITECTURE.md#lua-boundary), and
[adding settings or drawing primitives](../ARCHITECTURE.md#extending-the-interface).

Use the [Lua guide](scripting.md) when a change only needs a new scene rather than
an application change.
