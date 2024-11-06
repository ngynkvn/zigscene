const std = @import("std");

const playback = @import("audio/playback.zig");
const config = @import("core/config.zig");
const Rectangle = @import("ext/structs.zig").Rectangle;
const controls = @import("gui/controls.zig");
const rl = @import("raylib.zig");
const rg = @import("raygui.zig");

pub const Tab = enum(c_int) { none, scalar, color };
var active_tab: Tab = .scalar;
var gui_xoffset: f32 = 0;
pub const onTabChange = to;

/// Moves the gui state to the desired tab
fn to(next: Tab) void {
    if (Layout.Scalars.editState != null or active_tab == next) return;
    active_tab = next;
    gui_xoffset = -300;
}

var draggingSlider = false;

pub fn frame() void {
    updatePanelAnimation();

    const base = Layout.Base;
    renderTabControls(base);
    renderMusicControls(base);

    // Render active tab
    switch (active_tab) {
        .none => {
            const PanelSize = Layout.Base.translate(-310 - gui_xoffset, 20).resize(300, 700);
            _ = rg.GuiPanel(PanelSize, "");
        },
        .scalar => Layout.Scalars.draw(),
        .color => Layout.Colors.draw(),
    }
}

const PlaybackControl = union(enum) {
    play,
    pause,
    drag: f32,
};
fn handlePlaybackControl(c: PlaybackControl) void {
    switch (c) {
        .play => rl.ResumeMusicStream(playback.music),
        .pause => rl.PauseMusicStream(playback.music),
        .drag => |time| {
            rl.PauseMusicStream(playback.music);
            rl.SeekMusicStream(playback.music, time);
        },
    }
}

fn renderMusicControls(base: Rectangle) void {
    if (!rl.IsMusicValid(playback.music)) return;
    const guiStatusBar = base.translate(base.width * 4 + 10, 0).resize(800, base.height);

    // Progress bar and time display
    var mtp = playback.GetMusicTimePlayed();
    const mtl = playback.GetMusicTimeLength();
    var fbs = std.io.fixedBufferStream(&Layout.txt);
    const text = fbs.writer();
    _ = text.write(playback.filename) catch unreachable;
    text.print(" |{d:7.2}s/{d:7.2}s", .{ mtp, mtl }) catch unreachable;
    _ = rg.GuiStatusBar(guiStatusBar, &Layout.txt);
    if (rg.GuiSliderBar(guiStatusBar, null, null, &mtp, 0, mtl)) {
        draggingSlider = true;
        handlePlaybackControl(.{ .drag = mtp });
    } else if (draggingSlider) { // was dragging, now released
        draggingSlider = false;
        handlePlaybackControl(.play);
    }

    renderPlaybackButton(base);
}

fn renderPlaybackButton(base: Rectangle) void {
    const musicOn = rl.IsMusicStreamPlaying(playback.music) or !rl.IsMusicValid(playback.music);
    var playIconBuffer: [16]u8 = @splat(0);
    const playIconTxt = std.fmt.bufPrintZ(&playIconBuffer, "#{}#", .{if (musicOn) rl.ICON_PLAYER_PLAY else rl.ICON_PLAYER_PAUSE}) catch unreachable;
    if (rg.GuiButton(base.translate(base.width * 3 + 8, 0), playIconTxt)) {
        if (!rl.IsMusicValid(playback.music)) return;
        if (rl.IsMusicStreamPlaying(playback.music)) {
            handlePlaybackControl(.pause);
        } else {
            handlePlaybackControl(.play);
        }
    }
}

fn updatePanelAnimation() void {
    if (gui_xoffset < 0) {
        gui_xoffset = @trunc(std.math.lerp(gui_xoffset, 0, @min(0.3, 30 * rl.GetFrameTime())));
    }
}

fn renderTabControls(base: Rectangle) void {
    const grouptxt = std.fmt.comptimePrint("#{}#;#{}#;#{}#", .{ rl.ICON_ARROW_LEFT, rl.ICON_FX, rl.ICON_COLOR_PICKER });
    _ = rg.GuiToggleGroup(base, grouptxt, @ptrCast(&active_tab));
}

const Layout = struct {
    pub const Base = Rectangle.from(5, 5, 16, 16);
    pub const Scalars = struct {
        var editState: ?usize = null;
        const PanelSize = Base.translate(2, 20).resize(280, 700);
        const LabelSize = Base.resize(200, 8);
        const label: []const u8 = "Scalars";
        const offset: usize = 24;
        const initialOffset = 60;
        fn draw() void {
            const anchor = PanelSize.translate(gui_xoffset, 0);
            const label_rect = LabelSize.translate(gui_xoffset, 0);
            _ = rg.GuiPanel(anchor, label.ptr);
            comptime var nth_field = 0;
            // TODO: refactor this is such a mess
            inline for (Fields, 0..) |sf, gi| {
                const name, const group = sf;
                const y = initialOffset + offset * nth_field + offset * gi;
                _ = rg.GuiLabel(label_rect.translate(5, y), name.ptr);
                inline for (group, 0..) |optinfo, fi| {
                    const fname, const fval, const frange = optinfo;
                    const j = nth_field + fi;
                    _ = rg.GuiSlider(anchor.resize(120, 16).translate(100, y + fi * offset), fname.ptr, "", fval, frange[0], frange[1]);

                    const buf = if (editState == j)
                        &editing_buffer
                    else
                        std.fmt.bufPrintZ(&value_buffer, tunable_fmt, .{fval.*}) catch unreachable;

                    if (rg.GuiValueBoxFloat(anchor.resize(50, 16).translate(225, y + fi * offset), "", buf.ptr, fval, editState == j)) {
                        editState = if (editState == j) null else j;
                        @memset(&value_buffer, 0);
                        _ = std.fmt.bufPrintZ(&value_buffer, "{d}", .{fval.*}) catch unreachable;
                        @memcpy(&editing_buffer, &value_buffer);
                    }
                }
                nth_field += group.len;
            }
        }
        const Fields = [_]struct { []const u8, []const controls.Scalar }{
            .{ "WaveFormLine", &config.Visualizer.WaveFormLine.Scalars },
            .{ "WaveFormBar", &config.Visualizer.WaveFormBar.Scalars },
            .{ "Bubble", &config.Visualizer.Bubble.Scalars },
            .{ "Audio Controls", &config.Audio.Scalars },
            .{ "Shader", &config.Shader.Scalars },
        };
    };
    const Colors = struct {
        const slider_w = 100;
        const offset = 24;
        fn draw() void {
            const anchor = Base.translate(gui_xoffset + 2, 20).resize(200, 700);
            const panel = anchor.resize(slider_w, 16);
            _ = rg.GuiPanel(anchor, "Colors");

            comptime var yoff: f32 = 32;
            inline for (Fields) |info| {
                const name, const cfg = info;
                comptime var i: usize = 0;
                _ = rg.GuiLabel(anchor.resize(200, 8).translate(5, yoff), name.ptr);
                inline for (cfg) |optinfo| {
                    const fname, const fval = optinfo;
                    _ = rl.GuiColorBarHueH(panel.translate(40, offset + yoff).into(), fname.ptr, fval);
                    yoff += offset;
                    i += 1;
                }
                yoff += offset;
            }
        }
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
    //                          \__/ ⬋ please be nice to him
    //                         [0..0]
};
