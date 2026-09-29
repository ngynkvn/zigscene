# Codebase review and feature opportunities

Reviewed 2026-09-29 against the current working tree, including the existing audio changes.
The implementation change in this pass is the compact UI; the items below are follow-up recommendations.

The review covers the active application in `src`, Zig/C audio and Lua boundaries,
shader and scene sources, tests, build/dependency adapters, CI/release workflows,
and current documentation. Historical experiments under `notes` were used for context;
generated files, media assets, and upstream dependency internals were not audited.
This is a source review and local validation, not a claim of exhaustive platform testing.

The strongest foundations are the bounded audio queue, independent refill worker,
fixed-memory waveform preview, transactional Lua reload, and shared settings registry.
These support substantial improvements without replacing the renderer or audio architecture.

## Findings to address

| Priority | Finding and concrete effect | Suggested change |
| --- | --- | --- |
| Medium | **A failed file load discards the current session.** `Session.playFile` stops capture before validating the new file, and `playback.loadFile` unloads the existing music before calling `LoadMusicStream`. Dropping an unsupported or corrupt file therefore stops working playback/capture. | Load and validate a candidate first; replace the active stream and source only after success. Add a regression that loads a bad file while a valid track is playing. |
| Medium | **Abandoned previews still decode to completion.** `abandonPreview` only marks a result for discard; the decode loop does not observe cancellation. A new track's preview waits for that work, and `stopPreview` joins it synchronously on exit. This can delay new previews and shutdown on long files. | Add an atomic cancellation flag checked between decode chunks, keep decoder teardown on the worker, and expose loading/error status in the player. Measure cancellation and shutdown latency on a long track. |
| Low, latent | **Vector equality is incorrect.** `feql` computes `x - x` and `y - y`, so finite unequal inputs compare equal. The Vector3/4 equality wrappers also return `c_int` from a Boolean expression. There are no active callers, so the ordinary application build does not exercise these helpers. | Replace with a defined approximate comparison, fix the return types, and test unequal vectors. Consider retaining only the math helpers the application uses. |

Source locations: [session transitions](../src/audio/Session.zig),
[stream loading and preview jobs](../src/audio/playback.zig),
[vector helpers](../src/ext/vector.zig).
These findings are based on control-flow inspection; this pass did not change those modules.

## Recommended feature sequence

| Order | Enhancement | Why it fits this codebase | First useful version |
| --- | --- | --- | --- |
| 1 | **Named visual presets** | Preferences already serialize stable setting names, but there is only one saved configuration. Lua parameters and the chosen script are not restored across launches. | Save/load/duplicate a named look containing visual settings, scene reference, and parameter values. Keep machine settings such as capture devices and window opacity separate. |
| 2 | **Undo, redo, and reset per control/group** | Exploration currently changes global settings immediately. Users cannot easily compare a change or recover a look. | Record one operation per completed drag or numeric edit; add group reset and a visible modified indicator. Define how user edits interact with script-owned values before implementing history. |
| 3 | **Layer inspector with search and solo** | A layer's visibility, shape, color, and motion controls are split across tabs, while `Highlight.Element` already identifies the affected layer. | Select a layer to see its related controls together; add solo and collapsible groups. Keep the existing tabs as quick entry points and expose which values a Lua scene is driving. |
| 4 | **Full color editing and palette swatches** | The settings registry already stores hue, saturation, and value, but the Color tab exposes hue only. Spectrum colors are hard-coded. | Add saturation/brightness and reusable swatches, then make spectrum colors configurable. Retain a compact collapsed view showing the current color. |
| 5 | **A/B loop and a small track queue** | The player has an accurate seek surface, while multi-file drop currently keeps only the last non-Lua path. | Add two loop markers, repeat mode, and next/previous controls. Queue all valid dropped tracks; preserve the active track when another file fails. |
| 6 | **Scene-only export and presentation mode** | Scene rendering already happens in an offscreen texture, separate from the UI. | Start with a PNG export and one action to hide all UI. Follow with deterministic video export using a fixed timestep and an audio clock; screen recording alone would not guarantee synchronization. |
| 7 | **Audio mapping and source diagnostics** | Lua receives RMS, beat, waveform, and spectrum, but built-in mappings are fixed and the capture picker gives limited signal feedback. | Expose bass/mid/treble envelopes, an input meter, silence/disconnection status, and mappings from an envelope to a selected visual parameter. Add tempo estimation only after testing the current onset detector across different material. |
| 8 | **Keyboard navigation and contextual help** | Number shortcuts select tabs, but individual controls depend on pointer interaction and custom drawing exposes no semantic controls to accessibility tools. | Add visible focus, Tab/Shift-Tab traversal, arrow-key adjustment, and a shortcut/help overlay. Treat native accessibility semantics as a separate implementation requirement. |

Start with presets and undo/reset: together they make trying unfamiliar settings much safer.
The inspector and color controls then make the existing visual capabilities easier to discover.

## Maintenance opportunities

- Split `gui.zig` into panel, player, and interaction modules before adding substantial new UI.
  Keep shared geometry in one place; draw bounds, scroll extents, and hit testing must agree.
  The empty `gui/layout.zig` and `gui/state.zig`, and the unused `panel_layout.zig`, should either
  gain an explicit role or be removed in a cleanup.
- Consolidate setting metadata. GUI scalar groups and the Lua/preferences registry currently
  repeat names and ranges; presets, reset values, help text, and search will need richer metadata.
- Add browser runtime smoke checks. CI validates the generated bundle but does not open it,
  compile the shaders in a browser, or exercise dropped-file playback.
- Extend decoder parity fixtures to MP3, OGG, multichannel input, and fallback formats.
  The streaming decoder parity test currently uses a stereo WAV fixture.
- Make script reload checks cheaper for unchanged files before supporting large scene libraries:
  the watcher currently reads and hashes the source every 0.75 seconds on the frame thread.
- Refresh stale local guidance: `CLAUDE.md` still describes an older Zig version, architecture,
  and profiling option names. Keep historical notes clearly separate from current documentation.

## Compact UI implemented

| Element | Before | After |
| --- | --- | --- |
| Outer margin | 16 | 12 |
| Header height | 58 | 48 |
| Player height | 148 | 124 |
| Scalar/color/Lua parameter row spacing | 52 | 44 |
| Group heading allocation | 38 | 30 |
| Layer card / row spacing | 66 / 76 | 58 / 66 |
| Panel content height at 1024 × 768, automatic height | 392 | 464 |

Dimensions are logical UI units. Control typography, the 18-unit slider hit areas,
24-unit numeric fields, panel width preferences, UI scaling, tab scroll memory,
resize grips, and the waveform seek surface remain available. The Show shortcut
hint now matches the existing `2` key; Hide remains `1`.

Validation: `zig fmt --check src`, `zig build`, `zig build check` (99 tests), and
`zig build release-build` (native macOS and Windows cross-build). The native app's
Shape and Lua Scene layouts were visually inspected at the default window size,
and scrolling to the final layer card was verified. Automated clicks/keypresses did
not activate the GLFW controls reliably, so interactive click/drag and small-window
visual checks remain a manual validation limitation. Geometry and interaction unit
tests passed. No live capture hardware or browser runtime testing was performed.
