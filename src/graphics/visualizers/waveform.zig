const rl = @import("raylibz");
const hsv = rl.Color.hsv.vec3;

const processor = @import("../../audio/processor.zig");
var screenWidth: c_int = @import("../../core/config.zig").Window.width;

comptime {
    @setFloatMode(.optimized);
}

pub const WaveFormLine = struct {
    const Config = @import("../../core/config.zig").Visualizer.WaveFormLine;
    pub fn render(center: rl.Vector2, i: usize, v: f32) void {
        const amplitude: f32 = Config.amplitude;
        const color1 = Config.color1;
        const color2 = Config.color2;
        const SPACING = @as(f32, @floatFromInt(screenWidth)) / @as(f32, @floatFromInt(processor.curr_buffer.len));
        const x = @as(f32, @floatFromInt(i)) * SPACING;
        const y = -(v * amplitude);
        // "plot" x and y
        const px = x + center.x;
        const py = y + center.y;
        // zig fmt: off
        rl.drawRectangleRec(.{ .x = px, .y = py,      .width = SPACING, .height = 1 }, rl.Color.hsv.vec3(color1));
        rl.drawRectangleRec(.{ .x = px, .y = py + 8,  .width = SPACING, .height = 2 }, rl.Color.hsv.vec3(color2));
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
    var maxes: [N]f32 = @splat(0);

    pub fn render(center: rl.Vector2, i: usize, v: f32) void {
        const SPACING = @as(f32, @floatFromInt(screenWidth)) / @as(f32, @floatFromInt(processor.curr_buffer.len));
        const x = @as(f32, @floatFromInt(i)) * SPACING;
        const y = (v * amplitude.*);
        const px = x;
        const c1 = rl.Color.hsv.vec3(color1.*);
        const c2 = rl.Color.hsv.vec3(color2.*);
        // TODO: configurable
        maxes[i] = @max(y + base_h.*, maxes[i]);
        maxes[i] *= 0.99;
        rl.drawRectangleRec(.{
            .x = px,
            .y = center.y * 2 - maxes[i],
            .width = SPACING,
            .height = maxes[i],
        }, rl.Color.hsv.vec3(trail_color.*));
        rl.drawRectangleGradientEx(.{
            .x = px,
            .y = center.y * 2 - y - base_h.*,
            .width = SPACING,
            .height = y + base_h.*,
        }, c1, c2, c2, c1);
    }
};

pub fn onWindowResize(width: i32, _: i32) void {
    screenWidth = width;
}
