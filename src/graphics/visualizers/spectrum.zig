const processor = @import("../../audio/processor.zig");
const rl = @import("../../raylib.zig");
const cnv = @import("../../ext/convert.zig");

var screenWidth: c_int = @import("../../core/config.zig").Window.width;
pub fn onWindowResize(width: i32, _: i32) void {
    screenWidth = width;
}

const ffi = cnv.ffi;

pub const FFTSpectrum = struct {
    pub fn render(center: rl.Vector2, i: usize, v: f32) void {
        const SPACING = ffi(f32, screenWidth) / ffi(f32, processor.curr_buffer.len);
        const x = ffi(f32, i) * SPACING;
        const y = v;
        // "plot" x and y
        const px = x;
        const py = -y + center.y * 2 - 5;
        rl.DrawRectangleRec(.{ .x = px, .y = py, .width = 2, .height = 2 }, rl.RAYWHITE);
        rl.DrawRectangleRec(.{ .x = px, .y = py + 12, .width = 2, .height = y + 2 }, rl.RED);
    }
};
