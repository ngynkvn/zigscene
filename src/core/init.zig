//! Init sequence for the GUI / Window
const rl = @import("../raylib.zig");
const Config = @import("config.zig");
const APP_NAME = Config.Window.title;

pub fn startup() void {
    const retina = if (@import("builtin").os.tag == .macos) rl.rl.FLAG_WINDOW_HIGHDPI else 0;
    const topmost: c_int = if (Config.Window.always_on_top and @import("builtin").os.tag != .emscripten) rl.FLAG_WINDOW_TOPMOST else 0;
    rl.SetConfigFlags(@intCast(rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_WINDOW_TRANSPARENT | topmost | retina));

    // Setup
    rl.InitWindow(Config.Window.width, Config.Window.height, APP_NAME);
    rl.rl.SetWindowMinSize(640, 480);
    // Source-over alpha: translucent UI must never punch holes in an opaque
    // window. The default blend factors incorrectly square source alpha.
    rl.rl.rlSetBlendFactorsSeparate(rl.rl.RL_SRC_ALPHA, rl.rl.RL_ONE_MINUS_SRC_ALPHA, rl.rl.RL_ONE, rl.rl.RL_ONE_MINUS_SRC_ALPHA, rl.rl.RL_FUNC_ADD, rl.rl.RL_FUNC_ADD);
    rl.rl.rlSetBlendMode(rl.rl.RL_BLEND_CUSTOM_SEPARATE);
    rl.SetTargetFPS(@intFromFloat(Config.Window.fps_limit));

    rl.InitAudioDevice();

    @import("../gui/theme.zig").init();
    rl.SetMasterVolume(Config.Audio.volume);
}
pub fn shutdown() void {
    @import("../gui/theme.zig").deinit();
    rl.CloseAudioDevice();
    rl.CloseWindow(); // Close window and OpenGL context
}
