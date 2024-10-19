const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
    @cInclude("rlgl.h");
});
const audio = @import("audio.zig");
const graphics = @import("graphics.zig");
const APP_NAME = "zigscene";
const screenWidth = 800;
const screenHeight = 600;

pub fn main() !void {
    var t: f32 = 0.0;

    c.InitWindow(screenWidth, screenHeight, APP_NAME);
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
        for (audio.curr_buffer[0..audio.curr_len], 0..) |v, i| {
            graphics.draw_line(center, i, v);
            graphics.draw_bars(center, i, v);
            graphics.draw_bubbles(center, i, v, t);
        }
        for (audio.curr_fft[0..audio.curr_len], 0..) |v, i| {
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
    c.AttachAudioStreamProcessor(music.stream, audio.audioStreamCallback);
    c.PlayMusicStream(music.*);
}
