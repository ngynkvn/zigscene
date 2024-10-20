const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
    @cInclude("rlgl.h");
});
const main = @import("main.zig");
const audio = @import("audio.zig");
const asF32 = @import("extras.zig").asF32;

pub fn drawWaveformLine(center: c.Vector2, i: usize, v: f32) void {
    const SPACING = main.screenWidth / asF32(audio.curr_buffer.len);
    const x = @as(f32, @floatFromInt(i)) * SPACING;
    const y = -(v * 60);
    // "plot" x and y
    const px = x;
    const py = y + center.y - 80;
    c.DrawRectangleRec(.{ .x = px, .y = py, .width = 1, .height = 2 }, c.RAYWHITE);
    c.DrawRectangleRec(.{ .x = px, .y = py + 12, .width = 2, .height = 1 }, c.GREEN);
}

pub fn drawWaveformBar(center: c.Vector2, i: usize, v: f32) void {
    const SPACING = main.screenWidth / asF32(audio.curr_buffer.len);
    const x = @as(f32, @floatFromInt(i)) * SPACING;
    const y = (v * 40);
    const base_h: f32 = 40;
    const tgrad = c.BLUE;
    const bgrad = c.BLUE;
    const px = x;
    c.DrawRectangleGradientEx(
        .{
            .x = px,
            .y = center.y * 2 - y - base_h,
            .width = 3,
            .height = y + base_h,
        },
        tgrad,
        bgrad,
        bgrad,
        tgrad,
    );
}

pub fn drawFft(center: c.Vector2, i: usize, v: f32) void {
    const SPACING = main.screenWidth / asF32(audio.curr_buffer.len);
    const x = @as(f32, @floatFromInt(i)) * SPACING;
    const y = v;
    // "plot" x and y
    const px = x;
    const py = -y + center.y * 2 - 5;
    c.DrawRectangleRec(.{ .x = px, .y = py, .width = 3, .height = 2 }, c.RAYWHITE);
    c.DrawRectangleRec(.{ .x = px, .y = py + 12, .width = 3, .height = y + 2 }, c.RED);
}

pub fn draw3DScene(camera3d: c.Camera3D, rot_offset: f32, mtp: f32, t: f32) void {
    c.BeginMode3D(camera3d);
    defer c.EndMode3D();
    c.rlRotatef(rot_offset, 0, 1, 0);
    if (false) {
        c.rlPushMatrix();
        c.rlTranslatef(0, -5, mtp * 0.4);
        c.DrawGrid(64, 16);
        c.rlPopMatrix();
    }
    const R = 4;
    const SCALE = 1;
    c.rlPushMatrix();
    c.rlRotatef(t * 32, 1, 1, 1);
    c.DrawSphereWires(.{}, 2 + audio.avg_intensity, 10, 10, c.PURPLE);
    c.rlPopMatrix();
    c.rlPushMatrix();
    c.rlRotatef(t * 32, 0.2, 0.2, 1);
    const tsteps = 2 * std.math.pi / @as(f32, @floatFromInt(audio.curr_buffer.len));
    for (audio.curr_buffer, 0..) |v, i| {
        const r = R + (@abs(v) * SCALE);
        const angle_rad = @as(f32, @floatFromInt(i)) * tsteps;
        const x = @cos(angle_rad) * r;
        const y = @sin(angle_rad) * r;
        c.rlPushMatrix();
        c.rlTranslatef(x, y, 0);
        c.rlRotatef(90 + angle_rad * 180 / std.math.pi, 0, 0, 1);
        c.DrawCubeWires(.{}, 0.1, 0.1 + @abs(v) * 0.5, 0.1, c.ORANGE);
        c.rlTranslatef(-0.1, 0.1, 0);
        inline for (0..3) |j| {
            c.DrawCubeWires(.{ .z = 0.05 - 0.05 * @as(f32, @floatFromInt(j)) }, 0.03, 0.03, 0.03, c.GREEN);
        }

        c.rlPopMatrix();
    }
    c.rlPopMatrix();
}

const bubbles = [_][2]f32{
    .{ 240, 60 },
    .{ 240, 40 },
    .{ 240, 20 },
    .{ 240, 10 },
    .{ 220, 10 },
};
pub fn draw_bubbles(center: c.Vector2, i: usize, v: f32, t: f32) void {
    const tsteps = std.math.pi * 2 / @as(f32, @floatFromInt(audio.curr_buffer.len));
    for (bubbles) |b| {
        const r = b[0] + (@abs(v) * b[1]);
        const x = (@cos(@as(f32, @floatFromInt(i)) * tsteps + t) * r) + center.x;
        const y = (@sin(@as(f32, @floatFromInt(i)) * tsteps + t) * r) + center.y;
        c.DrawRectangleRec(.{ .x = x, .y = y, .width = 2, .height = 2 }, c.ORANGE);
    }
}
