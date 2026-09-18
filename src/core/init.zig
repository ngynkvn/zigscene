//! Init sequence for the GUI / Window
const rl = @import("../raylib.zig");
const Config = @import("config.zig");
const APP_NAME = Config.Window.title;
const capture = @import("../audio/capture.zig");
const playback = @import("../audio/playback.zig");

pub fn startup() void {
    // TODO: Options menu
    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_WINDOW_TRANSPARENT | rl.FLAG_WINDOW_TOPMOST);

    // Setup
    rl.InitWindow(Config.Window.width, Config.Window.height, APP_NAME);

    rl.InitAudioDevice();

    rl.GuiSetAlpha(0.8);
    rl.RayguiDark();
    rl.SetMasterVolume(Config.Audio.volume);
}
pub fn shutdown() void {
    capture.stop();
    playback.shutdown();
    rl.CloseAudioDevice();
    rl.CloseWindow(); // Close window and OpenGL context
}
