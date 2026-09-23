const Highlight = @import("../Highlight.zig");
const std = @import("std");
const rl = @import("../../raylib.zig");
const Config = @import("../../core/config.zig").Visualizer.Halo;
const Complex = @import("../../audio/analysis/fft.zig").ComplexF32;
const hsv = @import("../../ext/color.zig").Color.hsv.vec3;

pub const Halo = struct {
    const bands = 96;
    const first_fft_bin = 2;
    const fft_bins_per_band = 3;
    const level_smoothing_seconds: f32 = 0.09;
    const max_frame_dt_seconds: f32 = 0.1;
    levels: [bands]f32 = @splat(0),
    phase: f32 = 0,

    pub fn update(self: *Halo, dt_seconds: f32, spectrum: []const Complex) void {
        const dt = std.math.clamp(dt_seconds, 0, max_frame_dt_seconds);
        self.phase = @mod(self.phase + dt * Config.spin, std.math.tau);
        const blend = 1 - @exp(-dt / level_smoothing_seconds);
        for (&self.levels, 0..) |*level, i| {
            const bin = first_fft_bin + i * fft_bins_per_band;
            if (bin >= spectrum.len) break;
            const magnitude = spectrum[bin].magnitude() / @as(f32, @floatFromInt(spectrum.len));
            const target = std.math.clamp(@sqrt(magnitude) / (1 + @sqrt(magnitude)), 0, 1);
            level.* += (target - level.*) * blend;
        }
    }

    pub fn render(self: *const Halo, center: rl.Vector2, energy: f32, pulse: f32, focus: Highlight) void {
        var first_tip: rl.Vector2 = undefined;
        var previous_tip: rl.Vector2 = undefined;
        for (self.levels, 0..) |level, i| {
            const angle = self.phase + std.math.tau * @as(f32, @floatFromInt(i)) / bands;
            const direction = rl.Vector2{ .x = @cos(angle), .y = @sin(angle) };
            const inner_radius = Config.radius + energy * 20 + pulse * 14;
            const outer_radius = inner_radius + 8 + level * Config.depth + pulse * 28;
            const inner = rl.Vector2{ .x = center.x + direction.x * inner_radius, .y = center.y + direction.y * inner_radius };
            const tip = rl.Vector2{ .x = center.x + direction.x * outer_radius, .y = center.y + direction.y * outer_radius };
            const color = hsv(.{
                .x = Config.hue + @as(f32, @floatFromInt(i)) * 1.6 + energy * 80,
                .y = 0.75,
                .z = std.math.clamp(0.35 + level * 0.55 + pulse * 0.15, 0, 1),
            }).into();
            rl.DrawLineEx(inner, tip, 1.5 + energy * 2 + (if (focus.selected(.halo)) @as(f32, 1.5) else 0), focus.tint(.halo, color));
            if (i == 0) {
                first_tip = tip;
            } else {
                rl.DrawLineEx(previous_tip, tip, if (focus.selected(.halo)) 2 else 1, focus.tint(.halo, color));
            }
            previous_tip = tip;
        }
        rl.DrawLineEx(previous_tip, first_tip, if (focus.selected(.halo)) 2 else 1, focus.tint(.halo, hsv(.{ .x = Config.hue, .y = 0.75, .z = 0.55 }).into()));
    }
};
