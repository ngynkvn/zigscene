const Highlight = @import("../Highlight.zig");
const std = @import("std");
const processor = @import("../../audio/processor.zig");
var screenWidth: c_int = @import("../../core/config.zig").Window.width;
const hsv = @import("../../ext/color.zig").Color.hsv.vec3;
const cnv = @import("../../ext/convert.zig");
const ffi = cnv.ffi;
const rl = @import("../../raylib.zig");

comptime {
    @setFloatMode(.optimized);
}

pub const WaveFormLine = struct {
    const Config = @import("../../core/config.zig").Visualizer.WaveFormLine;
    pub fn render(center: rl.Vector2, i: usize, v: f32, focus: Highlight) void {
        const amplitude: f32 = Config.amplitude;
        const color1 = Config.color1;
        const color2 = Config.color2;
        const SPACING = ffi(f32, screenWidth) / ffi(f32, processor.curr_buffer.len);
        const x = ffi(f32, i) * SPACING;
        const y = -std.math.clamp(v * amplitude, -250, 250);
        // "plot" x and y
        const px = x + center.x;
        const py = y + center.y;
        // zig fmt: off
        rl.DrawRectangleRec(.{ .x = px, .y = py,      .width = SPACING, .height = if (focus.selected(.wave_lines)) 3 else 1 }, focus.tint(.wave_lines, hsv(color1).into()));
        rl.DrawRectangleRec(.{ .x = px, .y = py + 8,  .width = SPACING, .height = if (focus.selected(.wave_lines)) 4 else 2 }, focus.tint(.wave_lines, hsv(color2).into()));
        // zig fmt: on
    }
};

pub const WaveFormBar = struct {
    const Config = @import("../../core/config.zig");
    const N = Config.Audio.buffer_size;
    const WaveConfig = Config.Visualizer.WaveFormBar;
    const amplitude: *f32 = &WaveConfig.amplitude;
    const base_h: *f32 = &WaveConfig.base_h;
    const color1 = &WaveConfig.color1;
    const color2 = &WaveConfig.color2;
    const trail_color = &WaveConfig.trail_color;
    maxes: [N]f32 = @splat(0),

    pub fn advance(self: *WaveFormBar, dt_seconds: f32) void {
        const factor = @exp(-@min(dt_seconds, 0.1) / @max(WaveConfig.trail_decay, 0.01));
        for (&self.maxes) |*value| value.* = @max(base_h.*, value.* * factor);
    }

    pub fn render(self: *WaveFormBar, floor: f32, i: usize, v: f32, focus: Highlight) void {
        const SPACING = ffi(f32, screenWidth) / ffi(f32, processor.curr_buffer.len);
        const x = ffi(f32, i) * SPACING;
        const y = std.math.clamp(@abs(v) * amplitude.*, 0, 350);
        const px = x;
        const c1 = focus.tint(.wave_bars, hsv(color1.*).into());
        const c2 = focus.tint(.wave_bars, hsv(color2.*).into());
        self.maxes[i] = @max(y + base_h.*, self.maxes[i]);
        rl.DrawRectangleRec(.{
            .x = px,
            .y = floor - self.maxes[i],
            .width = SPACING,
            .height = self.maxes[i],
        }, focus.tint(.wave_bars, hsv(trail_color.*).into()));
        rl.DrawRectangleGradientEx(.{
            .x = px,
            .y = floor - y - base_h.*,
            .width = SPACING,
            .height = y + base_h.*,
        }, c1, c2, c2, c1);
    }
};

pub fn onWindowResize(width: i32, _: i32) void {
    screenWidth = width;
}
