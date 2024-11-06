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
    pub fn render(center: rl.Vector2, i: usize, v: f32) void {
        const amplitude: f32 = Config.amplitude;
        const color1 = Config.color1;
        const color2 = Config.color2;
        const SPACING = ffi(f32, screenWidth) / ffi(f32, processor.curr_buffer.len);
        const x = ffi(f32, i) * SPACING;
        const y = -(v * amplitude);
        // "plot" x and y
        const px = x + center.x;
        const py = y + center.y;
        // zig fmt: off
        rl.DrawRectangleRec(.{ .x = px, .y = py,      .width = 1, .height = 2 }, hsv(color1).into());
        rl.DrawRectangleRec(.{ .x = px, .y = py + 8,  .width = 1, .height = 2 }, hsv(color2).into());
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
    var maxes: [N]f32 = @splat(0);

    pub fn render(center: rl.Vector2, i: usize, v: f32) void {
        const SPACING = ffi(f32, screenWidth) / ffi(f32, processor.curr_buffer.len);
        const x = ffi(f32, i) * SPACING;
        const y = (v * amplitude.*);
        const px = x;
        const c1 = hsv(color1.*).into();
        const c2 = hsv(color2.*).into();
        // TODO: configurable
        maxes[i] = @max(y + base_h.*, maxes[i]);
        maxes[i] *= 0.99;
        rl.DrawRectangleRounded(.{
            .x = px,
            .y = center.y * 2 - maxes[i],
            .width = 2,
            .height = maxes[i],
        }, 1, 10, rl.BLUE);
        rl.DrawRectangleGradientEx(.{
            .x = px,
            .y = center.y * 2 - y - base_h.*,
            .width = 2,
            .height = y + base_h.*,
        }, c1, c2, c2, c1);
    }
};

pub fn onWindowResize(width: i32, _: i32) void {
    screenWidth = width;
}
