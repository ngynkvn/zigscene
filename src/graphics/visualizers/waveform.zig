const Highlight = @import("../Highlight.zig");
const std = @import("std");
const processor = @import("../../audio/processor.zig");
const hsv = @import("../../ext/color.zig").Color.hsv.vec3;
const cnv = @import("../../ext/convert.zig");
const ffi = cnv.ffi;
const rl = @import("../../raylib.zig");

comptime {
    @setFloatMode(.optimized);
}

pub const WaveFormLine = struct {
    const Config = @import("../../core/config.zig").Visualizer.WaveFormLine;
    pub const Style = struct {
        primary: rl.Color,
        secondary: rl.Color,
        emphasized: bool,

        pub fn init(focus: Highlight) Style {
            return .{
                .primary = focus.tint(.wave_lines, hsv(Config.color1).into()),
                .secondary = focus.tint(.wave_lines, hsv(Config.color2).into()),
                .emphasized = focus.selected(.wave_lines),
            };
        }
    };

    pub fn render(center: rl.Vector2, width: f32, i: usize, v: f32, style: Style) void {
        const amplitude: f32 = Config.amplitude;
        const SPACING = width / ffi(f32, processor.curr_buffer.len);
        const x = ffi(f32, i) * SPACING;
        const y = -std.math.clamp(v * amplitude, -250, 250);
        // "plot" x and y
        const px = x + center.x;
        const py = y + center.y;
        // zig fmt: off
        rl.DrawRectangleRec(.{ .x = px, .y = py,      .width = SPACING, .height = if (style.emphasized) 3 else 1 }, style.primary);
        rl.DrawRectangleRec(.{ .x = px, .y = py + 8,  .width = SPACING, .height = if (style.emphasized) 4 else 2 }, style.secondary);
        // zig fmt: on
    }
};

pub const WaveFormBar = struct {
    const Config = @import("../../core/config.zig");
    const N = Config.Audio.buffer_size;
    const WaveConfig = Config.Visualizer.WaveFormBar;
    const amplitude: *f32 = &WaveConfig.amplitude;
    const base_h: *f32 = &WaveConfig.base_h;
    maxes: [N]f32 = @splat(0),

    pub const Style = struct {
        primary: rl.Color,
        secondary: rl.Color,
        trail: rl.Color,

        pub fn init(focus: Highlight) Style {
            return .{
                .primary = focus.tint(.wave_bars, hsv(WaveConfig.color1).into()),
                .secondary = focus.tint(.wave_bars, hsv(WaveConfig.color2).into()),
                .trail = focus.tint(.wave_bars, hsv(WaveConfig.trail_color).into()),
            };
        }
    };

    pub fn advance(self: *WaveFormBar, dt_seconds: f32) void {
        const factor = @exp(-@min(dt_seconds, 0.1) / @max(WaveConfig.trail_decay, 0.01));
        for (&self.maxes) |*value| value.* = @max(base_h.*, value.* * factor);
    }

    pub fn render(self: *WaveFormBar, floor: f32, width: f32, i: usize, v: f32, style: Style) void {
        const SPACING = width / ffi(f32, processor.curr_buffer.len);
        const x = ffi(f32, i) * SPACING;
        const y = std.math.clamp(@abs(v) * amplitude.*, 0, 350);
        const px = x;
        self.maxes[i] = @max(y + base_h.*, self.maxes[i]);
        rl.DrawRectangleRec(.{
            .x = px,
            .y = floor - self.maxes[i],
            .width = SPACING,
            .height = self.maxes[i],
        }, style.trail);
        rl.DrawRectangleGradientEx(.{
            .x = px,
            .y = floor - y - base_h.*,
            .width = SPACING,
            .height = y + base_h.*,
        }, style.primary, style.secondary, style.secondary, style.primary);
    }
};
