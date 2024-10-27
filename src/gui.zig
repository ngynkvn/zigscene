const std = @import("std");
const graphics = @import("graphics.zig");
const rl = @import("raylib.zig");
const music = @import("music.zig");
const audio = @import("audio.zig");

const Rectangle = @import("ext/structs.zig").Rectangle;

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
    const base = Rectangle.from(5, 5, 20, 20);
    const a = rl.GuiToggle(base.translate(0, 0).c(), std.fmt.comptimePrint("#{}#", .{rl.ICON_FX}), &active_menu.scalar);
    if (a != 0) {
        std.debug.print("{}\n", .{a});
    }
    const b = rl.GuiToggle(base.translate(base.width, 0).c(), std.fmt.comptimePrint("#{}#", .{rl.ICON_COLOR_PICKER}), &active_menu.color);
    if (b != 0) {
        std.debug.print("{}\n", .{b});
    }
    const mtp = music.GetMusicTimePlayed();
    const mtl = music.GetMusicTimeLength();
    if (music.IsMusicStreamPlaying()) {
        const fps = rl.GetFPS();
        txt = std.fmt.bufPrintZ(&text_buffer, "#{}# {s} | {d:4.1}s / {d:4.1}s [FPS:{d}]", .{ rl.ICON_PLAYER_PLAY, music.filename, mtp, mtl, fps }) catch unreachable;
    }
    _ = rl.GuiStatusBar(base.translate(base.width * 2 + 5, 0).resize(window_width * 2, base.height).c(), txt.ptr);

    if (active_menu.scalar) {
        const anchor = base.translate(2, 20).resize(window_width, 300);
        _ = rl.GuiPanel(anchor.c(), "Scalars");

        comptime var buf_i: usize = 0;
        inline for (&Options, 0..) |info, y| {
            if (!@hasDecl(info, "Scalars")) continue;

            var yoff: f32 = y * 20;
            _ = rl.GuiLabel(anchor.resize(200, 8).translate(5, 40 + yoff).c(), @typeName(info));

            const cfg = @field(info, "Scalars");
            inline for (cfg) |optinfo| {
                const fname = optinfo.name;
                const fval = optinfo.value;
                const buf = std.fmt.bufPrintZ(value_buffer[buf_i * 7 .. buf_i * 7 + 7], "{d:6.2}", .{fval.*}) catch unreachable;
                _ = rl.GuiSlider(anchor.resize(100, 8).translate(100, 32 + yoff).c(), fname.ptr, buf.ptr, fval, optinfo.range[0], optinfo.range[1]);
                yoff += 20;
                buf_i += 1;
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
            if (!@hasDecl(info, "Colors")) continue;

            const cfg = @field(info, "Colors");
            comptime var i: usize = 0;
            _ = rl.GuiLabel(anchor.resize(200, 8).translate(5, 40 + yoff).c(), @typeName(info));
            yoff += 20;
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
