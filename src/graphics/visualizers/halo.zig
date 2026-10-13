const Highlight = @import("../Highlight.zig");
const std = @import("std");
const rl = @import("../../raylib.zig");
const Config = @import("../../core/config.zig").Visualizer.Halo;
const Complex = @import("../../audio/analysis/fft.zig").ComplexF32;
const hsv = @import("../../ext/color.zig").Color.hsv.vec3;

const Vec3 = @Vector(3, f32);
fn cross(a: Vec3, b: Vec3) Vec3 {
    return .{ a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0] };
}

/// The ring's 3D orientation as a unit quaternion; the default draws it flat.
/// Screen axes: x right, y down, z into the screen.
pub const Tilt = struct {
    const radians_per_pixel: f32 = 0.01;
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
    w: f32 = 1,

    /// Turns the ring so its nearest point follows a drag in any direction.
    pub fn drag(self: *Tilt, dx: f32, dy: f32) void {
        const length = @sqrt(dx * dx + dy * dy);
        if (!(length > 0) or !std.math.isFinite(length)) return;
        const half = length * radians_per_pixel / 2;
        const axis = @sin(half) / length;
        // Rotating about (dy, -dx, 0) moves the point facing the viewer along the drag.
        const turn: Tilt = .{ .x = dy * axis, .y = -dx * axis, .w = @cos(half) };
        self.* = turn.then(self.*).normalized();
    }

    /// Applies `first`, then this rotation.
    fn then(self: Tilt, first: Tilt) Tilt {
        return .{
            .w = self.w * first.w - self.x * first.x - self.y * first.y - self.z * first.z,
            .x = self.w * first.x + self.x * first.w + self.y * first.z - self.z * first.y,
            .y = self.w * first.y - self.x * first.z + self.y * first.w + self.z * first.x,
            .z = self.w * first.z + self.x * first.y - self.y * first.x + self.z * first.w,
        };
    }

    fn normalized(self: Tilt) Tilt {
        const length = @sqrt(self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w);
        return .{ .x = self.x / length, .y = self.y / length, .z = self.z / length, .w = self.w / length };
    }

    fn rotate(self: Tilt, v: Vec3) Vec3 {
        const u: Vec3 = .{ self.x, self.y, self.z };
        const t = cross(u, v) * @as(Vec3, @splat(2));
        return v + t * @as(Vec3, @splat(self.w)) + cross(u, t);
    }

    /// Projects the flat ring's point at `radius` along `direction`. A focal
    /// length well beyond the ring keeps the perspective gentle and finite.
    fn project(self: Tilt, center: rl.Vector2, direction: rl.Vector2, radius: f32, focal: f32) rl.Vector2 {
        const point = self.rotate(.{ direction.x * radius, direction.y * radius, 0 });
        const scale = focal / (focal + point[2]);
        return .{ .x = center.x + point[0] * scale, .y = center.y + point[1] * scale };
    }
};

pub const Halo = struct {
    const bands = 96;
    const first_fft_bin = 2;
    const fft_bins_per_band = 3;
    const level_attack_seconds: f32 = 0.012;
    const level_release_seconds: f32 = 0.09;
    const max_frame_dt_seconds: f32 = 0.1;
    levels: [bands]f32 = @splat(0),
    phase: f32 = 0,

    pub fn update(self: *Halo, dt_seconds: f32, spectrum: []const Complex) void {
        const dt = std.math.clamp(dt_seconds, 0, max_frame_dt_seconds);
        self.phase = @mod(self.phase + dt * Config.spin, std.math.tau);
        const attack = 1 - @exp(-dt / level_attack_seconds);
        const release = 1 - @exp(-dt / level_release_seconds);
        for (&self.levels, 0..) |*level, i| {
            const bin = first_fft_bin + i * fft_bins_per_band;
            if (bin >= spectrum.len) break;
            const magnitude = spectrum[bin].magnitude() / @as(f32, @floatFromInt(spectrum.len));
            const target = std.math.clamp(@sqrt(magnitude) / (1 + @sqrt(magnitude)), 0, 1);
            level.* += (target - level.*) * (if (target > level.*) attack else release);
        }
    }

    pub fn render(self: *const Halo, center: rl.Vector2, energy: f32, pulse: f32, focus: Highlight, tilt: Tilt) void {
        const focal = 4 * (Config.radius + Config.depth + 65);
        var first_tip: rl.Vector2 = undefined;
        var previous_tip: rl.Vector2 = undefined;
        for (self.levels, 0..) |level, i| {
            const angle = self.phase + std.math.tau * @as(f32, @floatFromInt(i)) / bands;
            const direction = rl.Vector2{ .x = @cos(angle), .y = @sin(angle) };
            const inner_radius = Config.radius + energy * 20 + pulse * 14;
            const outer_radius = inner_radius + 8 + level * Config.depth + pulse * 28;
            const inner = tilt.project(center, direction, inner_radius, focal);
            const tip = tilt.project(center, direction, outer_radius, focal);
            const color = hsv(.{
                .x = Config.hue + @sin(angle) * 12 + energy * 12,
                .y = Config.saturation,
                .z = Config.brightness * std.math.clamp(0.35 + level * 0.55 + pulse * 0.15, 0, 1),
            }).into();
            rl.DrawLineEx(inner, tip, 1.5 + energy * 2 + (if (focus.selected(.halo)) @as(f32, 1.5) else 0), focus.tint(.halo, color));
            if (i == 0) {
                first_tip = tip;
            } else {
                rl.DrawLineEx(previous_tip, tip, if (focus.selected(.halo)) 2 else 1, focus.tint(.halo, color));
            }
            previous_tip = tip;
        }
        rl.DrawLineEx(previous_tip, first_tip, if (focus.selected(.halo)) 2 else 1, focus.tint(.halo, hsv(.{ .x = Config.hue, .y = Config.saturation, .z = Config.brightness * 0.55 }).into()));
    }
};

test "halo reaches a hit promptly and retains a smooth decay" {
    var halo: Halo = .{};
    var spectrum: [1024]Complex = @splat(.init(0, 0));
    spectrum[2] = .init(1024, 0);
    halo.update(0.016, &spectrum);
    halo.update(0.016, &spectrum);
    // Target is 0.5: at least 90% within 32 ms, instead of over 200 ms.
    try std.testing.expect(halo.levels[0] >= 0.45);
    const peak = halo.levels[0];
    spectrum[2] = .init(0, 0);
    halo.update(0.016, &spectrum);
    try std.testing.expect(halo.levels[0] < peak and halo.levels[0] > peak * 0.8);
}

test "tilt starts flat and follows a drag in any direction" {
    const center = rl.Vector2{ .x = 400, .y = 300 };
    const flat: Tilt = .{};
    const point = flat.project(center, .{ .x = 0.6, .y = 0.8 }, 100, 1000);
    try std.testing.expectEqual(@as(f32, 460), point.x);
    try std.testing.expectEqual(@as(f32, 380), point.y);

    // Grabbing the front and dragging right brings the left edge forward.
    var right: Tilt = .{};
    right.drag(30, 0);
    try std.testing.expect(right.rotate(.{ -1, 0, 0 })[2] < 0);
    try std.testing.expect(right.rotate(.{ 1, 0, 0 })[2] > 0);
    // Dragging down brings the top edge forward.
    var down: Tilt = .{};
    down.drag(0, 30);
    try std.testing.expect(down.rotate(.{ 0, -1, 0 })[2] < 0);
    // A diagonal drag turns about the axis across it, so both edges move.
    var diagonal: Tilt = .{};
    diagonal.drag(20, 20);
    try std.testing.expect(diagonal.rotate(.{ -1, 0, 0 })[2] < 0 and diagonal.rotate(.{ 0, -1, 0 })[2] < 0);

    // A quarter turn about the vertical axis shows the ring edge-on.
    var edge: Tilt = .{};
    edge.drag(std.math.pi / 2.0 / Tilt.radians_per_pixel, 0);
    try std.testing.expectApproxEqAbs(@as(f32, 0), edge.project(center, .{ .x = 1, .y = 0 }, 100, 1000).x - center.x, 0.01);
}

test "tilt stays a unit rotation across long drags and ignores invalid input" {
    var tilt: Tilt = .{};
    for (0..10_000) |i| tilt.drag(@floatFromInt(i % 17), -@as(f32, @floatFromInt(i % 11)));
    tilt.drag(std.math.nan(f32), 1);
    tilt.drag(0, 0);
    const length = @sqrt(tilt.x * tilt.x + tilt.y * tilt.y + tilt.z * tilt.z + tilt.w * tilt.w);
    try std.testing.expectApproxEqAbs(@as(f32, 1), length, 0.0001);
    const rotated = tilt.rotate(.{ 3, 4, 0 });
    try std.testing.expectApproxEqAbs(@as(f32, 5), @sqrt(@reduce(.Add, rotated * rotated)), 0.001);
}
