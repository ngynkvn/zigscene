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
pub var gui_xoffset: f32 = 0;
/// Moves the gui state to the desired tab
pub fn to(next: Tab) void {
    if (Layout.Scalars.editState != null or active_tab == next) return;
    active_tab = next;
    gui_xoffset = -300;
}

pub fn frame() void {
    const base = Layout.Base;
    const grouptxt = std.fmt.comptimePrint("#{}#;#{}#;#{}#;#{}#", .{ rl.ICON_ARROW_LEFT, rl.ICON_FILETYPE_AUDIO, rl.ICON_FX, rl.ICON_COLOR_PICKER });
    _ = rl.GuiToggleGroup(base.into(), grouptxt, @ptrCast(&active_tab));

    var fbs = std.io.fixedBufferStream(&Layout.txt);
    const text = fbs.writer();
    text.print("#{}# | {s}", .{ rl.ICON_PLAYER_PLAY, music.filename }) catch unreachable;
    if (music.IsMusicStreamPlaying()) {
        const mtp = music.GetMusicTimePlayed();
        const mtl = music.GetMusicTimeLength();
        text.print(" | {d:7.2}s/{d:7.2}s", .{ mtp, mtl }) catch unreachable;
    }
    text.print(" | [FPS:{d}]\x00", .{rl.GetFPS()}) catch unreachable;
    if (gui_xoffset < 0) {
        gui_xoffset = @trunc(rl.Lerp(gui_xoffset, 0, 30 * rl.GetFrameTime()));
    }
    _ = rl.GuiStatusBar(base.translate(base.width * 4 + 5, 0).resize(800, base.height).into(), &Layout.txt);

    switch (active_tab) {
        .none => {
            const PanelSize = Layout.Base.translate(-310 - gui_xoffset, 20).resize(300, 700);
            _ = rl.GuiPanel(PanelSize.into(), "");
        },
        .audio => {},
        .scalar => Layout.Scalars.draw(),
        .color => Layout.Colors.draw(),
    }
}

const Layout = struct {
    pub const Base = Rectangle.from(5, 5, 16, 16);
    pub const Scalars = struct {
        var editState: ?usize = null;
        const PanelSize = Base.translate(2, 20).resize(310, 700);
        const LabelSize = Base.resize(200, 8);
        const label: []const u8 = "Scalars";
        const offset: usize = 24;
        const initialOffset = 60;
        fn draw() void {
            const anchor = PanelSize.translate(gui_xoffset, 0);
            const label_rect = LabelSize.translate(gui_xoffset, 0);
            _ = rl.GuiPanel(anchor.into(), label.ptr);
            comptime var nth_field = 0;
            // TODO: refactor this is such a mess
            inline for (Fields, 0..) |sf, gi| {
                const name, const group = sf;
                const y = initialOffset + offset * nth_field + offset * gi;
                _ = rl.GuiLabel(label_rect.translate(5, y).into(), name.ptr);
                inline for (group, 0..) |optinfo, fi| {
                    const fname, const fval, const frange = optinfo;
                    const j = nth_field + fi;
                    _ = rl.GuiSlider(anchor.resize(150, 16).translate(100, y + fi * offset).into(), fname.ptr, "", fval, frange[0], frange[1]);

                    const buf = if (editState == j)
                        &editing_buffer
                    else
                        std.fmt.bufPrintZ(&value_buffer, tunable_fmt, .{fval.*}) catch unreachable;

                    if (rl.GuiValueBoxFloat(anchor.resize(50, 16).translate(255, y + fi * offset).into(), "", buf.ptr, fval, editState == j) != 0) {
                        editState = if (editState == j) null else j;
                        @memset(&value_buffer, 0);
                        _ = std.fmt.bufPrintZ(&value_buffer, "{d}", .{fval.*}) catch unreachable;
                        @memcpy(&editing_buffer, &value_buffer);
                    }
                }
                nth_field += group.len;
            }
        }
        const Fields = [_]struct { []const u8, []controls.Scalar }{
            collect(graphics.WaveFormLine),
            collect(graphics.WaveFormBar),
            collect(graphics.Bubble),
            collect(audio.Controls),
        };
        fn collect(t: type) struct { []const u8, []controls.Scalar } {
            comptime return .{ @typeName(t), &@field(t, label) };
        }
        const NumFields: usize = brk: {
            var n = 0;
            for (Fields) |f| {
                n += f[1].len;
            }
            break :brk n;
        };
    };
    const Colors = struct {
        const slider_w = 100;
        const offset = 24;
        fn draw() void {
            const anchor = Base.translate(gui_xoffset + 2, 20).resize(200, 700);
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
        const Fields = [_]struct { []const u8, []controls.Color }{
            collect(graphics.WaveFormLine),
            collect(graphics.WaveFormBar),
            collect(graphics.Bubble),
        };
        fn collect(t: type) struct { []const u8, []controls.Color } {
            comptime return .{ @typeName(t), &@field(t, "Colors") };
        }
    };
    /// Length of values in value buffer (+1 for zero)
    /// It is expected that values shouldn't go over 1000 for the tunables.
    const tunable_fmt = "{d:.3}";
    const vlen = std.fmt.count(tunable_fmt, .{0}) + 10;
    var txt = [_]u8{0} ** 256;
    var value_buffer = [_]u8{0} ** vlen;
    var editing_buffer = [_]u8{0} ** vlen;
    //                          \__/ ⬋ please be nice to him
    //                         [0..0]
};
