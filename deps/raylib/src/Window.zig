const rlc = @import("c.zig");

pub fn init(width: i32, height: i32, title: []const u8) void {
    return rlc.InitWindow(width, height, title.ptr);
}

pub fn close() void {
    return rlc.CloseWindow();
}

pub fn shouldClose() bool {
    return rlc.WindowShouldClose();
}

pub fn isReady() bool {
    return rlc.IsWindowReady();
}

pub fn isFullscreen() bool {
    return rlc.IsWindowFullscreen();
}

pub fn isHidden() bool {
    return rlc.IsWindowHidden();
}

pub fn isMinimized() bool {
    return rlc.IsWindowMinimized();
}

pub fn isMaximized() bool {
    return rlc.IsWindowMaximized();
}

pub fn isFocused() bool {
    return rlc.IsWindowFocused();
}

pub fn isResized() bool {
    return rlc.IsWindowResized();
}

pub fn isState(flag: rlc.ConfigFlags) bool {
    return rlc.IsWindowState(@bitCast(flag));
}

pub fn setState(flags: rlc.ConfigFlags) void {
    return rlc.SetWindowState(@bitCast(flags));
}

pub fn clearState(flags: rlc.ConfigFlags) void {
    return rlc.ClearWindowState(@bitCast(flags));
}

pub fn toggleFullscreen() void {
    return rlc.ToggleFullscreen();
}

pub fn toggleBorderless() void {
    return rlc.ToggleBorderlessWindowed();
}

pub fn maximize() void {
    return rlc.MaximizeWindow();
}

pub fn minimize() void {
    return rlc.MinimizeWindow();
}

pub fn restore() void {
    return rlc.RestoreWindow();
}

pub fn setIcon(image: rlc.Image) void {
    return rlc.SetWindowIcon(image);
}

pub fn setIcons(images: [*c]rlc.Image, count: c_int) void {
    return rlc.SetWindowIcons(images, count);
}

pub fn setTitle(title: [*c]const u8) void {
    return rlc.SetWindowTitle(title);
}

pub fn setPosition(x: c_int, y: c_int) void {
    return rlc.SetWindowPosition(x, y);
}

pub fn setMonitor(monitor: c_int) void {
    return rlc.SetWindowMonitor(monitor);
}

pub fn setMinSize(width: c_int, height: c_int) void {
    return rlc.SetWindowMinSize(width, height);
}

pub fn setMaxSize(width: c_int, height: c_int) void {
    return rlc.SetWindowMaxSize(width, height);
}

pub fn setSize(width: c_int, height: c_int) void {
    return rlc.SetWindowSize(width, height);
}

pub fn setOpacity(opacity: f32) void {
    return rlc.SetWindowOpacity(opacity);
}

pub fn setFocused() void {
    return rlc.SetWindowFocused();
}

pub fn getHandle() ?*anyopaque {
    return rlc.GetWindowHandle();
}

pub fn getScreenWidth() i32 {
    return rlc.GetScreenWidth();
}

pub fn getScreenHeight() i32 {
    return rlc.GetScreenHeight();
}

pub fn getRenderWidth() i32 {
    return rlc.GetRenderWidth();
}

pub fn getRenderHeight() i32 {
    return rlc.GetRenderHeight();
}

pub fn getMonitorCount() i32 {
    return rlc.GetMonitorCount();
}

pub fn getCurrentMonitor() i32 {
    return rlc.GetCurrentMonitor();
}

pub fn getMonitorPosition(monitor: i32) rlc.Vector2 {
    return rlc.GetMonitorPosition(monitor);
}

pub fn getMonitorWidth(monitor: i32) i32 {
    return rlc.GetMonitorWidth(monitor);
}

pub fn getMonitorHeight(monitor: i32) i32 {
    return rlc.GetMonitorHeight(monitor);
}

pub fn getMonitorPhysicalWidth(monitor: i32) i32 {
    return rlc.GetMonitorPhysicalWidth(monitor);
}

pub fn getMonitorPhysicalHeight(monitor: i32) i32 {
    return rlc.GetMonitorPhysicalHeight(monitor);
}

pub fn getMonitorRefreshRate(monitor: i32) i32 {
    return rlc.GetMonitorRefreshRate(monitor);
}

pub fn getPosition() rlc.Vector2 {
    return rlc.GetWindowPosition();
}

pub fn getScaleDPI() rlc.Vector2 {
    return rlc.GetWindowScaleDPI();
}

pub fn getMonitorName(monitor: i32) []const u8 {
    return rlc.GetMonitorName(monitor);
}

pub fn setClipboardText(text: [*c]const u8) void {
    return rlc.SetClipboardText(text);
}

pub fn getClipboardText() [*c]const u8 {
    return rlc.GetClipboardText();
}

pub fn getClipboardImage() rlc.Image {
    return rlc.GetClipboardImage();
}

pub fn enableEventWaiting() void {
    return rlc.EnableEventWaiting();
}

pub fn disableEventWaiting() void {
    return rlc.DisableEventWaiting();
}
