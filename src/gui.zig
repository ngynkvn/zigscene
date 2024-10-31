const std = @import("std");
const graphics = @import("graphics.zig");
const rl = @import("raylib.zig");
const music = @import("music.zig");
const audio = @import("audio.zig");
const controls = @import("gui/controls.zig");

const Rectangle = @import("ext/structs.zig").Rectangle;

const Tab = enum(c_int) { none, audio, scalar, color };
var prev_tab: Tab = .none;
pub var active_tab: Tab = .scalar;
pub var menu_x: f32 = 0;
/// M is intended as a private namespace for the gui,
/// This is where all comptime info will go
const M = struct {
    /// Length of values in value buffer (+1 for zero)
    /// It is expected that values shouldn't go over 1000 for the tunables.
    const tunable_fmt = "{d:7.3}";
    const vlen = std.fmt.count(tunable_fmt, .{0}) + 1;
    var text_buffer = [_]u8{0} ** 256;
    var value_buffer = [_]u8{0} ** (vlen * 64);
    //                          \__/ ⬋ please be nice to him
    var txt: []u8 = text_buffer[0..0]; //\\//\\//\\//\\//\\

};

pub fn frame() void {
    const base = Layout.Base;
    const grouptxt = std.fmt.comptimePrint("#{}#;#{}#;#{}#;#{}#", .{ rl.ICON_ARROW_LEFT, rl.ICON_FILETYPE_AUDIO, rl.ICON_FX, rl.ICON_COLOR_PICKER });
    _ = rl.GuiToggleGroup(base.into(), grouptxt, @ptrCast(&active_tab));
    const mtp = music.GetMusicTimePlayed();
    const mtl = music.GetMusicTimeLength();
    if (music.IsMusicStreamPlaying()) {
        const fps = rl.GetFPS();
        M.txt = std.fmt.bufPrintZ(&M.text_buffer, "#{}# {s} | {d:4.1}s / {d:4.1}s [FPS:{d}]", .{ rl.ICON_PLAYER_PLAY, music.filename, mtp, mtl, fps }) catch unreachable;
    }
    if (menu_x < 0) {
        menu_x = @trunc(rl.Lerp(menu_x, 0, 30 * rl.GetFrameTime()));
    }
    _ = rl.GuiStatusBar(base.translate(base.width * 4 + 5, 0).resize(800, base.height).into(), M.txt.ptr);

    switch (active_tab) {
        .none => {
            const PanelSize = Layout.Base.translate(-310 - menu_x, 20).resize(300, 700);
            _ = rl.GuiPanel(PanelSize.into(), "");
        },
        .audio => {},
        .scalar => {
            Layout.Scalars.draw();
        },
        .color => {
            Layout.Colors.draw();
        },
    }
}

var Tuners = .{
    graphics.WaveFormLine,
    graphics.WaveFormBar,
    graphics.Bubble,
    audio.Controls,
};
const Layout = struct {
    pub const Base = Rectangle.from(5, 5, 16, 16);
    pub const Scalars = struct {
        fn draw() void {
            const anchor = PanelSize.translate(menu_x, 0);
            const label = Scalars.LabelSize.translate(menu_x, 0);
            _ = rl.GuiPanel(anchor.into(), Label.ptr);
            comptime var nth_field = 0;
            // TODO: refactor this is such a mess
            inline for (Fields, 0..) |sf, gi| {
                const name, const group = sf;
                const offset = Layout.Scalars.Offset;
                const y = InitialOffset + offset * nth_field + offset * gi;
                _ = rl.GuiLabel(label.translate(5, y).into(), name.ptr);
                inline for (group, 0..) |optinfo, fi| {
                    const fname, const fval, const frange = optinfo;
                    const j = nth_field + fi;
                    const buf = std.fmt.bufPrintZ(M.value_buffer[fi * M.vlen .. fi * M.vlen + M.vlen], M.tunable_fmt, .{fval.*}) catch unreachable;
                    _ = rl.GuiSlider(anchor.resize(150, 16).translate(100, y + fi * offset).into(), fname.ptr, "", fval, frange[0], frange[1]);
                    if (rl.GuiValueBoxFloat(anchor.resize(50, 16).translate(255, y + fi * offset).into(), "", buf.ptr, fval, editState[j]) != 0) {
                        editState[j] = !editState[j];
                        std.debug.print("TODO\n", .{});
                    }
                }
                nth_field += group.len;
            }
        }
        fn collect(t: type) struct { []const u8, []controls.Scalar } {
            comptime {
                return .{ @typeName(t), &@field(t, "Scalars") };
            }
        }
        const Fields = [_]struct { []const u8, []controls.Scalar }{
            collect(graphics.WaveFormLine),
            collect(graphics.WaveFormBar),
            collect(graphics.Bubble),
            collect(audio.Controls),
        };
        const numFields: usize = brk: {
            var n = 0;
            for (Fields) |f| {
                n += f[1].len;
            }
            break :brk n;
        };
        var editState: [numFields]bool = @splat(false);
        const PanelSize = Base.translate(2, 20).resize(310, 700);
        const LabelSize = Base.resize(200, 8);
        const Label: []const u8 = "Scalars";
        const Offset: usize = 24;
        const InitialOffset = 60;
    };
    const Colors = struct {
        fn draw() void {
            const anchor = Base.translate(menu_x + 2, 20).resize(200, 700);
            const slider_w = 100;
            const offset = 24;
            const panel = anchor.resize(slider_w, 16);
            _ = rl.GuiPanel(anchor.into(), "Colors");

            comptime var yoff: f32 = 32;
            inline for (Fields) |info| {
                const name, const cfg = info;
                comptime var i: usize = 0;
                _ = rl.GuiLabel(anchor.resize(200, 8).translate(5, yoff).into(), name.ptr);
                inline for (cfg) |optinfo| {
                    const fname, const fval = optinfo;
                    _ = rl.GuiColorBarHueH(panel.translate(40, offset + yoff).into(), fname.ptr, fval);
                    yoff += offset;
                    i += 1;
                }
                yoff += offset;
            }
        }
        fn collect(t: type) struct { []const u8, []controls.Color } {
            return .{ @typeName(t), &@field(t, "Colors") };
        }
        const Fields = [_]struct { []const u8, []controls.Color }{
            collect(graphics.WaveFormLine),
            collect(graphics.WaveFormBar),
            collect(graphics.Bubble),
        };
    };
};
