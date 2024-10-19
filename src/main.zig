const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
});
const screenWidth = 800;
const screenHeight = 600;

pub fn main() !void {
    var t: f32 = 0.0;

    c.InitWindow(screenWidth, screenHeight, "neo");
    defer c.CloseWindow(); // Close window and OpenGL context

    c.InitAudioDevice();
    defer c.CloseAudioDevice();

    var music = c.Music{};
    var filename = std.mem.zeroes([64:0]u8);
    var clen: usize = 0;
    var info = std.mem.zeroes([256:0]u8);
    c.SetMasterVolume(0.10);

    const camera3d: c.Camera3D = .{
        .position = .{ .x = 0.0, .y = 3.0, .z = 10.0 }, // Camera position
        .target = .{ .x = 0.0, .y = 0.0, .z = 0.0 }, // Camera looking at point
        .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 }, // Camera up vector (rotation towards target)
        .fovy = 45.0, // Camera field-of-view Y
        .projection = c.CAMERA_PERSPECTIVE, // Camera projection type
    };
    const camera2d: c.Camera2D = .{
        .zoom = 1,
        .offset = .{ .x = screenWidth / 2, .y = screenHeight / 2 },
    };

    c.SetTargetFPS(60); // Set our game to run at 60 frames-per-second

    // Main game loop
    // Detects window close button or ESC key
    while (!c.WindowShouldClose()) {
        if (c.IsFileDropped()) {
            const files = c.LoadDroppedFiles();
            defer c.UnloadDroppedFiles(files);
            const file = files.paths[0];
            const cfilename = c.GetFileName(file);
            clen = std.mem.len(cfilename);
            @memcpy(filename[0..clen], cfilename[0..clen]);
            startMusic(&music, file) catch @panic("oml");
        }
        if (c.IsMusicStreamPlaying(music)) {
            c.UpdateMusicStream(music);
        }

        c.BeginMode2D(camera2d);
        defer c.EndMode2D();

        c.BeginDrawing();
        defer c.EndDrawing();
        c.ClearBackground(c.BLACK);
        if (c.IsMusicStreamPlaying(music)) {
            const mtp = c.GetMusicTimePlayed(music);
            const mtl = c.GetMusicTimeLength(music);
            const txt = try std.fmt.bufPrint(&info, "{s}\n{d:3.2} | {d:3.2}", .{ filename[0..clen], mtl, mtp });
            c.DrawText(txt.ptr, 0, 0, 10, c.WHITE);
        }
        const center = c.GetWorldToScreen(.{ .x = 0, .y = 0 }, camera3d);
        for (curr_buffer[0..curr_len], 0..) |v, i| {
            draw_line(center, i, v);
            draw_bars(center, i, v);
            draw_bubbles(center, i, v, t);
        }
        for (curr_fft[0..curr_len], 0..) |v, i| {
            const SPACING = 6;
            const x = @as(f32, @floatFromInt(i)) * SPACING;
            const y = v.magnitude();
            // "plot" x and y
            const px = x;
            const py = -y + center.y * 2 - 5;
            c.DrawRectangleRec(.{ .x = px, .y = py, .width = 3, .height = 2 }, c.RAYWHITE);
            c.DrawRectangleRec(.{ .x = px, .y = py + 12, .width = 3, .height = y + 2 }, c.RED);
        }
        t += 0.01;
    }
}

fn startMusic(music: *c.Music, path: [*c]const u8) !void {
    music.* = c.LoadMusicStream(path);
    if (music.stream.sampleSize != 32) return error.NoMusic;
    c.AttachAudioStreamProcessor(music.stream, audioStreamCallback);
    c.PlayMusicStream(music.*);
}

var curr_buffer = std.mem.zeroes([256:0]f32);
var curr_len: usize = 256;
var intensity: f32 = 0;
const Cf32 = std.math.Complex(f32);
var curr_fft = std.mem.zeroes([256]Cf32);
// understand what *this* is?
// a buffer of the stream + the lengtth of the buffer
fn audioStreamCallback(ptr: ?*anyopaque, n: c_uint) callconv(.C) void {
    if (ptr == null) return;
    const buffer: []f32 = @as([*]f32, @ptrCast(@alignCast(ptr)))[0..n];
    var l: f32 = 0;
    var r: f32 = 0;
    curr_len = n / 2;
    for (0..curr_len) |fi| {
        l = buffer[fi * 2 + 0];
        r = buffer[fi * 2 + 1];
        // Damping
        curr_buffer[fi] += (l + r) / 4;
        curr_buffer[fi] *= 0.97;
        // No Damping
        curr_fft[fi] = Cf32.init(l + r, 0);
        intensity = (l + r);
    }
    intensity /= @floatFromInt(curr_len);
    fft(curr_fft[0..curr_len]);
}

fn fft(values: []Cf32) void {
    const N = values.len;
    if (N <= 1) return;
    var parts = std.mem.zeroes([2][128]Cf32);
    var pi: [2]usize = .{ 0, 0 };
    for (values, 0..) |v, i| {
        parts[i % 2][pi[i % 2]] = v;
        pi[i % 2] += 1;
    }
    const evens = parts[0][0..pi[0]];
    const odds = parts[1][0..pi[1]];
    fft(evens);
    fft(odds);
    for (0..N / 2) |i| {
        const index = Cf32.init(
            @cos(-2 * std.math.pi * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(N))),
            @sin(-2 * std.math.pi * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(N))),
        ).mul(odds[i]);
        values[i] = evens[i].add(index);
        values[i + N / 2] = evens[i].sub(index);
    }
}

fn draw_line(center: c.Vector2, i: usize, v: f32) void {
    const SPACING = 4;
    const x = @as(f32, @floatFromInt(i)) * SPACING;
    const y = (v * 60);
    // "plot" x and y
    const px = x;
    const py = -y + center.y - 60;
    c.DrawRectangleRec(.{ .x = px, .y = py, .width = 1, .height = 2 }, c.RAYWHITE);
    c.DrawRectangleRec(.{ .x = px, .y = py + 12, .width = 2, .height = 1 }, c.GREEN);
}

fn draw_bars(center: c.Vector2, i: usize, v: f32) void {
    const SPACING = 4;
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

const bubbles = [_][2]f32{
    .{ 240, 60 },
    .{ 240, 40 },
    .{ 240, 20 },
    .{ 240, 10 },
    .{ 220, 10 },
};
fn draw_bubbles(center: c.Vector2, i: usize, v: f32, t: f32) void {
    const tsteps = std.math.pi * 2 / @as(f32, @floatFromInt(curr_len));
    for (bubbles) |b| {
        const r = b[0] + (@abs(v) * b[1]);
        const x = (@cos(@as(f32, @floatFromInt(i)) * tsteps + t) * r) + center.x;
        const y = (@sin(@as(f32, @floatFromInt(i)) * tsteps + t) * r) + center.y;
        c.DrawRectangleRec(.{ .x = x, .y = y, .width = 2, .height = 2 }, c.ORANGE);
    }
}
