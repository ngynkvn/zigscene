const std = @import("std");

const playback = @import("audio/playback.zig");
const capture = @import("audio/capture.zig");
const config = @import("core/config.zig");
const Direction = @import("core/event.zig").Direction;
const Rectangle = @import("ext/structs.zig").Rectangle;
const controls = @import("gui/controls.zig");
const rl = @import("raylib.zig");

pub const Tab = enum(c_int) { none, scalar, color, motion, scene };
var active_tab: Tab = .scalar;
var gui_xoffset: f32 = 0;
pub const onTabChange = to;

/// Moves the gui state to the desired tab
fn to(next: Tab) void {
    if (active_tab == next) return;
    Layout.Scalars.editState = null;
    active_tab = next;
    gui_xoffset = -300;
}

var draggingSlider = false;

pub fn frame() void {
    if (gui_xoffset < 0) {
        gui_xoffset = @trunc(std.math.lerp(gui_xoffset, 0, @min(0.3, 30 * rl.GetFrameTime())));
    }
    const base = Layout.Base;
    const grouptxt = std.fmt.comptimePrint("#{}#;#{}#;#{}#;#{}#;#{}#", .{ rl.ICON_ARROW_LEFT, rl.ICON_FX, rl.ICON_COLOR_PICKER, rl.ICON_GEAR, rl.ICON_EYE_ON });
    _ = rl.GuiToggleGroup(base.into(), grouptxt, @ptrCast(&active_tab));

    const guiStatusBar = base.translate(base.width * 6 + 10, 0).resize(800, base.height).into();
    if (capture.active) {
        _ = std.fmt.bufPrintZ(&Layout.txt, "{s} audio capture active (M to stop)", .{if (capture.mode == .system) "System" else "Input"}) catch unreachable;
    } else if (rl.IsMusicValid(playback.music)) {
        var mtp = playback.GetMusicTimePlayed();
        const mtl = playback.GetMusicTimeLength();
        _ = std.fmt.bufPrintZ(&Layout.txt, "{s} |{d:7.2}s/{d:7.2}s", .{ playback.filename, mtp, mtl }) catch unreachable;
        if (rl.GuiSliderBar(guiStatusBar, null, null, &mtp, 0, mtl) != 0) {
            draggingSlider = true;
            rl.PauseMusicStream(playback.music);
            rl.SeekMusicStream(playback.music, mtp);
        } else if (draggingSlider) { // was dragging, now released
            draggingSlider = false;
            rl.ResumeMusicStream(playback.music);
        }
    } else {
        _ = std.fmt.bufPrintZ(&Layout.txt, "M: capture system audio | Drop a file to play", .{}) catch unreachable;
    }
    const musicOn = rl.IsMusicStreamPlaying(playback.music) or !rl.IsMusicValid(playback.music);
    var playIconBuffer: [16]u8 = @splat(0);
    const playIconTxt = std.fmt.bufPrintZ(&playIconBuffer, "#{}#", .{if (musicOn) rl.ICON_PLAYER_PLAY else rl.ICON_PLAYER_PAUSE}) catch unreachable;
    _ = rl.GuiStatusBar(guiStatusBar, &Layout.txt);
    if (rl.GuiButton(base.translate(base.width * 3 + 8, 0).into(), playIconTxt) != 0 and !capture.active and rl.IsMusicValid(playback.music)) {
        if (rl.IsMusicStreamPlaying(playback.music)) {
            rl.PauseMusicStream(playback.music);
        } else {
            rl.ResumeMusicStream(playback.music);
        }
    }

    switch (active_tab) {
        .none => {
            const PanelSize = Layout.Base.translate(-310 - gui_xoffset, 20).resize(300, 700);
            _ = rl.GuiPanel(PanelSize.into(), "");
        },
        .scalar => Layout.Scalars.draw(false),
        .color => Layout.Colors.draw(),
        .motion => Layout.Scalars.draw(true),
        .scene => Layout.Scene.draw(),
    }
}

const Layout = struct {
    pub const Base = Rectangle.from(5, 5, 16, 16);
    /// An input is always aware of where it's positioned, and reacts to IO (mouse / keyboard)
    pub const ValueInput = struct {
        base: Rectangle,
    };

    pub const Scalars = struct {
        var editState: ?usize = null;
        const PanelSize = Base.translate(2, 20).resize(280, 700);
        const LabelSize = Base.resize(200, 8);
        const label: []const u8 = "Scalars";
        const offset: usize = 24;
        const initialOffset = 60;
        fn draw(comptime motion_controls: bool) void {
            const fields = if (motion_controls) MotionFields else ShapeFields;
            const anchor = PanelSize.translate(gui_xoffset, 0);
            const label_rect = LabelSize.translate(gui_xoffset, 0);
            _ = rl.GuiPanel(anchor.into(), if (motion_controls) "Motion" else label.ptr);
            comptime var nth_field = 0;
            // TODO: refactor this is such a mess
            inline for (fields, 0..) |sf, gi| {
                const name, const group = sf;
                const y = initialOffset + offset * nth_field + offset * gi;
                _ = rl.GuiLabel(label_rect.translate(5, y).into(), name.ptr);
                inline for (group, 0..) |optinfo, fi| {
                    const fname, const fval, const frange = optinfo;
                    const j = nth_field + fi;
                    _ = rl.GuiSlider(anchor.resize(120, 16).translate(100, y + fi * offset).into(), fname.ptr, "", fval, frange[0], frange[1]);

                    const buf = if (editState == j)
                        &editing_buffer
                    else
                        std.fmt.bufPrintZ(&value_buffer, tunable_fmt, .{fval.*}) catch unreachable;

                    if (rl.GuiValueBoxFloat(anchor.resize(50, 16).translate(225, y + fi * offset).into(), "", buf.ptr, fval, editState == j) != 0) {
                        editState = if (editState == j) null else j;
                        @memset(&value_buffer, 0);
                        _ = std.fmt.bufPrintZ(&value_buffer, "{d}", .{fval.*}) catch unreachable;
                        @memcpy(&editing_buffer, &value_buffer);
                    }
                }
                nth_field += group.len;
            }
        }
        const ShapeFields = [_]struct { []const u8, []const controls.Scalar }{
            .{ "WaveFormLine", &config.Visualizer.WaveFormLine.Scalars },
            .{ "WaveFormBar", &config.Visualizer.WaveFormBar.Scalars },
            .{ "Bubble", &config.Visualizer.Bubble.Scalars },
            .{ "Shader", &config.Shader.Scalars },
        };
        const MotionFields = [_]struct { []const u8, []const controls.Scalar }{
            .{ "Window", &config.Window.Scalars },
            .{ "Energy motion", &config.Motion.Scalars },
            .{ "Audio Controls", &config.Audio.Scalars },
            .{ "Spectrum", &config.Visualizer.Spectrum.Scalars },
            .{ "Halo", &config.Visualizer.Halo.Scalars },
        };
    };
    const Scene = struct {
        const items = [_]struct { [*:0]const u8, *bool }{
            .{ "Waveform lines", &config.Scene.wave_lines },
            .{ "Waveform bars", &config.Scene.wave_bars },
            .{ "Spectrum", &config.Scene.spectrum },
            .{ "3D bubble", &config.Scene.bubble },
            .{ "Frequency halo", &config.Scene.halo },
        };
        fn draw() void {
            const anchor = Base.translate(gui_xoffset + 2, 20).resize(280, 700);
            _ = rl.GuiPanel(anchor.into(), "Scene elements");
            inline for (items, 0..) |item, i| {
                _ = rl.GuiCheckBox(anchor.resize(20, 20).translate(18, 40 + i * 38).into(), item[0], item[1]);
            }
        }
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
        const Fields = [_]struct { []const u8, []const controls.Color }{
            .{ "WaveFormLine", &config.Visualizer.WaveFormLine.Colors },
            .{ "WaveFormBar", &config.Visualizer.WaveFormBar.Colors },
            .{ "Bubble", &config.Visualizer.Bubble.Colors },
            .{ "Halo", &config.Visualizer.Halo.Colors },
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

pub fn onSwipe(dir: Direction, amount: f32) void {
    switch (dir) {
        .horizontal => {},
        .vertical => {},
    }
    _ = amount;
}
