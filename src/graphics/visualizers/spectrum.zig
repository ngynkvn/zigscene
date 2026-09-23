const Highlight = @import("../Highlight.zig");
const processor = @import("../../audio/processor.zig");
var screenWidth: c_int = @import("../../core/config.zig").Window.width;
const cnv = @import("../../ext/convert.zig");
const ffi = cnv.ffi;
const rl = @import("../../raylib.zig");
const Config = @import("../../core/config.zig").Visualizer.Spectrum;

comptime {
    @setFloatMode(.optimized);
}

pub fn onWindowResize(width: i32, _: i32) void {
    screenWidth = width;
}

pub const FFTSpectrum = struct {
    pub fn render(center: rl.Vector2, i: usize, v: f32, focus: Highlight) void {
        const SPACING = ffi(f32, screenWidth) / ffi(f32, processor.curr_buffer.len);
        const x = ffi(f32, i) * SPACING;
        const raw = @sqrt(@max(0, v) / @as(f32, @floatFromInt(processor.curr_buffer.len))) * Config.gain;
        const y = Config.height * (raw / (1 + raw));
        // "plot" x and y
        const px = x;
        const py = -y + center.y * 2 - 5;
        rl.DrawRectangleRec(.{ .x = px, .y = py, .width = 2, .height = 2 }, focus.tint(.spectrum, rl.RAYWHITE));
        rl.DrawRectangleRec(.{ .x = px, .y = py + 12, .width = 2, .height = y + 2 }, focus.tint(.spectrum, rl.RED));
    }
};
