const Frame = @import("../Frame.zig");
const std = @import("std");
const rl = @import("../../raylib.zig");
const Config = @import("../../core/config.zig").Visualizer.Spectrum;

comptime {
    @setFloatMode(.optimized);
}

pub const FFTSpectrum = struct {
    const column_spacing: f32 = 4;
    /// Lowest plotted bin; bin 0 is the DC offset, not a frequency.
    const first_bin: f32 = 1;

    /// Log-frequency analyzer across the viewport, standing on the floor.
    pub fn render(frame: Frame) void {
        const bins = frame.spectrum;
        if (bins.len < 2) return;
        const floor = frame.floor();
        const width = frame.viewport.width();
        const focus = frame.focus;
        const columns: usize = @intFromFloat(@max(1, width / column_spacing));
        const bar_width = @max(1, width / @as(f32, @floatFromInt(columns)) - 1);
        const hsv = @import("../../ext/color.zig").Color.hsv.vec3;
        const tips = focus.tint(.spectrum, hsv(Config.color1).into());
        const body = focus.tint(.spectrum, hsv(Config.color2).into());
        for (0..columns) |column| {
            const x = @as(f32, @floatFromInt(column)) * width / @as(f32, @floatFromInt(columns));
            const raw = @sqrt(@max(0, columnMagnitude(bins, column, columns))) * Config.gain;
            const y = Config.height * (raw / (1 + raw));
            const py = floor - y - 5;
            rl.DrawRectangleRec(.{ .x = x, .y = py, .width = bar_width, .height = 2 }, tips);
            rl.DrawRectangleRec(.{ .x = x, .y = py + 12, .width = bar_width, .height = @max(0, y - 7) }, body);
        }
    }

    /// Peak magnitude of the bins a column covers. Columns narrower than one
    /// bin (low frequencies) interpolate between neighbours instead of stepping.
    fn columnMagnitude(bins: []const f32, column: usize, columns: usize) f32 {
        const last: f32 = @floatFromInt(bins.len - 1);
        const start = binAt(column, columns, last);
        const end = binAt(column + 1, columns, last);
        if (end - start < 1) {
            const center = (start + end) / 2;
            const index: usize = @intFromFloat(center);
            const next = @min(index + 1, bins.len - 1);
            return std.math.lerp(bins[index], bins[next], center - @floor(center));
        }
        var peak: f32 = 0;
        for (bins[@intFromFloat(@ceil(start)) .. @as(usize, @intFromFloat(@floor(end))) + 1]) |bin| peak = @max(peak, bin);
        return peak;
    }

    fn binAt(column: usize, columns: usize, last: f32) f32 {
        const t = @as(f32, @floatFromInt(column)) / @as(f32, @floatFromInt(columns));
        return first_bin * std.math.pow(f32, last / first_bin, t);
    }
};

test "columns cover the lower half of the spectrum in rising order" {
    var spectrum: [512]f32 = undefined;
    for (&spectrum, 0..) |*bin, i| bin.* = @floatFromInt(i);
    var previous: f32 = 0;
    for (0..256) |column| {
        const magnitude = FFTSpectrum.columnMagnitude(&spectrum, column, 256);
        try std.testing.expect(magnitude >= previous);
        previous = magnitude;
    }
    // The lowest column starts at bin 1 (not DC) and the highest reaches the last bin.
    try std.testing.expectApproxEqAbs(@as(f32, 1), FFTSpectrum.columnMagnitude(&spectrum, 0, 256), 0.05);
    try std.testing.expectApproxEqAbs(@as(f32, 511), FFTSpectrum.columnMagnitude(&spectrum, 255, 256), 1);
}
