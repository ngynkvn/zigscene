//! Init sequence for the GUI / Window
const rl = @import("../raylib.zig");
const Config = @import("config.zig");
const APP_NAME = Config.Window.title;

pub fn startup() void {
    // TODO: Options menu
    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_WINDOW_TRANSPARENT | rl.FLAG_WINDOW_TOPMOST);

    // Setup
    rl.InitWindow(Config.Window.width, Config.Window.height, APP_NAME);
    rl.SetTargetFPS(Config.Window.fps_target);

    rl.InitAudioDevice();

    rl.GuiSetAlpha(0.8);
    rl.RayguiDark();
    rl.SetMasterVolume(Config.Audio.volume);
}
pub fn shutdown() void {
    rl.CloseAudioDevice();
    rl.CloseWindow(); // Close window and OpenGL context
}
