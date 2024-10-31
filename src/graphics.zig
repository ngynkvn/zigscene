const std = @import("std");

const rl = @import("raylib.zig");
const main = @import("main.zig");
const audio = @import("audio.zig");
const controls = @import("gui/controls.zig");
const tracy = @import("tracy");
const cnv = @import("ext/convert.zig");
const ffi = cnv.ffi;
const iff = cnv.iff;
const hsv = @import("ext/color.zig").Color.hsv.vec3;
const Color = @import("ext/color.zig").Color;
const Vector3 = @import("ext/vector.zig").Vector3;

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

pub const FFT = struct {
    pub fn render(center: rl.Vector2, i: usize, v: f32) void {
        const SPACING = ffi(f32, main.screenWidth) / ffi(f32, audio.curr_buffer.len);
        const x = ffi(f32, i) * SPACING;
        const y = v;
        // "plot" x and y
        const px = x;
        const py = -y + center.y * 2 - 5;
        rl.DrawRectangleRec(.{ .x = px, .y = py, .width = 2, .height = 2 }, rl.RAYWHITE);
        rl.DrawRectangleRec(.{ .x = px, .y = py + 12, .width = 2, .height = y + 2 }, rl.RED);
    }
};

pub const Bubble = struct {
    pub var Scalars = [_]controls.Scalar{
        // zig fmt: off
        .{ "ring radius",     &r_ring,             .{ 0.1, 8 } },
        .{ "sphere radius",   &r_sphere,           .{ 0.1, 4 } },
        .{ "volume effect",   &effect,             .{ 0.1, 1 } },
        .{ "color scale",     &color_scale,        .{ 0.0, 100 } },
        .{ "bubble color fx", &bubble_color_scale, .{ 0.0, 100 } },
        .{ "ring height",     &height_ring,        .{ 0.0, 1 } },
        // zig fmt: on
    };
    pub var Colors = [_]controls.Color{
        .{ "color1", &color1.x },
        .{ "color2", &color2.x },
    };
    var color1 = Vector3{ .x = 195, .y = 0.5, .z = 1 };
    var color2 = Vector3{ .x = 117, .y = 1, .z = 1 };
    // Radii
    pub var r_ring: f32 = 3.25;
    pub var r_sphere: f32 = 3;
    pub var height_ring: f32 = 0.1;
    pub var effect: f32 = 0.75;
    pub var color_scale: f32 = 45;
    pub var bubble_color_scale: f32 = 30;
    pub fn render(camera3d: rl.Camera3D, rot_offset: f32, t: f32) void {
        rl.BeginMode3D(camera3d);
        defer rl.EndMode3D();
        rl.rlRotatef(rot_offset, 0, 1, 0);
        {
            rl.rlPushMatrix();
            rl.rlRotatef(t * 32, 1, 1, 1);
            var col = color1;
            col.x += audio.rms_energy * bubble_color_scale;
            rl.DrawSphereWires(.{}, r_sphere + audio.rms_energy * effect, 10, 10, hsv(col).into());
            rl.rlPopMatrix();
        }
        rl.rlPushMatrix();
        rl.rlRotatef(t * 32, 0.2, 0.2, 1);
        const tsteps = 2 * std.math.pi / @as(f32, @floatFromInt(audio.curr_buffer.len));
        for (audio.curr_buffer, 0..) |v, i| {
            const r = r_ring +
                (effect * audio.rms_energy) +
                (@abs(v) * effect);

            const angle_rad = ffi(f32, i) * tsteps;
            const x = @cos(angle_rad) * r;
            const y = @sin(angle_rad) * r;

            rl.rlPushMatrix();
            rl.rlTranslatef(x, y, 0);
            rl.rlRotatef(90 + (angle_rad * 180 / std.math.pi), 0, 0, 1);

            var col = color2;
            col.x += audio.rms_energy * color_scale + @abs(v) * 30;
            rl.DrawCubeWires(.{}, 0.1, height_ring + @abs(v) * effect + audio.rms_energy * 0.2, 0.1, hsv(col).into());
            rl.rlPopMatrix();
        }
        rl.rlPopMatrix();
    }
};
