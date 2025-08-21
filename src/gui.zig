const std = @import("std");
const rl = @import("raylibz");

const config = @import("core/config.zig");
const controls = @import("gui/controls.zig");
const playback = @import("audio/playback.zig");
const rlcolor_picker = @import("gui/color_picker.zig");

const Rectangle = rl.Rectangle;
const Panel = @import("ui/panel.zig").Panel;
const Direction = @import("core/event.zig").Direction;

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
        gui_xoffset = @trunc(std.math.lerp(gui_xoffset, 0, @min(0.3, 30 * rl.getFrameTime())));
    }
    const base = Rectangle.from(5, 5, 16, 16);
    const grouptxt = std.fmt.comptimePrint("#{d}#;#{d}#;#{d}#", .{ rl.Icon.arrow_left, rl.Icon.fx, rl.Icon.color_picker });
    _ = rl.guiToggleGroup(base, grouptxt, @ptrCast(&active_tab));

    const guiStatusBar = base.translate(base.width * 4 + 10, 0).resize(800, base.height);
    if (rl.isMusicValid(playback.music)) {
        var mtp = playback.GetMusicTimePlayed();
        const mtl = playback.GetMusicTimeLength();
        var fbs = std.io.fixedBufferStream(&Layout.txt);
        const text = fbs.writer();
        _ = text.write(playback.filename) catch unreachable;
        text.print(" |{d:7.2}s/{d:7.2}s", .{ mtp, mtl }) catch unreachable;
        if (rl.guiSliderBar(guiStatusBar, null, null, &mtp, 0, mtl) != 0) {
            draggingSlider = true;
            rl.pauseMusicStream(playback.music);
            rl.seekMusicStream(playback.music, mtp);
        } else if (draggingSlider) { // was dragging, now released
            draggingSlider = false;
            rl.resumeMusicStream(playback.music);
        }
    }
    const musicOn = rl.isMusicStreamPlaying(playback.music) or !rl.isMusicValid(playback.music);
    var playIconBuffer: [16]u8 = @splat(0);
    const playIconTxt = std.fmt.bufPrintZ(&playIconBuffer, "#{d}#", .{if (musicOn) rl.Icon.player_play else rl.Icon.player_pause}) catch unreachable;
    _ = rl.guiStatusBar(guiStatusBar, &Layout.txt);
    if (rl.guiButton(base.translate(base.width * 3 + 8, 0), playIconTxt) != 0 and rl.isMusicValid(playback.music)) {
        if (rl.isMusicStreamPlaying(playback.music)) {
            rl.pauseMusicStream(playback.music);
        } else {
            rl.resumeMusicStream(playback.music);
        }
    }

    switch (active_tab) {
        .none => {
            const panel_bounds = base.translate(-310 - gui_xoffset, 20).resize(300, 700);
            _ = rl.guiPanel(panel_bounds, "");
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
                        var bounds = ctx.nextRow(16);
                        bounds.width = 120;

                        ctx.slider(fval, .{
                            .text = fname,
                            .bounds = bounds,
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
                        var row = ctx.nextRow(16);
                        row.width = 120;
                        _ = rlcolor_picker.GuiColorBarHueH(row, fname.ptr, fval);
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
