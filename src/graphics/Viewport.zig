//! The scene's drawing area: the window to the right of the open side panel.
//! 2D layers draw in viewport-local coordinates. 3D projections move their
//! center into the viewport without changing perspective or scale.
const Viewport = @This();
const std = @import("std");
const rl = @import("../raylib.zig");

/// Inset from the render target's left edge, in pixels.
left: f32 = 0,
/// Full render target size, in pixels.
target_width: f32,
target_height: f32,

pub fn width(self: Viewport) f32 {
    return self.target_width - self.left;
}

/// Maps a window-space projection of a world point (e.g. `GetWorldToScreen`,
/// which knows nothing of the shift) into viewport-local coordinates.
pub fn toLocal(self: Viewport, projected: rl.Vector2) rl.Vector2 {
    return .{ .x = projected.x + projectedShift(self.left) - self.left, .y = projected.y };
}

/// 3D content moves by half the inset, so its center meets the viewport's.
fn projectedShift(left: f32) f32 {
    return left / 2;
}

pub fn begin(self: Viewport) void {
    rl.rlPushMatrix();
    rl.rlTranslatef(self.left, 0, 0);
}

pub fn end(_: Viewport) void {
    rl.rlPopMatrix();
}

/// Like `BeginMode3D`, with an off-axis projection centered on the viewport.
/// Call between `begin` and `end`.
pub fn begin3D(self: Viewport, camera: rl.Camera3D) void {
    // rlgl applies a pushed 2D transform to 3D vertices too; leave it first.
    self.end();
    rl.BeginMode3D(camera);
    const r = rl.rl;
    r.rlMatrixMode(r.RL_PROJECTION);
    r.rlLoadIdentity();
    const frustum = projection(camera, self.target_width / self.target_height, projectedShift(self.left) / (self.target_width / 2), r.rlGetCullDistanceNear());
    if (camera.projection == rl.CAMERA_ORTHOGRAPHIC)
        r.rlOrtho(frustum.left, frustum.right, -frustum.top, frustum.top, r.rlGetCullDistanceNear(), r.rlGetCullDistanceFar())
    else
        r.rlFrustum(frustum.left, frustum.right, -frustum.top, frustum.top, r.rlGetCullDistanceNear(), r.rlGetCullDistanceFar());
    r.rlMatrixMode(r.RL_MODELVIEW);
}

/// `EndMode3D` resets the modelview, so the 2D offset is re-applied.
pub fn end3D(self: Viewport) void {
    rl.EndMode3D();
    self.begin();
}

/// Eases an inset toward `target`, independent of frame rate. Settles exactly
/// so an idle scene is not drawn at a drifting sub-pixel offset.
pub fn slide(current: f32, target: f32, dt: f32, time_constant: f32) f32 {
    const next = current + (target - current) * (1 - @exp(-std.math.clamp(dt, 0, 0.1) / time_constant));
    return if (@abs(target - next) < 0.25) target else next;
}

const Frustum = struct { left: f64, right: f64, top: f64 };

/// raylib's `BeginMode3D` frustum, slid horizontally so points at every depth
/// move by `shift_ndc` in normalized device coordinates.
fn projection(camera: rl.Camera3D, aspect: f32, shift_ndc: f32, near: f64) Frustum {
    const top: f64 = if (camera.projection == rl.CAMERA_ORTHOGRAPHIC)
        camera.fovy / 2.0
    else
        near * @tan(@as(f64, camera.fovy) * 0.5 * std.math.pi / 180.0);
    const right = top * aspect;
    const offset = right * shift_ndc;
    return .{ .left = -right - offset, .right = right - offset, .top = top };
}

test "off-axis projection moves the center into the viewport at any depth" {
    const target_width: f32 = 1000;
    const inset: f32 = 300;
    const shift_ndc = projectedShift(inset) / (target_width / 2);
    for ([_]c_int{ rl.CAMERA_PERSPECTIVE, rl.CAMERA_ORTHOGRAPHIC }) |kind| {
        const camera: rl.Camera3D = .{ .fovy = 45, .projection = kind };
        const unshifted = projection(camera, 1.5, 0, 0.01);
        const frustum = projection(camera, 1.5, shift_ndc, 0.01);
        // Same field of view: the image moves, it does not scale.
        try std.testing.expectApproxEqAbs(unshifted.right - unshifted.left, frustum.right - frustum.left, 1e-12);
        // A point on the camera axis (x = 0) lands at the viewport's center.
        const ndc = (0 - (frustum.right + frustum.left)) / (frustum.right - frustum.left);
        const pixel = (ndc + 1) / 2 * target_width;
        try std.testing.expectApproxEqAbs(@as(f64, inset + (target_width - inset) / 2), pixel, 1e-3);
    }
    const viewport: Viewport = .{ .left = inset, .target_width = target_width, .target_height = 600 };
    try std.testing.expectApproxEqAbs(viewport.width() / 2, viewport.toLocal(.{ .x = target_width / 2, .y = 0 }).x, 1e-4);
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
