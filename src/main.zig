const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
    @cInclude("rlgl.h");
});
const rl = @import("raylib.zig");
const audio = @import("audio.zig");
const graphics = @import("graphics.zig");

pub const screenWidth = 1200;
pub const screenHeight = 800;
const APP_NAME = "zigscene";

const projections = .{ c.CAMERA_PERSPECTIVE, c.CAMERA_ORTHOGRAPHIC };

pub fn main() !void {
    var t: f32 = 0.0;

    // Setup
    c.InitWindow(screenWidth, screenHeight, APP_NAME);
    defer c.CloseWindow(); // Close window and OpenGL context

    c.InitAudioDevice();
    defer c.CloseAudioDevice();

    var music = c.Music{};
    var filename = std.mem.zeroes([64:0]u8);
    var clen: usize = 0;
    var txtbuffer = std.mem.zeroes([256:0]u8);
    var rot_offset: f32 = 0.0;
    c.SetMasterVolume(0.10);

    var camera3d: c.Camera3D = .{
        .position = .{ .x = 0.0, .y = 0.5, .z = 10.0 }, // Camera position
        .target = .{ .x = 0.0, .y = 0.0, .z = 0.0 }, // Camera looking at point
        .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 }, // Camera up vector (rotation towards target)
        .fovy = 65.0, // Camera field-of-view Y
        .projection = c.CAMERA_PERSPECTIVE, // Camera projection type
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
            @memset(&txtbuffer, 0);
            @memcpy(filename[0..clen], cfilename[0..clen]);
            startMusic(&music, file) catch @panic("oml");
        }
        if (c.IsMusicStreamPlaying(music)) {
            c.UpdateMusicStream(music);
        }
        if (rl.IsKeyPressed(.C)) {
            camera3d.projection = switch (camera3d.projection) {
                c.CAMERA_PERSPECTIVE => c.CAMERA_ORTHOGRAPHIC,
                c.CAMERA_ORTHOGRAPHIC => c.CAMERA_PERSPECTIVE,
                else => unreachable,
            };
        }
        if (rl.IsKeyDown(.LEFT)) {
            rot_offset -= 0.5;
        }
        if (rl.IsKeyDown(.RIGHT)) {
            rot_offset += 0.5;
        }

        c.BeginDrawing();
        defer c.EndDrawing();
        const center = c.GetWorldToScreen(.{ .x = 0, .y = 0 }, camera3d);

        c.ClearBackground(c.BLACK);
        const mtp = c.GetMusicTimePlayed(music);
        const mtl = c.GetMusicTimeLength(music);
        if (c.IsMusicStreamPlaying(music)) {
            const txt = try std.fmt.bufPrint(&txtbuffer, "{s}\n{d:3.2} | {d:3.2}", .{ filename[0..clen], mtl, mtp });
            c.DrawText(txt.ptr, 0, 0, 10, c.WHITE);
        }
        {
            c.BeginMode3D(camera3d);
            defer c.EndMode3D();
            c.rlPushMatrix();
            c.rlTranslatef(0, 0, mtp * 0.4);
            c.DrawGrid(256, 2);
            c.rlPopMatrix();
            const R = 4;
            const SCALE = 1;
            c.rlPushMatrix();
            c.rlRotatef(t * 32, 0.2, 0.2, 1);
            const tsteps = 2 * std.math.pi / @as(f32, @floatFromInt(audio.curr_buffer.len));
            for (audio.curr_buffer, 0..) |v, i| {
                const r = R + (@abs(v) * SCALE);
                const angle_rad = @as(f32, @floatFromInt(i)) * tsteps;
                const x = @cos(angle_rad) * r;
                const y = @sin(angle_rad) * r;
                // _ = x;
                // _ = y;
                c.rlPushMatrix();
                c.rlTranslatef(x, y, 0);
                c.rlRotatef(90 + angle_rad * 180 / std.math.pi, 0, 0, 1);
                c.DrawCubeWires(.{
                    .x = 0,
                    .y = 0,
                }, 0.1, 0.1 + @abs(v) * 0.5, 0.1, c.ORANGE);
                c.rlTranslatef(0.1, 0.1, 0);
                c.DrawCubeWires(.{
                    .x = 0,
                    .y = 0,
                }, 0.05, 0.03, 0.05, c.GREEN);
                c.rlPopMatrix();
            }
            c.rlPopMatrix();
        }
        for (audio.curr_buffer, 0..) |v, i| {
            graphics.draw_line(center, i, v);
            graphics.draw_bars(center, i, v);
            //graphics.draw_bubbles(center, i, v, t);
        }
        for (audio.curr_fft, 0..) |v, i| {
            const SPACING = 5;
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

test "root" {
    std.testing.refAllDecls(@This());
}
