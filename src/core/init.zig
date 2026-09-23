//! Init sequence for the GUI / Window
const rl = @import("../raylib.zig");
const Config = @import("config.zig");
const APP_NAME = Config.Window.title;

pub fn startup() void {
    // TODO: Options menu
    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE | rl.FLAG_WINDOW_TRANSPARENT | rl.FLAG_WINDOW_TOPMOST);

    // Setup
    rl.InitWindow(Config.Window.width, Config.Window.height, APP_NAME);
    rl.rl.SetWindowMinSize(640, 480);
    rl.SetTargetFPS(Config.Window.fps_target);

    rl.InitAudioDevice();

    rl.GuiSetAlpha(1.0);
    rl.RayguiDark();
    const ui = rl.rl;
    ui.GuiSetStyle(ui.DEFAULT, ui.BACKGROUND_COLOR, 0x141c29ff);
    ui.GuiSetStyle(ui.DEFAULT, ui.BORDER_COLOR_NORMAL, 0x41516aff);
    ui.GuiSetStyle(ui.DEFAULT, ui.BASE_COLOR_NORMAL, 0x202c3eff);
    ui.GuiSetStyle(ui.DEFAULT, ui.TEXT_COLOR_NORMAL, @bitCast(@as(u32, 0xdce7f5ff)));
    ui.GuiSetStyle(ui.DEFAULT, ui.BORDER_COLOR_FOCUSED, 0x65d9c5ff);
    ui.GuiSetStyle(ui.DEFAULT, ui.BASE_COLOR_FOCUSED, 0x2d4c59ff);
    ui.GuiSetStyle(ui.DEFAULT, ui.TEXT_COLOR_FOCUSED, @bitCast(@as(u32, 0xffffffff)));
    ui.GuiSetStyle(ui.DEFAULT, ui.BORDER_COLOR_PRESSED, 0x65d9c5ff);
    ui.GuiSetStyle(ui.DEFAULT, ui.BASE_COLOR_PRESSED, 0x65d9c5ff);
    ui.GuiSetStyle(ui.DEFAULT, ui.TEXT_COLOR_PRESSED, 0x102830ff);
    rl.SetMasterVolume(Config.Audio.volume);
}
pub fn shutdown() void {
    rl.CloseAudioDevice();
    rl.CloseWindow(); // Close window and OpenGL context
}
