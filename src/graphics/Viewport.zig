//! The scene canvas, excluding editor chrome and the player.
//! Both 2D coordinates and the 3D viewport use this same rectangle.
const Viewport = @This();
const std = @import("std");
const rl = @import("../raylib.zig");

/// Inset from the render target's left edge, in pixels.
left: f32 = 0,
top: f32 = 0,
bottom: f32 = 0,
right: f32 = 0,
/// Full render target size, in pixels.
target_width: f32,
target_height: f32,

pub fn width(self: Viewport) f32 {
    return @max(1, self.target_width - self.left - self.right);
}
pub fn height(self: Viewport) f32 {
    return @max(1, self.target_height - self.top - self.bottom);
}
pub fn center(self: Viewport) rl.Vector2 {
    return .{ .x = self.width() / 2, .y = self.height() / 2 };
}

pub fn begin(self: Viewport) void {
    rl.rlPushMatrix();
    rl.rlTranslatef(self.left, self.top, 0);
}

pub fn end(_: Viewport) void {
    rl.rlPopMatrix();
}

/// Like `BeginMode3D`, fitted to the available canvas in both dimensions.
/// Call between `begin` and `end`.
pub fn begin3D(self: Viewport, camera: rl.Camera3D) void {
    // rlgl applies a pushed 2D transform to 3D vertices too; leave it first.
    self.end();
    rl.BeginMode3D(camera);
    const r = rl.rl;
    r.rlViewport(@intFromFloat(self.left), @intFromFloat(self.bottom), @intFromFloat(self.width()), @intFromFloat(self.height()));
    r.rlMatrixMode(r.RL_PROJECTION);
    r.rlLoadIdentity();
    var fitted_camera = camera;
    // Preserve the horizontal field of view in a narrow editor canvas too.
    const aspect = self.width() / self.height();
    if (aspect < 1) fitted_camera.fovy = if (camera.projection == rl.CAMERA_ORTHOGRAPHIC) camera.fovy / aspect else @min(150, 2 * std.math.atan(@tan(camera.fovy * std.math.pi / 360) / aspect) * 180 / std.math.pi);
    const frustum = projection(fitted_camera, aspect, r.rlGetCullDistanceNear());
    if (camera.projection == rl.CAMERA_ORTHOGRAPHIC)
        r.rlOrtho(frustum.left, frustum.right, -frustum.top, frustum.top, r.rlGetCullDistanceNear(), r.rlGetCullDistanceFar())
    else
        r.rlFrustum(frustum.left, frustum.right, -frustum.top, frustum.top, r.rlGetCullDistanceNear(), r.rlGetCullDistanceFar());
    r.rlMatrixMode(r.RL_MODELVIEW);
}

/// `EndMode3D` resets the modelview, so the 2D offset is re-applied.
pub fn end3D(self: Viewport) void {
    rl.EndMode3D();
    rl.rl.rlViewport(0, 0, @intFromFloat(self.target_width), @intFromFloat(self.target_height));
    self.begin();
}

test "editor canvas reserves panels and player in both dimensions" {
    const view: Viewport = .{ .left = 304, .top = 72, .bottom = 104, .right = 12, .target_width = 640, .target_height = 480 };
    try std.testing.expectEqual(@as(f32, 324), view.width());
    try std.testing.expectEqual(@as(f32, 304), view.height());
    try std.testing.expectEqual(@as(f32, 152), view.center().y);
}

/// Eases an inset toward `target`, independent of frame rate. Settles exactly
/// so an idle scene is not drawn at a drifting sub-pixel offset.
pub fn slide(current: f32, target: f32, dt: f32, time_constant: f32) f32 {
    const next = current + (target - current) * (1 - @exp(-std.math.clamp(dt, 0, 0.1) / time_constant));
    return if (@abs(target - next) < 0.25) target else next;
}

const Frustum = struct { left: f64, right: f64, top: f64 };

/// raylib's `BeginMode3D` frustum, centered inside the canvas.
fn projection(camera: rl.Camera3D, aspect: f32, near: f64) Frustum {
    const top: f64 = if (camera.projection == rl.CAMERA_ORTHOGRAPHIC)
        camera.fovy / 2.0
    else
        near * @tan(@as(f64, camera.fovy) * 0.5 * std.math.pi / 180.0);
    const right = top * aspect;
    return .{ .left = -right, .right = right, .top = top };
}

test "the viewport slide is frame-rate independent and settles exactly" {
    var once: f32 = 0;
    var split: f32 = 0;
    once = slide(once, 300, 0.05, 0.12);
    split = slide(split, 300, 0.025, 0.12);
    split = slide(split, 300, 0.025, 0.12);
    try std.testing.expectApproxEqAbs(once, split, 0.001);
    try std.testing.expect(once > 0 and once < 300);
    var left: f32 = 0;
    for (0..60) |_| left = slide(left, 300, 1.0 / 60.0, 0.12);
    try std.testing.expectEqual(@as(f32, 300), left);
    // A long stall cannot overshoot or jump straight past the easing.
    try std.testing.expect(slide(0, 300, 5, 0.12) < 300);
}
