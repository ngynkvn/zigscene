//! Init sequence for the GUI / Window
const rl = @import("../raylib.zig");
const Config = @import("config.zig");
const APP_NAME = Config.Window.title;

pub fn startup() void {
    const retina = if (@import("builtin").os.tag == .macos) rl.rl.FLAG_WINDOW_HIGHDPI else 0;
    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_WINDOW_TRANSPARENT | rl.FLAG_WINDOW_TOPMOST | retina);

    // Setup
    rl.InitWindow(Config.Window.width, Config.Window.height, APP_NAME);
    rl.rl.SetWindowMinSize(640, 480);
    rl.SetTargetFPS(Config.Window.fps_target);

    rl.InitAudioDevice();

    @import("../gui/theme.zig").init();
    rl.SetMasterVolume(Config.Audio.volume);
}
pub fn shutdown() void {
    @import("../gui/theme.zig").deinit();
    rl.CloseAudioDevice();
    rl.CloseWindow(); // Close window and OpenGL context
}
