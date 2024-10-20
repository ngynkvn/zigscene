const std = @import("std");
const rl = @import("raylib.zig");
const c = rl.c;
const audio = @import("audio.zig");
const graphics = @import("graphics.zig");
const gui = @import("gui.zig");

pub const screenWidth = 1200;
pub const screenHeight = 800;
const APP_NAME = "zigscene";

const projections = .{ c.CAMERA_PERSPECTIVE, c.CAMERA_ORTHOGRAPHIC };

var filename_buffer = std.mem.zeroes([64:0]u8);
var text_buffer = std.mem.zeroes([256:0]u8);
pub fn main() !void {
    var t: f32 = 0.0;

    // Setup
    c.InitWindow(screenWidth, screenHeight, APP_NAME);
    defer c.CloseWindow(); // Close window and OpenGL context

    c.InitAudioDevice();
    defer c.CloseAudioDevice();

    graphics.initColors();

    c.GuiLoadStyleDark();

    var music = c.Music{};
    var filename: []const u8 = undefined;
    var rot_offset: f32 = 0.0;
    c.SetMasterVolume(0.10);

    var camera3d: c.Camera3D = .{
        .position = .{ .x = 0.0, .y = 0, .z = 10.0 }, // Camera position
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
            filename = try handleFile(&filename_buffer, &music);
            @memset(&text_buffer, 0);
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
            rot_offset -= 1;
        }
        if (rl.IsKeyDown(.RIGHT)) {
            rot_offset += 1;
        }
        const wheelMove = c.GetMouseWheelMoveV();
        if (@abs(wheelMove.x) > @abs(wheelMove.y)) {
            rot_offset += wheelMove.x;
        } else {
            camera3d.position.z += wheelMove.y;
        }
        {
            c.BeginDrawing();
            defer c.EndDrawing();
            const center = c.GetWorldToScreen(.{ .x = 0, .y = 0 }, camera3d);

            c.ClearBackground(c.BLACK);
            const mtp = c.GetMusicTimePlayed(music);
            const mtl = c.GetMusicTimeLength(music);
            // Drawing
            graphics.Bubble.render(camera3d, rot_offset, mtp, t);
            for (audio.curr_buffer, audio.curr_fft, 0..) |v, fv, i| {
                graphics.WaveFormLine.render(.{ .y = center.y - 80 }, i, v);
                graphics.WaveFormBar.render(center, i, v);
                graphics.WaveFormLine.render(.{ .y = center.y * 2 }, i, fv.magnitude() * 0.15);
                graphics.FFT.render(center, i, fv.magnitude());
                //graphics.draw_bubbles(center, i, v, t);
            }
            if (c.IsMusicStreamPlaying(music)) {
                const ftime = c.GetFrameTime();
                const txt = try std.fmt.bufPrint(&text_buffer, "{s}\n{d:3.2} | {d:3.2}\nftime:{d:2.2}", .{ filename, mtl, mtp, ftime });
                c.DrawText(txt.ptr, screenWidth - 100, 0, 10, c.WHITE);
            }
            gui.frame();
            t += 0.01;
        }
    }
}

fn handleFile(buf: []u8, music: *c.Music) ![]const u8 {
    const files = c.LoadDroppedFiles();
    defer c.UnloadDroppedFiles(files);
    const file = files.paths[0];
    const cfilename = c.GetFileName(file);
    const clen = std.mem.len(cfilename);
    @memcpy(buf[0..clen], cfilename[0..clen]);
    try startMusic(music, file);
    return buf[0..clen];
}

fn startMusic(music: *c.Music, path: [*c]const u8) !void {
    music.* = c.LoadMusicStream(path);
    if (music.stream.sampleSize != 32) return error.NoMusic;
    c.AttachAudioStreamProcessor(music.stream, audio.audioStreamCallback);
    std.log.info("samplesize = {}, samplerate = {}\n", .{ music.stream.sampleSize, music.stream.sampleRate });
    c.PlayMusicStream(music.*);
}

test "root" {
    std.testing.refAllDecls(@This());
}
