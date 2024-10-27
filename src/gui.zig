const std = @import("std");
const graphics = @import("graphics.zig");
const rl = @import("raylib.zig");
const music = @import("music.zig");
const audio = @import("audio.zig");

pub const Rectangle = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    pub fn R(x: f32, y: f32, width: f32, height: f32) Rectangle {
        return .{ .x = x, .y = y, .width = width, .height = height };
    }
    pub fn resize(self: Rectangle, width: f32, height: f32) Rectangle {
        return .{ .x = self.x, .y = self.y, .width = width, .height = height };
    }
    pub fn translate(self: Rectangle, dx: f32, dy: f32) Rectangle {
        return .{ .x = self.x + dx, .y = self.y + dy, .width = self.width, .height = self.height };
    }
    pub fn c(self: Rectangle) rl.Rectangle {
        return .{ .x = self.x, .y = self.y, .width = self.width, .height = self.height };
    }
};
pub const R = Rectangle.R;

const active_menu = struct {
    var scalar: bool = false;
    var color: bool = true;
};
var Options = .{
    graphics.WaveFormLine,
    graphics.WaveFormBar,
    graphics.Bubble,
    audio.Controls,
};
const window_width = 400;
var value_buffer = std.mem.zeroes([256]u8);
var text_buffer = std.mem.zeroes([256:0]u8);
//                          \__/ ⬋ please be nice to him
var txt: []u8 = text_buffer[0..0]; //\\//\\//\\//\\//\\
pub fn frame() void {
    const base = R(5, 5, 16, 16);
    const a = rl.GuiToggle(base.translate(0, 0).c(), std.fmt.comptimePrint("#{}#", .{rl.ICON_FX}), &active_menu.scalar);
    if (a != 0) {
        std.debug.print("{}\n", .{a});
    }
    const b = rl.GuiToggle(base.translate(21, 0).c(), std.fmt.comptimePrint("#{}#", .{rl.ICON_COLOR_PICKER}), &active_menu.color);
    if (b != 0) {
        std.debug.print("{}\n", .{b});
    }
    const mtp = music.GetMusicTimePlayed();
    const mtl = music.GetMusicTimeLength();
    if (music.IsMusicStreamPlaying()) {
        const fps = rl.GetFPS();
        txt = std.fmt.bufPrintZ(&text_buffer, "#{}# {s} | {d:4.1}s / {d:4.1}s [FPS:{d}]", .{ rl.ICON_PLAYER_PLAY, music.filename, mtp, mtl, fps }) catch unreachable;
    }
    _ = rl.GuiStatusBar(base.translate(base.width * 2 + 10, 0).resize(window_width * 2, 16).c(), txt.ptr);

    if (active_menu.scalar) {
        const anchor = base.translate(2, 20).resize(window_width, 400);
        _ = rl.GuiPanel(anchor.c(), "Scalars");

        comptime var yoff: f32 = 0;
        comptime var i: usize = 0;
        inline for (&Options) |info| {
            const name = @typeName(info);
            _ = rl.GuiLabel(anchor.resize(200, 8).translate(5, 40 + yoff).c(), name.ptr);
            yoff += 20;
            const cfg = @field(info, "Scalars");
            inline for (cfg) |optinfo| {
                const fname = optinfo.name;
                const fval = optinfo.value;
                const buf = std.fmt.bufPrintZ(value_buffer[i * 7 .. i * 7 + 7], "{d:6.2}", .{fval.*}) catch unreachable;
                _ = rl.GuiSlider(anchor.resize(100, 8).translate(100, 32 + yoff).c(), fname.ptr, buf.ptr, fval, optinfo.range[0], optinfo.range[1]);
                yoff += 20;
                i += 1;
            }
            yoff += 20;
        }
    } else if (active_menu.color) {
        const anchor = base.translate(2, 20).resize(window_width / 2, 400);
        const panel_size = 90;
        const panel_spacing = 40;
        const panel = anchor.resize(16, panel_size);
        _ = rl.GuiPanel(anchor.c(), "Colors");

        comptime var yoff: f32 = 0;
        inline for (&Options) |info| {
            comptime var i: usize = 0;
            const name = @typeName(info);
            _ = rl.GuiLabel(anchor.resize(200, 8).translate(5, 40 + yoff).c(), name.ptr);
            yoff += 20;
            const cfg = @field(info, "Colors");
            inline for (cfg) |optinfo| {
                const fname = optinfo.name;
                const fval: *f32 = optinfo.hue;
                _ = rl.GuiColorBarHue(panel.translate(40 + panel_spacing * (i % 3), 40 + yoff).c(), fname.ptr, fval);
                i += 1;
            }
            yoff += 100;
        }
    }
}
