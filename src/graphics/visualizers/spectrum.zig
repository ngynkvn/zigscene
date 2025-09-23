const rl = @import("raylibz");

const processor = @import("../../audio/processor.zig");
var screenWidth: c_int = @import("../../core/config.zig").Window.width;

comptime {
    @setFloatMode(.optimized);
}

pub fn onWindowResize(width: i32, _: i32) void {
    screenWidth = width;
}

pub const FFTSpectrum = struct {
    pub fn render(center: rl.Vector2, i: usize, v: f32) void {
        const SPACING = @as(f32, @floatFromInt(screenWidth)) / @as(f32, @floatFromInt(processor.curr_buffer.len));
        const x = @as(f32, @floatFromInt(i)) * SPACING;
        const y = v;
        // "plot" x and y
        const px = x;
        const py = -y + center.y * 2 - 5;
        rl.drawRectangleRec(.{ .x = px, .y = py, .width = 2, .height = 2 }, rl.RAYWHITE);
        rl.drawRectangleRec(.{ .x = px, .y = py + 12, .width = 2, .height = y + 2 }, rl.RED);
    }
};
