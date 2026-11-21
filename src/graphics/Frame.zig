//! Everything a built-in layer may read while updating or drawing one frame.
//! Layers take this instead of reaching into audio, input or window globals,
//! so a layer can be driven by any source and exercised without a device.
const rl = @import("../raylib.zig");
const Highlight = @import("Highlight.zig");
const Viewport = @import("Viewport.zig");
const Frame = @This();

/// Seconds since the previous frame, and since startup.
dt: f32,
time: f32,
/// Smoothed mono samples of the newest analysis block.
samples: []const f32,
/// Normalized magnitudes of that block's positive frequencies.
spectrum: []const f32,
/// Motion envelope: sustained level and the decaying beat pulse.
energy: f32,
pulse: f32,
viewport: Viewport,
/// Where centered layers sit, in viewport-local coordinates.
center: rl.Vector2,
camera: rl.Camera3D,
/// User rotation of the 3D layers about the vertical axis, in degrees.
rotation: f32,
/// User orientation of the halo ring.
halo_tilt: @import("visualizers/halo.zig").Tilt = .{},
focus: Highlight = .{},

/// Baseline for bottom-anchored 2D layers, in viewport-local pixels.
pub fn floor(self: Frame) f32 {
    return self.viewport.height() - 6;
}
