const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
});
const music_file = "./sounds/sample.wav";
const screenWidth = 900;
const screenHeight = 500;

pub fn main() !void {
    var t: f32 = 0.0;

    c.InitWindow(screenWidth, screenHeight, "neo");
    defer c.CloseWindow(); // Close window and OpenGL context

    c.InitAudioDevice();
    defer c.CloseAudioDevice();

    const music = startMusic(music_file);
    c.SetMasterVolume(0.10);

    const camera = c.Camera2D{
        .zoom = 1,
        .offset = .{ .x = 0, .y = screenHeight / 2 },
    };

    c.SetTargetFPS(60); // Set our game to run at 60 frames-per-second

    // Main game loop
    while (!c.WindowShouldClose()) { // Detect window close button or ESC key
        c.UpdateMusicStream(music);

        c.BeginMode2D(camera);
        {
            defer c.EndMode2D();
            // Draw
            c.BeginDrawing();
            {
                defer c.EndDrawing();
                const center = c.GetWorldToScreen2D(.{ .x = 0, .y = 0 }, camera);
                c.ClearBackground(c.BLACK);
                // Direct map of buffer
                for (curr_buffer[0..curr_len], 0..) |v, i| {
                    const x = @as(f32, @floatFromInt(i)) * 4;
                    const y = (v * 80);
                    // "plot" x and y
                    const px = x + center.x;
                    const py = y + center.y;
                    c.DrawRectangleGradientEx(
                        .{ .x = @mod(px + t, screenWidth + 40), .y = y + center.y + 80 + @abs(v) * 20, .width = 1, .height = screenHeight / 2 },
                        c.BLUE,
                        c.BLACK,
                        c.BLACK,
                        c.BLUE,
                    );
                    c.DrawRectangleRec(.{ .x = px, .y = py, .width = 1, .height = 2 }, c.RAYWHITE);
                    c.DrawRectangleRec(.{ .x = px, .y = py + 12, .width = 2, .height = 1 }, c.GREEN);
                }
            }
        }
        t += 3.14;
    }
}

fn startMusic(path: [*c]const u8) c.Music {
    const music = c.LoadMusicStream(path);
    {
        std.debug.assert(music.stream.sampleSize == 32);
    }
    c.AttachAudioStreamProcessor(music.stream, audioStreamCallback);
    c.PlayMusicStream(music);
    return music;
}

var curr_buffer = std.mem.zeroes([256:0]f32);
var curr_len: usize = 0;
var curr_fft = std.mem.zeroes([256:0]f32);
fn audioStreamCallback(ptr: ?*anyopaque, n: c_uint) callconv(.C) void {
    if (ptr == null) return;
    const buffer: []f32 = @as([*]f32, @ptrCast(@alignCast(ptr)))[0..n];
    var l: f32 = 0;
    var r: f32 = 0;
    curr_len = n / 2;
    for (0..n / 2 - 1) |fi| {
        l = buffer[fi * 2 + 0];
        r = buffer[fi * 2 + 1];
        curr_buffer[fi] += (l + r) / 4;
        curr_buffer[fi] *= 0.97;
    }
}
