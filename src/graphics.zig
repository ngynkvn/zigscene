const std = @import("std");
const c = @import("raylib.zig").c;
const main = @import("main.zig");
const audio = @import("audio.zig");
const asF32 = @import("extras.zig").asF32;
const fromHSV = @import("extras.zig").fromHSV;

pub const WaveFormLine = struct {
    pub var Scalars = [_]Scalar{
        .{ .name = "amplitude", .value = &amplitude, .range = .{ 0, 100 } },
    };
    pub var Colors = [_]Color{
        .{ .name = "color1", .hue = &color1.x },
        .{ .name = "color2", .hue = &color2.x },
    };
    pub var amplitude: f32 = 60;
    var color1 = c.Vector3{ .x = 0e0, .y = 0, .z = 0.96 };
    var color2 = c.Vector3{ .x = 132, .y = 1, .z = 0.9 };
    pub fn render(center: c.Vector2, i: usize, v: f32) void {
        const SPACING = asF32(main.screenWidth) / asF32(audio.curr_buffer.len);
        const x = @as(f32, @floatFromInt(i)) * SPACING;
        const y = -(v * amplitude);
        // "plot" x and y
        const px = x + center.x;
        const py = y + center.y;
        c.DrawRectangleRec(.{ .x = px, .y = py, .width = 1, .height = 2 }, fromHSV(color1));
        c.DrawRectangleRec(.{ .x = px, .y = py + 12, .width = 2, .height = 1 }, fromHSV(color2));
    }
};

pub const WaveFormBar = struct {
    pub var Scalars = [_]Scalar{
        .{ .name = "amplitude", .value = &amplitude, .range = .{ 0, 100 } },
        .{ .name = "base height", .value = &base_h, .range = .{ 0, 100 } },
    };
    pub var Colors = [_]Color{
        .{ .name = "color1", .hue = &color1.x },
        .{ .name = "color2", .hue = &color2.x },
    };
    var color1 = c.Vector3{ .x = 229, .y = 1, .z = 0.94 };
    var color2 = c.Vector3{ .x = 162, .y = 1, .z = 0.89 };
    pub var amplitude: f32 = 40;
    pub var base_h: f32 = 40;

    pub fn render(center: c.Vector2, i: usize, v: f32) void {
        const SPACING = asF32(main.screenWidth) / asF32(audio.curr_buffer.len);
        const x = @as(f32, @floatFromInt(i)) * SPACING;
        const y = (v * amplitude);
        const px = x;
        const c1 = fromHSV(color1);
        const c2 = fromHSV(color2);
        c.DrawRectangleGradientEx(.{
            .x = px,
            .y = center.y * 2 - y - base_h,
            .width = 3,
            .height = y + base_h,
        }, c1, c2, c2, c1);
    }
};

pub const FFT = struct {
    pub fn render(center: c.Vector2, i: usize, v: f32) void {
        const SPACING = asF32(main.screenWidth) / asF32(audio.curr_buffer.len);
        const x = @as(f32, @floatFromInt(i)) * SPACING;
        const y = v;
        // "plot" x and y
        const px = x;
        const py = -y + center.y * 2 - 5;
        c.DrawRectangleRec(.{ .x = px, .y = py, .width = 3, .height = 2 }, c.RAYWHITE);
        c.DrawRectangleRec(.{ .x = px, .y = py + 12, .width = 3, .height = y + 2 }, c.RED);
    }
};

pub const Bubble = struct {
    pub var Scalars = [_]Scalar{
        .{ .name = "ring radius", .value = &r_ring, .range = .{ 0.1, 8 } },
        .{ .name = "sphere radius", .value = &r_sphere, .range = .{ 0.1, 4 } },
        .{ .name = "volume effect", .value = &effect, .range = .{ 0.1, 1 } },
        .{ .name = "color scale", .value = &color_scale, .range = .{ 0.0, 100 } },
        .{ .name = "bubble color fx", .value = &bubble_color_scale, .range = .{ 0.0, 100 } },
    };
    pub var Colors = [_]Color{
        .{ .name = "color1", .hue = &color1.x },
        .{ .name = "color2", .hue = &color2.x },
        .{ .name = "color2", .hue = &color3.x },
    };
    var color1 = c.Vector3{ .x = 195, .y = 0.5, .z = 1 };
    var color2 = c.Vector3{ .x = 117, .y = 1, .z = 1 };
    var color3 = c.Vector3{ .x = 132, .y = 1, .z = 0.9 };
    // Radii
    pub var r_ring: f32 = 4;
    pub var r_sphere: f32 = 3;
    pub var effect: f32 = 0.5;
    pub var color_scale: f32 = 45;
    pub var bubble_color_scale: f32 = 30;
    pub fn render(camera3d: c.Camera3D, rot_offset: f32, mtp: f32, t: f32) void {
        c.BeginMode3D(camera3d);
        defer c.EndMode3D();
        c.rlRotatef(rot_offset, 0, 1, 0);
        if (false) {
            c.rlPushMatrix();
            c.rlTranslatef(0, -5, mtp * 0.4);
            c.DrawGrid(64, 16);
            c.rlPopMatrix();
        }
        {
            c.rlPushMatrix();
            c.rlRotatef(t * 32, 1, 1, 1);
            var col = color1;
            col.x += audio.avg_intensity * bubble_color_scale;
            c.DrawSphereWires(.{}, r_sphere + audio.avg_intensity * effect, 10, 10, fromHSV(col));
            c.rlPopMatrix();
        }
        c.rlPushMatrix();
        c.rlRotatef(t * 32, 0.2, 0.2, 1);
        const tsteps = 2 * std.math.pi / @as(f32, @floatFromInt(audio.curr_buffer.len));
        for (audio.curr_buffer, 0..) |v, i| {
            const r = r_ring +
                (effect * audio.avg_intensity) +
                (@abs(v) * effect);

            const angle_rad = @as(f32, @floatFromInt(i)) * tsteps;
            const x = @cos(angle_rad) * r;
            const y = @sin(angle_rad) * r;

            c.rlPushMatrix();
            c.rlTranslatef(x, y, 0);
            c.rlRotatef(90 + (angle_rad * 180 / std.math.pi), 0, 0, 1);

            var col = color2;
            col.x += audio.avg_intensity * color_scale + @abs(v) * 30;
            c.DrawCubeWires(.{}, 0.1, 0.1 + @abs(v) * effect + audio.avg_intensity * 0.2, 0.1, fromHSV(col));

            c.rlTranslatef(-0.1, 0.1, 0);
            col = color3;
            col.x += audio.avg_intensity * 10 + @abs(v) * 20;
            c.DrawCubeWires(.{}, 0.03, 0.03, 0.03, fromHSV(col));

            c.rlPopMatrix();
        }
        c.rlPopMatrix();
    }
};

// Configurables. These get set up in the UI
pub const Scalar = struct {
    name: []const u8,
    value: *f32,
    range: struct { f32, f32 },
};
pub const Color = struct {
    name: []const u8,
    hue: *f32,
};
