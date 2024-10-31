const std = @import("std");
const graphics = @import("graphics.zig");
const rl = @import("raylib.zig");
const music = @import("music.zig");
const audio = @import("audio.zig");
const controls = @import("gui/controls.zig");

const Rectangle = @import("ext/structs.zig").Rectangle;

var Tuners = .{
    graphics.WaveFormLine,
    graphics.WaveFormBar,
    graphics.Bubble,
    audio.Controls,
};
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
    var value_buffer = [_]u8{0} ** (vlen * Layout.Scalars.NumFields);
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
        menu_x = @trunc(rl.Lerp(menu_x, 0, 0.25));
        std.debug.print("{}\n", .{menu_x});
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

const Layout = struct {
    pub const Base = Rectangle.from(5, 5, 16, 16);
    pub const Scalars = struct {
        fn draw() void {
            const anchor = PanelSize.translate(menu_x, 0);
            const label = Scalars.LabelSize.translate(menu_x, 0);
            _ = rl.GuiPanel(anchor.into(), Label.ptr);
            comptime var y = InitialOffset;
            inline for (Layout.Scalars.Groups) |group| {
                const info, const ygroup = group;
                const cfg = @field(info, Label);
                const offset = Layout.Scalars.Offset;
                _ = rl.GuiLabel(label.translate(5, y).into(), @typeName(info));
                inline for (cfg, 0..) |optinfo, y2| {
                    const fname, const fval, const frange = optinfo;
                    const buf = std.fmt.bufPrintZ(M.value_buffer[y2 * M.vlen .. y2 * M.vlen + M.vlen], M.tunable_fmt, .{fval.*}) catch unreachable;
                    _ = rl.GuiSlider(anchor.resize(150, 16).translate(90, y + y2 * offset).into(), fname.ptr, "", fval, frange[0], frange[1]);
                    if (rl.GuiValueBoxFloat(anchor.resize(50, 16).translate(245, y + y2 * offset).into(), "", buf.ptr, fval, false) != 0) {
                        std.debug.print("TODO\n", .{});
                    }
                }
                y += ygroup;
            }
        }
        const PanelSize = Base.translate(2, 20).resize(300, 700);
        const LabelSize = Base.resize(200, 8);
        const Label: []const u8 = "Scalars";
        const NumFields: usize = field_count();
        const Offset: usize = 24;
        const InitialOffset = 60;
        pub const Groups = sv: {
            const n: usize = group_count();
            var groups: [n]struct { type, usize } = undefined;
            var i = 0;
            for (Tuners) |t| {
                if (@hasDecl(t, Label)) {
                    groups[i] = .{ t, @field(t, Label).len * Offset + (i + 1 * Offset) };
                    i += 1;
                }
            }
            break :sv groups;
        };

        fn field_count() usize {
            var n = 0;
            for (Tuners) |knob| n += if (@hasDecl(knob, Label)) @field(knob, Label).len;
            return comptime n;
        }
        fn group_count() usize {
            var n = 0;
            for (Tuners) |knob| n += if (@hasDecl(knob, Label)) 1;
            return comptime n;
        }
    };
    const Colors = struct {
        fn draw() void {
            const anchor = Base.translate(menu_x + 2, 20).resize(200, 700);
            const slider_w = 100;
            const offset = 24;
            const panel = anchor.resize(slider_w, 16);
            _ = rl.GuiPanel(anchor.into(), "Colors");

            comptime var yoff: f32 = 32;
            inline for (&Tuners) |info| {
                if (!@hasDecl(info, "Colors")) continue;

                const cfg = @field(info, "Colors");
                comptime var i: usize = 0;
                _ = rl.GuiLabel(anchor.resize(200, 8).translate(5, yoff).into(), @typeName(info));
                inline for (cfg) |optinfo| {
                    const fname, const fval = optinfo;
                    _ = rl.GuiColorBarHueH(panel.translate(40, offset + yoff).into(), fname.ptr, fval);
                    yoff += offset;
                    i += 1;
                }
                yoff += offset;
            }
        }
    };
};
