const std = @import("std");

const playback = @import("audio/playback.zig");
const config = @import("core/config.zig");
const Rectangle = @import("ext/structs.zig").Rectangle;
const controls = @import("gui/controls.zig");
const rl = @import("raylib.zig");

// GUI state
pub const Tab = enum(c_int) { none, scalar, color };
var active_tab: Tab = .scalar;
var gui_xoffset: f32 = 0;
var dragging_slider = false;
pub const onTabChange = to;

/// Moves the gui state to the desired tab
fn to(next: Tab) void {
    if (Layout.Scalars.editState != null or active_tab == next) return;
    active_tab = next;
    gui_xoffset = -300;
}

/// Handles drawing and interaction with the music playback controls
fn drawPlaybackControls(base: Rectangle) void {
    const status_bar = base.translate(base.width * 4 + 10, 0).resize(800, base.height).into();

    if (rl.IsMusicValid(playback.music)) {
        var music_time = playback.GetMusicTimePlayed();
        const total_time = playback.GetMusicTimeLength();

        // Format status text
        var fbs = std.io.fixedBufferStream(&Layout.txt);
        const text = fbs.writer();
        _ = text.write(playback.filename) catch unreachable;
        text.print(" |{d:7.2}s/{d:7.2}s", .{ music_time, total_time }) catch unreachable;

        // Handle timeline slider
        if (rl.GuiSliderBar(status_bar, null, null, &music_time, 0, total_time) != 0) {
            dragging_slider = true;
            rl.PauseMusicStream(playback.music);
            rl.SeekMusicStream(playback.music, music_time);
        } else if (dragging_slider) {
            dragging_slider = false;
            rl.ResumeMusicStream(playback.music);
        }
    }

    _ = rl.GuiStatusBar(status_bar, &Layout.txt);

    // Play/pause button
    const music_playing = rl.IsMusicStreamPlaying(playback.music) or !rl.IsMusicValid(playback.music);
    var play_icon_buffer: [16]u8 = @splat(0);
    const play_icon = std.fmt.bufPrintZ(&play_icon_buffer, "#{}#", .{
        if (music_playing) rl.ICON_PLAYER_PLAY else rl.ICON_PLAYER_PAUSE,
    }) catch unreachable;

    const play_btn = base.translate(base.width * 3 + 8, 0).into();
    if (rl.GuiButton(play_btn, play_icon) != 0 and rl.IsMusicValid(playback.music)) {
        if (music_playing) {
            rl.PauseMusicStream(playback.music);
        } else {
            rl.ResumeMusicStream(playback.music);
        }
    }
}

pub fn frame() void {
    // Animate GUI sliding
    if (gui_xoffset < 0) {
        gui_xoffset = @trunc(std.math.lerp(gui_xoffset, 0, @min(0.3, 30 * rl.GetFrameTime())));
    }

    const base = Layout.Base;

    // Draw tab selector
    const group_text = std.fmt.comptimePrint("#{}#;#{}#;#{}#", .{
        rl.ICON_ARROW_LEFT,
        rl.ICON_FX,
        rl.ICON_COLOR_PICKER,
    });
    _ = rl.GuiToggleGroup(base.into(), group_text, @ptrCast(&active_tab));

    drawPlaybackControls(base);

    // Draw active tab content
    switch (active_tab) {
        .none => {
            const panel_size = Layout.Base.translate(-310 - gui_xoffset, 20).resize(300, 700);
            _ = rl.GuiPanel(panel_size.into(), "");
        },
        .scalar => Layout.Scalars.draw(),
        .color => Layout.Colors.draw(),
    }
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

        fn drawScalarControlGroup(anchor: Rectangle, label_rect: Rectangle, comptime name: []const u8, comptime group: []const controls.Scalar, comptime y: usize, comptime nth_field: usize) void {
            _ = rl.GuiLabel(label_rect.translate(5, y).into(), name.ptr);

            inline for (group, 0..) |optinfo, fi| {
                const fname, const fval, const frange = optinfo;
                const j = nth_field + fi;

                _ = rl.GuiSlider(
                    anchor.resize(120, 16).translate(100, @floatFromInt(y + fi * offset)).into(),
                    fname.ptr,
                    "",
                    fval,
                    frange[0],
                    frange[1],
                );

                const buf = if (editState == j)
                    &editing_buffer
                else
                    std.fmt.bufPrintZ(&value_buffer, tunable_fmt, .{fval.*}) catch unreachable;

                if (rl.GuiValueBoxFloat(
                    anchor.resize(50, 16).translate(225, @floatFromInt(y + fi * offset)).into(),
                    "",
                    buf.ptr,
                    fval,
                    editState == j,
                ) != 0) {
                    editState = if (editState == j) null else j;
                    @memset(&value_buffer, 0);
                    _ = std.fmt.bufPrintZ(&value_buffer, "{d}", .{fval.*}) catch unreachable;
                    @memcpy(&editing_buffer, &value_buffer);
                }
            }
        }

        fn draw() void {
            const anchor = PanelSize.translate(gui_xoffset, 0);
            const label_rect = LabelSize.translate(gui_xoffset, 0);
            _ = rl.GuiPanel(anchor.into(), label.ptr);

            comptime var nth_field: usize = 0;
            inline for (Fields, 0..) |sf, gi| {
                const name, const group = sf;
                const y = initialOffset + offset * nth_field + offset * gi;
                drawScalarControlGroup(anchor, label_rect, name, group, y, nth_field);
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

        fn drawColorControlGroup(anchor: Rectangle, panel: Rectangle, comptime name: []const u8, comptime colors: []const controls.Color, comptime y: usize) void {
            _ = rl.GuiLabel(anchor.resize(200, 8).translate(5, y).into(), name.ptr);
            for (colors, 1..) |optinfo, i| {
                const fname, const fval = optinfo;
                _ = rl.GuiColorBarHueH(panel.translate(40, @floatFromInt(y + i * offset)).into(), fname.ptr, fval);
            }
        }

        fn draw() void {
            const anchor = Base.translate(gui_xoffset + 2, 20).resize(200, 700);
            const panel = anchor.resize(slider_w, 16);
            _ = rl.GuiPanel(anchor.into(), "Colors");

            comptime var y: f32 = 32;
            inline for (Fields) |info| {
                const name, const cfg = info;
                drawColorControlGroup(anchor, panel, name, cfg, y);
                y += cfg.len * offset + offset;
            }
        }

        const Fields = [_]struct { []const u8, []const controls.Color }{
            .{ "WaveFormLine", &config.Visualizer.WaveFormLine.Colors },
            .{ "WaveFormBar", &config.Visualizer.WaveFormBar.Colors },
            .{ "Bubble", &config.Visualizer.Bubble.Colors },
        };
    };

    const tunable_fmt = "{d:7.3}";
    const vlen = std.fmt.count(tunable_fmt, .{0}) + 5;
    var txt = [_]u8{0} ** 256;
    var value_buffer = [_]u8{0} ** vlen;
    var editing_buffer = [_]u8{0} ** vlen;
};
