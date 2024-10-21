const std = @import("std");
const c = @import("raylib.zig").c;
const main = @import("main.zig");
const audio = @import("audio.zig");
const asF32 = @import("extras.zig").asF32;

pub fn initColors() void {
    WaveFormLine.init();
    WaveFormBar.init();
    Bubble.init();
}

fn fromHSV(col: c.Vector3) c.Color {
    return c.ColorFromHSV(col.x, col.y, col.z);
}

pub const WaveFormLine = struct {
    pub var Scalars = [_]Scalar{
        .{ .name = "amplitude", .value = &amplitude, .range = .{ 0, 100 } },
    };
    pub var Colors = [_]Color{
        .{ .name = "color1", .hue = &color1.x },
        .{ .name = "color2", .hue = &color2.x },
    };
    pub var amplitude: f32 = 60;
    var color1: c.Vector3 = undefined;
    var color2: c.Vector3 = undefined;
    fn init() void {
        color1 = c.ColorToHSV(c.RAYWHITE);
        color2 = c.ColorToHSV(c.GREEN);
    }
    pub fn render(center: c.Vector2, i: usize, v: f32) void {
        const SPACING = main.screenWidth / asF32(audio.curr_buffer.len);
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
        .{ .name = "base_h", .value = &base_h, .range = .{ 0, 100 } },
    };
    pub var Colors = [_]Color{
        .{ .name = "color1", .hue = &color1.x },
        .{ .name = "color2", .hue = &color2.x },
    };
    var color1: c.Vector3 = undefined;
    var color2: c.Vector3 = undefined;
    fn init() void {
        color1 = c.ColorToHSV(c.BLUE);
        color1.x += 20;
        color2 = c.ColorToHSV(c.GREEN);
        color2.x += 30;
    }
    pub var amplitude: f32 = 40;
    pub var base_h: f32 = 40;
    pub fn render(center: c.Vector2, i: usize, v: f32) void {
        const SPACING = main.screenWidth / asF32(audio.curr_buffer.len);
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
        const SPACING = main.screenWidth / asF32(audio.curr_buffer.len);
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
        .{ .name = "amplitude", .value = &R, .range = .{ 0, 6 } },
        .{ .name = "scale", .value = &scale, .range = .{ 0, 2 } },
    };
    pub var Colors = [_]Color{
        .{ .name = "color1", .hue = &color1.x },
        .{ .name = "color2", .hue = &color2.x },
        .{ .name = "color2", .hue = &color3.x },
    };
    var color1: c.Vector3 = undefined;
    var color2: c.Vector3 = undefined;
    var color3: c.Vector3 = undefined;
    fn init() void {
        color1 = c.ColorToHSV(c.PURPLE);
        color2 = c.ColorToHSV(c.ORANGE);
        color3 = c.ColorToHSV(c.GREEN);
    }
    pub var R: f32 = 4;
    pub var scale: f32 = 1;
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
            col.x += t * 10 + audio.avg_intensity * 45;
            c.DrawSphereWires(.{}, 2 + audio.avg_intensity / 2, 10, 10, fromHSV(col));
            c.rlPopMatrix();
        }
        c.rlPushMatrix();
        c.rlRotatef(t * 32, 0.2, 0.2, 1);
        const tsteps = 2 * std.math.pi / @as(f32, @floatFromInt(audio.curr_buffer.len));
        for (audio.curr_buffer, 0..) |v, i| {
            const r = R + (@abs(v) * scale);
            const angle_rad = @as(f32, @floatFromInt(i)) * tsteps;
            const x = @cos(angle_rad) * r;
            const y = @sin(angle_rad) * r;
            c.rlPushMatrix();
            c.rlTranslatef(x, y, 0);
            c.rlRotatef(90 + angle_rad * 180 / std.math.pi, 0, 0, 1);
            var col = color2;
            col.x += t * 5 + audio.avg_intensity * 10 + r * 40;
            c.DrawCubeWires(.{}, 0.1, 0.1 + @abs(v) * 0.5, 0.1, fromHSV(col));
            c.rlTranslatef(-0.1, 0.1, 0);
            inline for (0..3) |j| {
                c.DrawCubeWires(.{ .z = 0.05 - 0.05 * @as(f32, @floatFromInt(j)) }, 0.03, 0.03, 0.03, fromHSV(color3));
            }

            c.rlPopMatrix();
        }
        c.rlPopMatrix();
    }
};

// const bubbles = [_][2]f32{
//     .{ 240, 60 },
//     .{ 240, 40 },
//     .{ 240, 20 },
//     .{ 240, 10 },
//     .{ 220, 10 },
// };
// pub fn draw_bubbles(center: c.Vector2, i: usize, v: f32, t: f32) void {
//     const tsteps = std.math.pi * 2 / @as(f32, @floatFromInt(audio.curr_buffer.len));
//     for (bubbles) |b| {
//         const r = b[0] + (@abs(v) * b[1]);
//         const x = (@cos(@as(f32, @floatFromInt(i)) * tsteps + t) * r) + center.x;
//         const y = (@sin(@as(f32, @floatFromInt(i)) * tsteps + t) * r) + center.y;
//         c.DrawRectangleRec(.{ .x = x, .y = y, .width = 2, .height = 2 }, c.ORANGE);
//     }
// }

pub const Scalar = struct {
    name: []const u8,
    value: *f32,
    range: struct { f32, f32 },
};
pub const Color = struct {
    name: []const u8,
    hue: *f32,
};
