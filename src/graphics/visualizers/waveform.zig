const std = @import("std");
const main = @import("zigscene");
const audio = main.audio;
const rl = main.rl;
const controls = @import("../../gui/controls.zig");
const cnv = @import("../../ext/convert.zig");

const hsv = @import("../../ext/color.zig").Color.hsv.vec3;
const Vector3 = @import("../../ext/vector.zig").Vector3;
const ffi = cnv.ffi;
const iff = cnv.iff;

pub const WaveFormLine = struct {
    pub var Scalars = [_]controls.Scalar{
        .{ "amplitude", &amplitude, .{ 0, 100 } },
    };
    pub var Colors = [_]controls.Color{
        .{ "color1", &color1.x },
        .{ "color2", &color2.x },
    };
    pub var amplitude: f32 = 60;
    // zig fmt: off
    var color1 = Vector3{ .x = 0,   .y = 0, .z = 0.96 };
    var color2 = Vector3{ .x = 100, .y = 1, .z = 0.90 };
    pub fn render(center: rl.Vector2, i: usize, v: f32) void {
        const SPACING = ffi(f32, main.screenWidth) / ffi(f32, audio.curr_buffer.len);
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
    pub var Scalars = [_]controls.Scalar{
        .{ "amplitude", &amplitude, .{ 0, 100 } },
        .{ "base height", &base_h, .{ 0, 100 } },
    };
    pub var Colors = [_]controls.Color{
        .{ "color1", &color1.x },
        .{ "color2", &color2.x },
    };
    var color1 = Vector3{ .x = 250, .y = 1, .z = 0.94 };
    var color2 = Vector3{ .x = 270, .y = 1, .z = 0.9 };
    pub var amplitude: f32 = 50;
    pub var base_h: f32 = 20;

    pub fn render(center: rl.Vector2, i: usize, v: f32) void {
        const SPACING = ffi(f32, main.screenWidth) / ffi(f32, audio.curr_buffer.len);
        const x = ffi(f32, i) * SPACING;
        const y = (v * amplitude);
        const px = x;
        const c1 = hsv(color1).into();
        const c2 = hsv(color2).into();
        rl.DrawRectangleGradientEx(.{
            .x = px,
            .y = center.y * 2 - y - base_h,
            .width = 2,
            .height = y + base_h,
        }, c1, c2, c2, c1);
    }
};
