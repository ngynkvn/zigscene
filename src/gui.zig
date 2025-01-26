const std = @import("std");

const playback = @import("audio/playback.zig");
const config = @import("core/config.zig");
const Direction = @import("core/event.zig").Direction;
const Rectangle = @import("ext/structs.zig").Rectangle;
const controls = @import("gui/controls.zig");
const rl = @import("raylib.zig");

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

pub const UIContext = struct {
    bounds: Rectangle,
    current_y: f32,

    pub fn init(bounds: Rectangle) UIContext {
        return .{
            .bounds = bounds,
            .current_y = bounds.y,
        };
    }

    pub fn nextRow(self: *UIContext, height: f32) Rectangle {
        const result = self.bounds.resize(self.bounds.width, height).translate(0, self.current_y - self.bounds.y);
        self.current_y += height;
        return result;
    }

    pub fn label(self: *UIContext, text: [*c]const u8) void {
        _ = rl.GuiLabel(self.nextRow(24).into(), text);
    }

    pub fn slider(self: *UIContext, text: [*c]const u8, value: *f32, min: f32, max: f32) void {
        const row = self.nextRow(24);
        _ = rl.GuiSlider(row.resize(120, 16).translate(100, 0).into(), text, "", value, min, max);
    }

    pub fn valueBox(self: *UIContext, value: *f32, editing: bool) bool {
        const row = self.nextRow(24);
        const buf = if (editing)
            &Layout.editing_buffer
        else
            std.fmt.bufPrintZ(&Layout.value_buffer, Layout.tunable_fmt, .{value.*}) catch unreachable;

        return rl.GuiValueBoxFloat(row.resize(50, 16).translate(225, 0).into(), "", buf.ptr, value, editing) != 0;
    }
};

pub fn frame() void {
    if (gui_xoffset < 0) {
        gui_xoffset = @trunc(std.math.lerp(gui_xoffset, 0, @min(0.3, 30 * rl.GetFrameTime())));
    }
    const base = Layout.Base;
    const grouptxt = std.fmt.comptimePrint("#{}#;#{}#;#{}#", .{ rl.ICON_ARROW_LEFT, rl.ICON_FX, rl.ICON_COLOR_PICKER });
    _ = rl.GuiToggleGroup(base.into(), grouptxt, @ptrCast(&active_tab));

    const guiStatusBar = base.translate(base.width * 4 + 10, 0).resize(800, base.height).into();
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
    if (rl.GuiButton(base.translate(base.width * 3 + 8, 0).into(), playIconTxt) != 0 and rl.IsMusicValid(playback.music)) {
        if (rl.IsMusicStreamPlaying(playback.music)) {
            rl.PauseMusicStream(playback.music);
        } else {
            rl.ResumeMusicStream(playback.music);
        }
    }

    switch (active_tab) {
        .none => {
            const panel_bounds = Layout.Base.translate(-310 - gui_xoffset, 20).resize(300, 700);
            _ = rl.GuiPanel(panel_bounds.into(), "");
        },
        .scalar => Layout.Scalars.draw(),
        .color => Layout.Colors.draw(),
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
        fn draw() void {
            const anchor = PanelSize.translate(gui_xoffset, 0);
            _ = rl.GuiPanel(anchor.into(), "Scalars");

            var ctx = UIContext.init(anchor.translate(5, 40));
            comptime var nth_field: usize = 0;

            inline for (Fields) |sf| {
                const name, const group = sf;
                ctx.label(name.ptr);

                inline for (group) |optinfo| {
                    const fname, const fval, const frange = optinfo;
                    const field_idx = nth_field;

                    ctx.slider(fname.ptr, fval, frange[0], frange[1]);
                    if (ctx.valueBox(fval, editState == field_idx)) {
                        editState = if (editState == field_idx) null else field_idx;
                        @memset(&value_buffer, 0);
                        _ = std.fmt.bufPrintZ(&value_buffer, "{d}", .{fval.*}) catch unreachable;
                        @memcpy(&editing_buffer, &value_buffer);
                    }
                    nth_field += 1;
                }
                ctx.current_y += 24; // Add spacing between groups
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
            _ = rl.GuiPanel(anchor.into(), "Colors");

            var ctx = UIContext.init(anchor.translate(5, 40));

            inline for (Fields) |info| {
                const name, const cfg = info;
                ctx.label(name.ptr);

                inline for (cfg) |optinfo| {
                    const fname, const fval = optinfo;
                    _ = rl.GuiColorBarHueH(ctx.nextRow(24).resize(100, 16).translate(40, 0).into(), fname.ptr, fval);
                }
                ctx.current_y += 24; // Add spacing between groups
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

pub fn onSwipe(dir: Direction, amount: f32) void {
    switch (dir) {
        .horizontal => {},
        .vertical => {},
    }
    _ = amount;
}
