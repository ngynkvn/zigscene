const std = @import("std");

const playback = @import("audio/playback.zig");
const config = @import("core/config.zig");
const Direction = @import("core/event.zig").Direction;
const Rectangle = @import("ext/structs.zig").Rectangle;
const controls = @import("gui/controls.zig");
const rl = @import("raylib.zig");
const Panel = @import("ui/panel.zig").Panel;

pub const Tab = enum(c_int) { none, scalar, color };
var active_tab: Tab = .scalar;
var gui_xoffset: f32 = 0;

/// Moves the gui state to the desired tab
pub fn onTabChange(next: Tab) void {
    if (Layout.Scalars.editState != null or active_tab == next) return;
    active_tab = next;
    gui_xoffset = -300;
}

var draggingSlider = false;

var scalar_panel = Panel.init(8, 24, 280, 700, "Scalars");
var color_panel = Panel.init(8, 24, 200, 700, "Colors");

pub fn frame() void {
    if (gui_xoffset < 0) {
        gui_xoffset = @trunc(std.math.lerp(gui_xoffset, 0, @min(0.3, 30 * rl.GetFrameTime())));
    }
    const base = Rectangle.from(5, 5, 16, 16);
    const grouptxt = std.fmt.comptimePrint("#{}#;#{}#;#{}#", .{ rl.ICON_ARROW_LEFT, rl.ICON_FX, rl.ICON_COLOR_PICKER });
    _ = rl.GuiToggleGroup(base, grouptxt, @ptrCast(&active_tab));

    const guiStatusBar = base.translate(base.width * 4 + 10, 0).resize(800, base.height);
    if (rl.IsMusicValid(playback.music)) {
        var mtp = playback.GetMusicTimePlayed();
        const mtl = playback.GetMusicTimeLength();
        var fbs = std.io.fixedBufferStream(&Layout.txt);
        const text = fbs.writer();
        _ = text.write(playback.filename) catch unreachable;
        text.print(" |{d:7.2}s/{d:7.2}s", .{ mtp, mtl }) catch unreachable;
        if (rl.GuiSliderBar(guiStatusBar, null, null, &mtp, 0, mtl) != 0) {
            draggingSlider = true;
            rl.PauseMusicStream(playback.music);
            rl.SeekMusicStream(playback.music, mtp);
        } else if (draggingSlider) { // was dragging, now released
            draggingSlider = false;
            rl.ResumeMusicStream(playback.music);
        }
    }
    const musicOn = rl.IsMusicStreamPlaying(playback.music) or !rl.IsMusicValid(playback.music);
    var playIconBuffer: [16]u8 = @splat(0);
    const playIconTxt = std.fmt.bufPrintZ(&playIconBuffer, "#{}#", .{if (musicOn) rl.ICON_PLAYER_PLAY else rl.ICON_PLAYER_PAUSE}) catch unreachable;
    _ = rl.GuiStatusBar(guiStatusBar, &Layout.txt);
    if (rl.GuiButton(base.translate(base.width * 3 + 8, 0), playIconTxt) != 0 and rl.IsMusicValid(playback.music)) {
        if (rl.IsMusicStreamPlaying(playback.music)) {
            rl.PauseMusicStream(playback.music);
        } else {
            rl.ResumeMusicStream(playback.music);
        }
    }

    switch (active_tab) {
        .none => {
            const panel_bounds = base.translate(-310 - gui_xoffset, 20).resize(300, 700);
            _ = rl.GuiPanel(panel_bounds, "");
        },
        .scalar => {
            scalar_panel.bounds.x = gui_xoffset;
            if (scalar_panel.begin()) {
                var ctx = scalar_panel.context();
                inline for (Layout.Scalars.Fields) |sf| {
                    const name, const group = sf;
                    ctx.label(name.ptr);

                    var group_ctx = ctx.group();
                    group_ctx.begin(92);
                    inline for (group) |optinfo| {
                        const fname, const fval, const frange = optinfo;

                        ctx.slider(fval, .{
                            .text = fname,
                            .bounds = ctx.nextRow(16).with(.{ .width = 120 }),
                            .min = frange[0],
                            .max = frange[1],
                            .valueBox = true,
                        });
                        // TODO:
                        // if(ctx.valueBox(fval, Layout.Scalars.editState == field_idx)){
                        //     Layout.Scalars.editState = if (Layout.Scalars.editState == field_idx) null else field_idx;
                        //     @memset(&Layout.value_buffer, 0);
                        //     _ = std.fmt.bufPrintZ(&Layout.value_buffer, "{d}", .{fval.*}) catch unreachable;
                        //     @memcpy(&Layout.editing_buffer, &Layout.value_buffer);
                        // }
                    }
                    group_ctx.end();
                }
            }
        },
        .color => {
            color_panel.bounds.x = gui_xoffset;
            if (color_panel.begin()) {
                var ctx = color_panel.context();
                inline for (Layout.Colors.Fields) |info| {
                    const name, const cfg = info;
                    ctx.label(name.ptr);

                    var group_ctx = ctx.group();
                    group_ctx.begin(40);
                    inline for (cfg) |optinfo| {
                        const fname, const fval = optinfo;
                        const row = ctx.nextRow(16);
                        _ = rl.GuiLabel(row.with(.{ .x = row.x }), fname.ptr);
                        _ = rl.GuiColorBarHueH(row.with(.{ .width = 120 }), fname.ptr, fval);
                    }
                    group_ctx.end();
                }
            }
        },
    }
}

const Layout = struct {
    pub const Scalars = struct {
        var editState: ?usize = null;
        const Fields = [_]struct { []const u8, []const controls.Scalar }{
            .{ "WaveFormLine", &config.Visualizer.WaveFormLine.Scalars },
            .{ "WaveFormBar", &config.Visualizer.WaveFormBar.Scalars },
            .{ "Bubble", &config.Visualizer.Bubble.Scalars },
            .{ "Audio Controls", &config.Audio.Scalars },
            .{ "Shader", &config.Shader.Scalars },
        };
    };
    const Colors = struct {
        const Fields = [_]struct { []const u8, []const controls.Color }{
            .{ "WaveFormLine", &config.Visualizer.WaveFormLine.Colors },
            .{ "WaveFormBar", &config.Visualizer.WaveFormBar.Colors },
            .{ "Bubble", &config.Visualizer.Bubble.Colors },
        };
    };
    /// Length of values in value buffer (+1 for zero)
    /// It is expected that values shouldn't go over 1000 for the tunables.
    const tunable_fmt = "{d:7.3}";
    const vlen = std.fmt.count(tunable_fmt, .{0}) + 5;
    var txt = [_]u8{0} ** 256;
    var value_buffer = [_]u8{0} ** vlen;
    var editing_buffer = [_]u8{0} ** vlen;
    //        ⬋ please be nice to him
    //   /\_/\
    // =(• . •)=
    //  /     \
};

pub fn onSwipe(dir: Direction, amount: f32) void {
    switch (dir) {
        .horizontal => {},
        .vertical => {},
    }
    _ = amount;
}
