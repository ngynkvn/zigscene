const std = @import("std");
const input = @import("input.zig");
const music = @import("../audio/playback.zig");

const rl = @import("../raylib.zig");
const Config = @import("config.zig");
pub var screenWidth: c_int = Config.Window.width;
pub var screenHeight: c_int = Config.Window.height;
const APP_NAME = Config.Window.title;

const event = @import("event.zig");
pub const App = struct {
    //! Init sequence for the GUI / Window
    pub fn init() !App {
        // TODO: Options menu
        rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_WINDOW_TRANSPARENT | rl.FLAG_WINDOW_TOPMOST);

        // Setup
        rl.InitWindow(screenWidth, screenHeight, APP_NAME);

        rl.InitAudioDevice();

        rl.GuiSetAlpha(0.8);
        rl.RayguiDark();
        if (try processArgs()) |path| {
            event.onFilenameInput(path);
        }

        rl.SetMasterVolume(Config.Audio.volume);
        return .{};
    }
    pub fn deinit(self: App) void {
        _ = self;
        rl.CloseAudioDevice();
        rl.CloseWindow(); // Close window and OpenGL context
    }

    fn processArgs() !?[]const u8 {
        var buffer: [256]u8 = @splat(0);
        var fba = std.heap.FixedBufferAllocator.init(&buffer);
        const allocator = fba.allocator();
        var args = try std.process.argsWithAllocator(allocator);
        return if (!args.skip()) null else args.next();
    }
    pub fn processInput(self: *App) void {
        _ = self;
        input.processInput();
    }
    pub fn processMusic(self: *App) void {
        _ = self;
        if (music.IsMusicStreamPlaying()) music.UpdateMusicStream();
    }
};
