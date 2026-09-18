//! Init sequence for the GUI / Window
const std = @import("std");

const rl = @import("../raylib.zig");
const Config = @import("config.zig");
pub var screenWidth: c_int = Config.Window.width;
pub var screenHeight: c_int = Config.Window.height;
const APP_NAME = Config.Window.title;
const event = @import("event.zig");
const capture = @import("../audio/capture.zig");
const playback = @import("../audio/playback.zig");

pub fn startup(process_args: std.process.Args) !void {
    // TODO: Options menu
    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_WINDOW_TRANSPARENT | rl.FLAG_WINDOW_TOPMOST);

    // Setup
    rl.InitWindow(screenWidth, screenHeight, APP_NAME);

    rl.InitAudioDevice();

    rl.GuiSetAlpha(0.8);
    rl.RayguiDark();
    var buffer: [256]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var args = try std.process.Args.Iterator.initAllocator(process_args, fba.allocator());
    defer args.deinit();
    _ = args.skip();
    var capture_mode: ?capture.Mode = null;
    var capture_device: i32 = -1;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--system-audio")) {
            capture_mode = .system;
        } else if (std.mem.eql(u8, arg, "--input-audio")) {
            capture_mode = .input;
        } else if (std.mem.eql(u8, arg, "--list-audio-devices")) {
            capture.listDevices();
        } else if (std.mem.startsWith(u8, arg, "--audio-device=")) {
            capture_device = std.fmt.parseInt(i32, arg["--audio-device=".len..], 10) catch -1;
        } else {
            event.onFilenameInput(arg);
        }
    }
    if (capture_mode) |mode| {
        if (rl.IsMusicValid(playback.music)) rl.PauseMusicStream(playback.music);
        capture.start(mode, capture_device) catch {
            if (rl.IsMusicValid(playback.music)) rl.ResumeMusicStream(playback.music);
        };
    }

    rl.SetMasterVolume(Config.Audio.volume);
}
pub fn shutdown() void {
    capture.stop();
    rl.CloseAudioDevice();
    rl.CloseWindow(); // Close window and OpenGL context
}
