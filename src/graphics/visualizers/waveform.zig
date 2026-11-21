const Frame = @import("../Frame.zig");
const Highlight = @import("../Highlight.zig");
const std = @import("std");
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

    /// The waveform above the scene center and the spectrum below it.
    pub fn render(frame: Frame) void {
        const count = frame.samples.len;
        if (count == 0) return;
        const style = Style.init(frame.focus);
        const spacing = frame.viewport.width() / ffi(f32, count);
        for (frame.samples, 0..) |value, i| plot(frame.center.y - 80, spacing, i, value, style);
        if (frame.spectrum.len == 0) return;
        // The lower line spans the whole transform: a real signal's upper
        // half mirrors its lower half.
        const last_bin = frame.spectrum.len - 1;
        for (0..count) |i| {
            const bin = @min(i, count - i, last_bin);
            plot(frame.center.y * 2, spacing, i, frame.spectrum[bin] * 1.2, style);
        }
    }

    fn plot(baseline: f32, spacing: f32, i: usize, v: f32, style: Style) void {
        const px = ffi(f32, i) * spacing;
        const py = baseline - std.math.clamp(v * Config.amplitude, -250, 250);
        // zig fmt: off
        rl.DrawRectangleRec(.{ .x = px, .y = py,      .width = spacing, .height = if (style.emphasized) 3 else 1 }, style.primary);
        rl.DrawRectangleRec(.{ .x = px, .y = py + 8,  .width = spacing, .height = if (style.emphasized) 4 else 2 }, style.secondary);
        // zig fmt: on
    }
};

pub const WaveFormBar = struct {
    const Config = @import("../../core/config.zig");
    const N = Config.Audio.buffer_size;
    const WaveConfig = Config.Visualizer.WaveFormBar;
    /// Decaying peak height per sample column: the trail behind each bar.
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
        for (&self.maxes) |*value| value.* = @max(WaveConfig.base_h, value.* * factor);
    }

    pub fn render(self: *WaveFormBar, frame: Frame) void {
        const count = @min(frame.samples.len, self.maxes.len);
        if (count == 0) return;
        const style = Style.init(frame.focus);
        const spacing = frame.viewport.width() / ffi(f32, count);
        const base = WaveConfig.base_h;
        const floor = frame.floor();
        for (frame.samples[0..count], self.maxes[0..count], 0..) |value, *max, i| {
            const px = ffi(f32, i) * spacing;
            const y = std.math.clamp(@abs(value) * WaveConfig.amplitude, 0, 350);
            max.* = @max(y + base, max.*);
            rl.DrawRectangleRec(.{
                .x = px,
                .y = floor - max.*,
                .width = spacing,
                .height = max.*,
            }, style.trail);
            rl.DrawRectangleGradientEx(.{
                .x = px,
                .y = floor - y - base,
                .width = spacing,
                .height = y + base,
            }, style.primary, style.secondary, style.secondary, style.primary);
        }
    }
};
