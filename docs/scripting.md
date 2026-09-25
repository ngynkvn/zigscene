# Lua scenes

zigscene embeds Lua 5.4.9. No separate Lua installation is required. A scene can be
an ordinary configuration table, a program that animates built-in settings, or a
complete custom 2D/3D visualizer. Audio playback, capture, the seek waveform, the
settings panels, and post-processing remain owned by the app.

## Load and edit

```sh
zig build run -- --scene=src/scripting/examples/orbit.lua
zig build run -- --scene=src/scripting/examples/sculpture.lua song.wav
```

Alternatively, drop a `.lua` file onto the window. Audio and Lua files can be
dropped together. Open **Scene / 5** to choose the embedded **Palette**, **Orbit**,
or **Sculpture** example, adjust its parameters, reload it, or **Use built-in**.
The examples' editable sources are in [`src/scripting/examples`](../src/scripting/examples).

External files auto-reload on content changes, checked every 0.75 seconds. Toggle
**Auto reload** off to edit without applying changes; press **F5** or **Reload**
to apply manually. Embedded examples have no watched file: drop their source or
use `--scene=...` to edit them live. Relative paths resolve against the app's
working directory. Save the file to persist your configuration; UI edits alone
are not written to disk.

Lua scenes currently run in the native app only (`zig build run`). Browser
builds report this limitation when a script is selected.

## Script structure

The file must return a table. Every field is optional; an empty table leaves the
built-in scene unchanged.

```lua
local phase = 0

return {
    name = "My scene",
    mode = "replace", -- "overlay" (default) or "replace"
    config = {
        window = { fps_limit = 120, always_on_top = false },
        shader = { noise_factor = 0, chroma_factor = 0 },
    },
    params = {
        { id = "radius", label = "Radius", min = 20, max = 200, default = 80 },
    },
    setup = function(ctx)
        scene.log("Ready")
    end,
    update = function(ctx)
        phase = phase + ctx.dt
    end,
    draw = function(ctx)
        local radius = scene.param("radius") * (1 + ctx.audio.energy)
        gfx.circle(ctx.width * 0.6, ctx.height * 0.4, radius,
            gfx.hsv(phase * 20, 0.7, 1))
    end,
}
```

- `overlay` draws the enabled built-in layers, then your drawing commands.
- `replace` draws only your commands. Built-in layer toggles remain available for
  when you return to an overlay or the built-in scene.
- `config` applies once when the script loads, before `setup`.
- `setup(ctx)` runs once per successful load. At initial CLI loading, context has
  the default window size and empty audio arrays; current audio arrives in the
  first frame. Reload uses the latest available frame context.
- `update(ctx)` then `draw(ctx)` run once per rendered frame. All callbacks are
  optional. Drawing functions are only allowed inside `draw`.
- `params` creates numeric sliders in Scene. IDs must be unique, at most 47 bytes;
  labels at most 63 bytes; `min < max` and `min <= default <= max`. Up to 16 sliders
  are supported. Values survive reload by ID and clamp to a changed range.
  Selecting another example/file resets parameters to its defaults.

Local variables persist between frames. Reload creates a fresh Lua state:
ordinary script variables reset, while parameter values survive. `ctx.time` is
app elapsed time and does not reset on reload or stop when audio is paused. Use
`ctx.dt` to animate independently of FPS.

## Context

| Field | Meaning |
| --- | --- |
| `ctx.width`, `ctx.height` | Current window drawing dimensions, independent of UI size |
| `ctx.time`, `ctx.dt` | Elapsed app time and the previous frame duration, in seconds |
| `ctx.audio.samples` | 1-based array of 1,024 smoothed mono waveform samples, clamped to −2…2; affected by wave strength/smoothing |
| `ctx.audio.spectrum` | 1-based array of 512 linear FFT magnitudes, `abs(FFT) / 1024`; first bin is DC; not decibels or log-spaced |
| `ctx.audio.rms` | RMS of the most recently analyzed stereo block |
| `ctx.audio.energy` | Smoothed/compressed motion energy, 0…1.5 |
| `ctx.audio.beat` | Boolean: a beat was detected in this analysis frame |
| `ctx.audio.pulse` | Beat envelope, 0…1, decaying with the configured beat decay |
| `ctx.audio.progress` | File playback fraction 0…1; zero without a file or during capture |
| `ctx.audio.playing`, `ctx.audio.capturing` | Boolean file-playing and live-capture states |
| `ctx.mouse.x`, `ctx.mouse.y` | Pointer position in window drawing coordinates |
| `ctx.mouse.down`, `ctx.mouse.wheel` | Left-button state and vertical wheel delta; suppressed over the app UI |

Audio arrays reflect the latest analyzed block, not the full track or the seek
waveform. They retain that block when playback pauses; energy and pulse still
decay. Do not assume that one analysis block corresponds to one rendering frame.
The FFT uses the mixed/captured stream; bin spacing depends on the device sample
rate, which is not currently exposed by this API.

The context and audio tables are reused each frame. Treat them as read-only;
copy data into your own table if you want history. Setup may receive empty arrays,
so guard array access with `value or 0` and check `#array`.

## Host interface

```lua
scene.get("halo.radius")       -- read the current host setting
scene.set("halo.radius", 180)  -- validated, frame-local setting change
scene.param("radius")         -- read a slider by ID
scene.log("A short message")   -- replaces the status message in Scene
```

Unknown paths/parameter IDs, incorrect types, NaN/infinity, or out-of-range
settings produce an error. Numeric strings are not settings values. Config
nesting corresponds to dotted paths: `{ halo = { radius = 180 } }` writes
`halo.radius`. A dotted key (`["halo.radius"] = 180`) also works. Boolean settings
require `true` or `false`.

Settings changes from an update/draw frame commit only if both callbacks finish
successfully. `scene.get` observes prior writes in that callback/frame. Settings
not written by the script remain under UI control; settings continuously written
by `update` or `draw` override UI edits on the next frame. Audio-analysis and
window changes take effect at their next host update; visual settings apply to
that frame's rendering.

When unloading or replacing a script, settings it wrote return to their values
from before that script. Reload starts from these original values, so removing a
config key removes its override. For failures during compile/setup, the old VM
and host settings stay active. A runtime error discards that frame's commands and
writes, unloads the failing script, restores its settings, and falls back to the
built-in scene. The error appears in Scene. Fix/save or reload to retry.

## Drawing API

2D coordinates are window drawing pixels, with origin at the top left. 3D
coordinates are world units. Commands draw in order into the scene texture,
before the app's chromatic/noise shader and UI. Colors are `{r, g, b, a}` with
components in 0…1; alpha defaults to 1. An omitted color is opaque white.

```lua
gfx.clear(color) -- clears the entire scene texture, including earlier layers
gfx.line(x1, y1, x2, y2, thickness, color)
gfx.circle(x, y, radius, color)
gfx.ring(x, y, inner_radius, outer_radius, color)
gfx.rect(x, y, width, height, color)
gfx.rect_lines(x, y, width, height, thickness, color)
gfx.triangle(x1, y1, x2, y2, x3, y3, color) -- counter-clockwise vertices
gfx.text("text", x, y, font_size, color) -- default raylib scene font

gfx.camera {
    position = {0, 3, 12}, target = {0, 0, 0},
    up = {0, 1, 0}, -- optional
    fov = 45,       -- optional, degrees; 1…150
}
gfx.line3d(x1, y1, z1, x2, y2, z2, color)
gfx.sphere(x, y, z, radius, color, wire)       -- optional wire=true/false
gfx.cube(x, y, z, width, height, depth, color, wire)

local color = gfx.hsv(hue_degrees, saturation, value, alpha)
```

`gfx.hsv` is available in any callback and returns a color array. Hue wraps;
saturation/value/alpha use 0…1. A camera command affects following 3D commands in
that frame. Without one, they use the app's current camera (C/arrow/wheel controls).
Each frame starts with that default camera again. Camera position and target must
differ, and its up vector must not be parallel to the viewing direction.

Dimensions cannot be negative, thickness must be positive, and text size is
1…512. Numeric API arguments must be finite and within ±1,000,000. Text and log
messages are at most 255 bytes. Strings may not contain embedded NULs. Arbitrary
textures, custom GLSL, file/network access, audio control, and editing the app's
UI widgets are not exposed in this version; scripts customize scene composition,
geometry, animation, colors, post-processing settings, and their own sliders.

## Settings reference

These paths are valid for both `config` and `scene.get/set`. All ranges are
inclusive. Fractional FPS values round to the nearest integer when applied.

| Path | Values |
| --- | --- |
| `window.fps_limit` | 0…360; 0 is uncapped |
| `window.opacity` | 0.15…1, native window opacity |
| `window.always_on_top` | Boolean, native only; default true |
| `interface.scale_percent` | 75…150; also fits the available window |
| `interface.panel_width` | 240…2000 logical pixels; clamped to window |
| `interface.panel_height` | 0…2000; 0 follows available height |
| `interface.show_fps` | Boolean |
| `audio.volume` | 0…1 |
| `audio.wave_blend` | 0…0.98 |
| `audio.wave_gain` | 0.1…3 |
| `motion.energy_gain` | 0.2…6 |
| `motion.compression` | 0…8 |
| `motion.attack_seconds` | 0.01…0.5 |
| `motion.release_seconds` | 0.03…1.5 |
| `motion.beat_decay_seconds` | 0.05…1 |
| `scene.wave_lines`, `scene.wave_bars`, `scene.spectrum`, `scene.bubble`, `scene.halo` | Boolean |
| `shader.chroma_factor` | 0…0.01 |
| `shader.noise_factor` | 0…0.5 |
| `shader.alpha_factor` | 0…1; background opacity |
| `wave_lines.amplitude` | 0…100 |
| `wave_bars.amplitude`, `wave_bars.base_h` | 0…100 |
| `wave_bars.trail_decay` | 0.05…2 seconds |
| `spectrum.gain` | 0.2…10 |
| `spectrum.height` | 20…300 |
| `halo.radius` | 40…260 |
| `halo.depth` | 0…220 |
| `halo.spin` | −1…1 |
| `halo.hue` | 0…359 |
| `bubble.ring_radius` | 0.1…8 |
| `bubble.sphere_radius` | 0.1…4 |
| `bubble.effect` | 0.1…1 |
| `bubble.color_scale`, `bubble.bubble_color_scale` | 0…100 |
| `bubble.height_ring` | 0…1 |

Each of `wave_lines.color1`, `wave_lines.color2`, `wave_bars.color1`,
`wave_bars.color2`, `wave_bars.trail_color`, `bubble.color1`, and `bubble.color2`
has `.h` (0…359), `.s` (0…1), and `.v` (0…1) components. These are HSV settings,
whereas drawing functions receive RGBA arrays.

## Runtime boundaries and performance

Lua has base functions plus `math`, `string`, `table`, and `utf8`. It has no
`io`, `os`, `package`, `require`, `debug`, or coroutines. `load`, `loadfile`,
`dofile`, `print`, `collectgarbage`, `setmetatable`, and `getmetatable` are removed.
Use `scene.log` for a short status message. Metatable mutation is excluded so
scripts cannot install finalizers that execute during VM teardown.

A source file is limited to 1 MiB, Lua allocations to 16 MiB per VM, and drawing
to 4,096 commands per frame. Compilation/setup gets a 500,000-instruction budget;
update and draw share 200,000 per frame. These limits catch runaway Lua loops and
allocation failures; they are not a wall-clock deadline for Lua's C library
functions or a security boundary for running untrusted code.

The runtime is single-threaded on the rendering thread. Reuse tables where
practical and sample the audio arrays at a stride for complex drawings. Heavy
geometry can lower FPS within the command budget. **D** shows CPU timing:
Lua update/command generation is included in audio/update, while executing the
commands is included in scene drawing. There is no Lua overhead when no script
is loaded beyond checking for a watched file.

See [ARCHITECTURE.md](../ARCHITECTURE.md) for ownership, the C boundary, rendering,
and build details, and the [Lua 5.4 manual](https://www.lua.org/manual/5.4/) for the
language itself.
