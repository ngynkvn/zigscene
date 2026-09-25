# Audio refill and SIMD experiment

Bookmark: `experimental/audio-refill-simd`.

## Playback reliability

Native playback previously called `UpdateMusicStream` only from `App.frame`.
Delayed rendering, window event handling, or scripts could exhaust the stream
buffers. A dedicated producer now refills every 5 ms. Its mutex serializes
playback controls with decoding; track replacement and shutdown join the worker
before releasing the stream. Play/resume primes the buffers immediately.
Browsers and worker-start failures retain frame-driven updates.

An offline probe of the pinned raylib mixer used a 440 Hz stereo WAV, a 48 kHz
output, 10 ms output blocks, and delayed refills every 500 ms. Over 300 blocks:

| Source rate | Frame-driven silent blocks | Worker-driven silent blocks |
| --- | ---: | ---: |
| 48 kHz | 57 | 0 |
| 96 kHz | 138 | 0 |

These are Linux-host offline mixer measurements, not Windows hardware results.
The app was not launched. The committed worker regression test exercises a
500 ms main-thread stall, control serialization, shutdown, and repeated starts
without opening a window or audio device. Windows listening verification is
still needed; this does not rule out device/backend-specific problems.

## SIMD analysis

`src/audio/analysis/frame.zig` uses four-lane Zig vectors for stereo-to-mono
conversion, waveform smoothing/clamping, FFT input preparation, and energy
accumulation. It processes tails scalarly and retains a scalar reference.
It only processes analysis copies; it does not modify audible output.

Four lanes support baseline x86-64 without requiring AVX. Inspection of the
baseline build confirmed packed SSE operations (`shufps`, `mulps`, `addps`).
Tests compare all output samples and RMS against the scalar reference for empty,
short, full, and odd-length blocks, smoothing endpoints, clamping, and silence.
Floating-point reduction order changes slightly; RMS comparisons allow 1e-5.

Run the offline benchmark (no app/window/audio device):

```sh
zig run -O ReleaseSafe -mcpu=baseline --dep frame \
  -Mroot=dev/audio_bench.zig -Mframe=src/audio/analysis/frame.zig
```

Four alternating-order measurements on the development host reported
1,321–1,423 ns/block scalar versus 707–734 ns/block SIMD, about 1.8–2.0x for
this analysis pass. This is not an overall application speedup or a Windows
benchmark. The recursive FFT remains unchanged and may dominate analysis cost.

Validation commands:

```sh
zig build check
zig build test -Doptimize=ReleaseSafe
zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSafe \
  --prefix release/windows-experimental
```
