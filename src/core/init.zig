//! Init sequence for the GUI / Window
const rl = @import("../raylib.zig");
const Config = @import("config.zig");
const APP_NAME = Config.Window.title;

pub fn startup(desktop_pet: bool) void {
    const pet = @import("desktop_pet.zig");
    pet.init(desktop_pet);
    const retina = if (@import("builtin").os.tag == .macos) rl.rl.FLAG_WINDOW_HIGHDPI else 0;
    const topmost: c_int = if ((pet.enabled or Config.Window.always_on_top) and @import("builtin").os.tag != .emscripten) rl.FLAG_WINDOW_TOPMOST else 0;
    const style: c_int = if (pet.enabled) rl.rl.FLAG_WINDOW_UNDECORATED else rl.FLAG_WINDOW_RESIZABLE;
    rl.SetConfigFlags(@intCast(style | rl.FLAG_WINDOW_TRANSPARENT | topmost | retina));

    // Setup
    rl.InitWindow(if (pet.enabled) pet.size else Config.Window.width, if (pet.enabled) pet.size else Config.Window.height, APP_NAME);
    rl.rl.SetWindowMinSize(if (pet.enabled) pet.size else 640, if (pet.enabled) pet.size else 480);
    pet.place();
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
