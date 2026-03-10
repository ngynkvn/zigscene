const std = @import("std");
const rl = @import("raylibz");
const hsv = rl.Color.hsv.vec3;
const controls = @import("../../core/controls.zig");
const Vector3 = rl.Vector3;

const processor = @import("../../audio/processor.zig");
var screenWidth: c_int = @import("../../core/config.zig").Window.width;

comptime {
    @setFloatMode(.optimized);
}

pub const WaveFormLine = struct {
    pub var amplitude: f32 = 60;
    pub var color1: Vector3 = .{ .x = 0, .y = 0, .z = 0.96 };
    pub var color2: Vector3 = .{ .x = 100, .y = 1, .z = 0.90 };

    pub const Settings = std.StaticStringMap(controls.Setting).initComptime(.{
        .{ "amplitude", controls.Setting{ .scalar = .{ .value = &amplitude, .range = .{ 0, 100 } } } },
        .{ "color1", controls.Setting{ .color = .{ .value = &color1.x } } },
        .{ "color2", controls.Setting{ .color = .{ .value = &color2.x } } },
    });

    pub fn render(center: rl.Vector2, i: usize, v: f32) void {
        const SPACING = @as(f32, @floatFromInt(screenWidth)) / @as(f32, @floatFromInt(processor.curr_buffer.len));
        const x = @as(f32, @floatFromInt(i)) * SPACING;
        const y = -(v * amplitude);
        // "plot" x and y
        const px = x + center.x;
        const py = y + center.y;
        rl.drawRectangleRec(
            .{ .x = px, .y = py, .width = SPACING, .height = 1 },
            rl.Color.hsv.from(color1),
        );
        rl.drawRectangleRec(
            .{ .x = px, .y = py + 8, .width = SPACING, .height = 2 },
            rl.Color.hsv.from(color2),
        );
    }
};

pub const WaveFormBar = struct {
    const Config = @import("../../core/config.zig");
    const N = Config.Audio.buffer_size;

    pub var amplitude: f32 = 50;
    pub var base_h: f32 = 20;
    pub var color1 = Vector3{ .x = 250, .y = 1, .z = 0.94 };
    pub var color2 = Vector3{ .x = 270, .y = 1, .z = 0.9 };
    pub var trail_color = Vector3{ .x = 210, .y = 1, .z = 0.473 };
    pub const Settings = std.StaticStringMap(controls.Setting).initComptime(.{
        .{ "amplitude", controls.Setting{ .scalar = .{ .value = &amplitude, .range = .{ 0, 100 } } } },
        .{ "base height", controls.Setting{ .scalar = .{ .value = &base_h, .range = .{ 0, 100 } } } },
        .{ "color1", controls.Setting{ .color = .{ .value = &color1.x } } },
        .{ "color2", controls.Setting{ .color = .{ .value = &color2.x } } },
        .{ "trail color", controls.Setting{ .color = .{ .value = &trail_color.x } } },
    });
    var maxes: [N]f32 = @splat(0);

    pub fn render(center: rl.Vector2, i: usize, v: f32) void {
        const SPACING = @as(f32, @floatFromInt(screenWidth)) / @as(f32, @floatFromInt(processor.curr_buffer.len));
        const x = @as(f32, @floatFromInt(i)) * SPACING;
        const y = (v * amplitude);
        const px = x;
        const c1 = rl.Color.hsv.from(color1);
        const c2 = rl.Color.hsv.from(color2);
        // TODO: configurable
        maxes[i] = @max(y + base_h, maxes[i]);
        maxes[i] *= 0.99;
        rl.drawRectangleRec(.{
            .x = px,
            .y = center.y * 2 - maxes[i],
            .width = SPACING,
            .height = maxes[i],
        }, rl.Color.hsv.from(trail_color));
        rl.drawRectangleGradientEx(.{
            .x = px,
            .y = center.y * 2 - y - base_h,
            .width = SPACING,
            .height = y + base_h,
        }, c1, c2, c2, c1);
    }
};

pub fn onWindowResize(width: i32, _: i32) void {
    screenWidth = width;
}
