const std = @import("std");
const builtin = @import("builtin");
const ui = @import("raylib");

const AudioSession = @import("audio/Session.zig");
const config = @import("core/config.zig");
const Direction = @import("core/event.zig").Direction;
const Rectangle = @import("ext/structs.zig").Rectangle;
const controls = @import("gui/controls.zig");
const PanelLayout = @import("gui/panel_layout.zig");
const rl = @import("raylib.zig");

pub const Tab = enum(c_int) { none, scalar, color, motion, scene };
var active_tab: Tab = .scalar;
var panel_scroll: rl.Vector2 = .{};
pub const onTabChange = to;

/// Moves the gui state to the desired tab
fn to(next: Tab) void {
    if (active_tab == next) return;
    Layout.Scalars.editState = null;
    active_tab = next;
    panel_scroll = .{};
}

var draggingSlider = false;

pub fn frame(audio: *AudioSession) void {
    if (draggingSlider and (audio.captureActive() or !audio.hasFile())) draggingSlider = false;
    const width: f32 = @floatFromInt(rl.GetScreenWidth());
    const height: f32 = @floatFromInt(rl.GetScreenHeight());
    const bar = Rectangle.from(12, height - 156, width - 24, 144);
    _ = rl.GuiPanel(bar.into(), null);
    if (audio.captureActive()) {
        _ = std.fmt.bufPrintZ(&Layout.txt, "LIVE  /  {s} audio", .{if (audio.captureMode() == .system) "System" else "Input"}) catch unreachable;
    } else if (audio.hasFile()) {
        _ = std.fmt.bufPrintZ(&Layout.txt, "{s}  /  {s}", .{
            if (audio.isFilePlaying()) "Playing" else "Paused",
            audio.filename()[0..@min(audio.filename().len, 140)],
        }) catch unreachable;
    } else {
        _ = std.fmt.bufPrintZ(&Layout.txt, "Ready when you are - drop an audio file to begin", .{}) catch unreachable;
    }
    _ = rl.GuiLabel(bar.translate(12, 6).resize(bar.width - 24, 24).into(), &Layout.txt);
    if (audio.captureActive() or !audio.hasFile()) ui.GuiDisable();
    if (rl.GuiButton(bar.translate(12, 38).resize(100, 30).into(), if (audio.isFilePlaying()) "Pause (P)" else "Play (P)") != 0) audio.togglePlayback();
    ui.GuiEnable();
    if (builtin.os.tag == .emscripten) ui.GuiDisable();
    if (rl.GuiButton(bar.translate(122, 38).resize(166, 30).into(), if (audio.captureActive()) "Stop capture (M)" else "System audio (M)") != 0) audio.toggleSystemCapture();
    ui.GuiEnable();
    _ = rl.GuiSlider(bar.translate(360, 44).resize(@max(60, @min(140, bar.width - 450)), 20).into(), "Volume", "", &config.Audio.volume, 0, 1);
    var volume_text: [16]u8 = undefined;
    const volume_label = std.fmt.bufPrintZ(&volume_text, "{d}%", .{@as(u32, @intFromFloat(config.Audio.volume * 100))}) catch unreachable;
    _ = rl.GuiLabel(bar.translate(@max(420, @min(500, bar.width - 90)) + 8, 40).resize(60, 28).into(), volume_label);
    if (!audio.captureActive() and audio.hasFile()) {
        drawWaveformScrubber(audio, bar.translate(12, 78).resize(bar.width - 24, 58).into());
    } else {
        _ = rl.GuiLabel(bar.translate(12, 78).resize(bar.width - 24, 24).into(), if (audio.captureActive()) "Listening live. Drop a file to switch to playback." else if (builtin.os.tag == .emscripten) "Drop a file anywhere in the window." else "Drop a file anywhere, or choose System audio to listen live.");
    }

    const tabs = [_][*:0]const u8{ "Hide (1)", "Shape (2)", "Colors (3)", "Motion (4)", "Scene (5)" };
    for (tabs, 0..) |label, index| {
        var selected = @intFromEnum(active_tab) == index;
        if (ui.GuiToggle(Rectangle.from(12 + @as(f32, @floatFromInt(index)) * 104, 12, 98, 32).into(), label, &selected) != 0) to(@enumFromInt(index));
    }
    switch (active_tab) {
        .none => {},
        .scalar => Layout.Scalars.draw(false),
        .color => Layout.Colors.draw(),
        .motion => Layout.Scalars.draw(true),
        .scene => Layout.Scene.draw(),
    }
    if (!audio.hasFile() and !audio.captureActive() and width >= 860) {
        const card = Rectangle.from(400, @max(90, height * 0.35), width - 424, 142);
        _ = rl.GuiPanel(card.into(), "Welcome to zigscene");
        _ = rl.GuiLabel(card.translate(20, 38).resize(card.width - 40, 28).into(), "Drop an audio file to bring the scene to life.");
        _ = rl.GuiLabel(card.translate(20, 72).resize(card.width - 40, 24).into(), "Choose Scene to show or hide visual effects.");
        _ = rl.GuiLabel(card.translate(20, 102).resize(card.width - 40, 24).into(), "Shape, Colors and Motion make it yours.");
    }
}

pub fn pointerOverUi() bool {
    const mouse = rl.GetMousePosition();
    return mouse.y < 52 or mouse.y >= @as(f32, @floatFromInt(rl.GetScreenHeight())) - 168 or
        (active_tab != .none and mouse.x < 384);
}

pub fn editingValue() bool {
    return Layout.Scalars.editState != null;
}

fn beginPanel(title: [*:0]const u8, content_height: f32) Rectangle {
    const bounds = Rectangle.from(12, 56, 368, @max(80, @as(f32, @floatFromInt(rl.GetScreenHeight())) - 224));
    var view: rl.Rectangle = undefined;
    _ = ui.GuiScrollPanel(bounds.into(), title, Rectangle.from(0, 0, 342, content_height).into(), &panel_scroll, &view);
    ui.BeginScissorMode(@intFromFloat(view.x), @intFromFloat(view.y), @intFromFloat(view.width), @intFromFloat(view.height));
    if (!rl.CheckCollisionPointRec(rl.GetMousePosition(), view)) ui.GuiLock();
    return Rectangle.from(view.x, view.y + panel_scroll.y, 342, content_height);
}

fn endPanel() void {
    ui.GuiUnlock();
    ui.EndScissorMode();
}

fn drawWaveformScrubber(audio: *AudioSession, status: rl.Rectangle) void {
    const inset: f32 = 2;
    const bounds = rl.Rectangle{
        .x = status.x + inset,
        .y = status.y + inset,
        .width = status.width - inset * 2,
        .height = status.height - inset * 2,
    };
    const duration = audio.timeLength();
    const mouse = rl.GetMousePosition();
    if (duration > 0 and rl.CheckCollisionPointRec(mouse, bounds) and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
        draggingSlider = true;
        audio.beginSeek();
    }
    if (draggingSlider and rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
        const fraction = std.math.clamp((mouse.x - bounds.x) / bounds.width, 0, 1);
        audio.seekTo(duration * fraction);
    }
    if (draggingSlider and rl.IsMouseButtonReleased(rl.MOUSE_BUTTON_LEFT)) {
        draggingSlider = false;
        audio.endSeek();
    }

    rl.DrawRectangleRec(bounds, .{ .r = 12, .g = 16, .b = 24, .a = 220 });
    const peaks = audio.waveform();
    const played = std.math.clamp(audio.timePlayed() / @max(duration, 0.001), 0, 1);
    const columns: usize = @intFromFloat(@max(1, @floor(bounds.width)));
    for (0..if (peaks.len == 0) 0 else columns) |column| {
        const peak = peaks[@min(column * peaks.len / columns, peaks.len - 1)];
        const x = bounds.x + @as(f32, @floatFromInt(column));
        const half_height = @max(1, peak * (bounds.height * 0.46));
        const color: rl.Color = if (@as(f32, @floatFromInt(column)) / @as(f32, @floatFromInt(columns)) <= played)
            .{ .r = 56, .g = 210, .b = 255, .a = 255 }
        else
            .{ .r = 115, .g = 128, .b = 150, .a = 210 };
        rl.DrawLineV(.{ .x = x, .y = bounds.y + bounds.height * 0.5 - half_height }, .{ .x = x, .y = bounds.y + bounds.height * 0.5 + half_height }, color);
    }
    const playhead_x = bounds.x + bounds.width * played;
    rl.DrawLineV(.{ .x = playhead_x, .y = bounds.y }, .{ .x = playhead_x, .y = bounds.y + bounds.height }, rl.WHITE);

    // Keep the timer on the waveform, with a solid backing for busy tracks.
    const elapsed: u32 = @intFromFloat(@max(0, audio.timePlayed()));
    const total: u32 = @intFromFloat(@max(0, duration));
    var timer_buffer: [48]u8 = undefined;
    const timer = std.fmt.bufPrintZ(&timer_buffer, "{d}:{d:0>2} / {d}:{d:0>2}", .{
        elapsed / 60, elapsed % 60, total / 60, total % 60,
    }) catch unreachable;
    const timer_width = ui.MeasureTextEx(ui.GuiGetFont(), timer, @floatFromInt(ui.GuiGetStyle(ui.DEFAULT, ui.TEXT_SIZE)), @floatFromInt(ui.GuiGetStyle(ui.DEFAULT, ui.TEXT_SPACING))).x + 40;
    const timer_bounds = Rectangle.from(bounds.x + bounds.width - timer_width - 6, bounds.y + 4, timer_width, 24);
    rl.DrawRectangleRec(timer_bounds.into(), .{ .r = 12, .g = 16, .b = 24, .a = 255 });
    _ = rl.GuiLabel(timer_bounds.translate(8, 0).resize(timer_width - 8, 24).into(), timer);
}

const Layout = struct {
    pub const Base = Rectangle.from(5, 5, 16, 16);
    /// An input is always aware of where it's positioned, and reacts to IO (mouse / keyboard)
    pub const ValueInput = struct {
        base: Rectangle,
    };

    pub const Scalars = struct {
        var editState: ?usize = null;
        const offset: usize = 36;
        const initialOffset = 12;
        fn draw(comptime motion_controls: bool) void {
            const fields = if (motion_controls) MotionFields else ShapeFields;
            const content_height = comptime blk: {
                var total: usize = initialOffset;
                for (fields) |group| total += 32 + group[1].len * offset + 16;
                break :blk total;
            };
            const anchor = beginPanel(if (motion_controls) "Motion & audio - scroll for more" else "Shape & effects - scroll for more", content_height);
            defer endPanel();
            var layout = PanelLayout.init(anchor, initialOffset);
            var field_index: usize = 0;
            inline for (fields) |sf| {
                const name, const group = sf;
                _ = rl.GuiLabel(layout.row(32).translate(12, 0).resize(310, 24).into(), name.ptr);
                inline for (group) |optinfo| {
                    const fname, const fval, const frange = optinfo;
                    const row = layout.row(offset);
                    _ = rl.GuiLabel(row.translate(12, 0).resize(134, 26).into(), fname.ptr);
                    _ = rl.GuiSlider(row.resize(110, 22).translate(150, 2).into(), "", "", fval, frange[0], frange[1]);

                    const buf = if (editState == field_index)
                        &editing_buffer
                    else
                        std.fmt.bufPrintZ(&value_buffer, tunable_fmt, .{fval.*}) catch unreachable;

                    if (rl.GuiValueBoxFloat(row.resize(64, 26).translate(270, 0).into(), "", buf.ptr, fval, editState == field_index) != 0) {
                        editState = if (editState == field_index) null else field_index;
                        @memset(&value_buffer, 0);
                        _ = std.fmt.bufPrintZ(&value_buffer, "{d}", .{fval.*}) catch unreachable;
                        @memcpy(&editing_buffer, &value_buffer);
                    }
                    controls.constrainScalar(optinfo);
                    field_index += 1;
                }
                layout.advance(16);
            }
        }
        const ShapeFields = [_]struct { []const u8, []const controls.Scalar }{
            .{ "Waveform lines", &config.Visualizer.WaveFormLine.Scalars },
            .{ "Waveform bars", &config.Visualizer.WaveFormBar.Scalars },
            .{ "3D bubble", &config.Visualizer.Bubble.Scalars },
            .{ "Screen effects", &config.Shader.Scalars },
        };
        const MotionFields = [_]struct { []const u8, []const controls.Scalar }{
            .{ "Window", &config.Window.Scalars },
            .{ "Energy motion", &config.Motion.Scalars },
            .{ "Audio response", &config.Audio.Scalars },
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
            const anchor = beginPanel("Scene elements", 280);
            defer endPanel();
            var layout = PanelLayout.init(anchor, 16);
            _ = rl.GuiLabel(layout.row(40).translate(12, 0).into(), "Choose what appears in your scene.");
            inline for (items) |item| {
                const row = layout.row(42);
                _ = rl.GuiCheckBox(row.resize(24, 24).translate(18, 0).into(), item[0], item[1]);
            }
        }
    };
    const Colors = struct {
        const slider_w = 214;
        const offset = 40;
        fn draw() void {
            const anchor = beginPanel("Colors - drag a hue strip", 540);
            defer endPanel();
            var layout = PanelLayout.init(anchor, 12);
            inline for (Fields) |info| {
                const name, const cfg = info;
                _ = rl.GuiLabel(layout.row(32).translate(12, 0).resize(310, 24).into(), name.ptr);
                layout.advance(16);
                inline for (cfg) |optinfo| {
                    const fname, const fval = optinfo;
                    const row = layout.row(offset);
                    const label = if (std.mem.eql(u8, fname, "color1")) "Primary" else if (std.mem.eql(u8, fname, "color2")) "Secondary" else if (std.mem.eql(u8, fname, "color3")) "Trail" else "Hue";
                    _ = rl.GuiLabel(row.translate(12, 0).resize(88, 24).into(), label);
                    _ = rl.GuiColorBarHueH(row.resize(slider_w, 24).translate(112, 0).into(), "", fval);
                }
            }
        }
        const Fields = [_]struct { []const u8, []const controls.Color }{
            .{ "Waveform lines", &config.Visualizer.WaveFormLine.Colors },
            .{ "Waveform bars", &config.Visualizer.WaveFormBar.Colors },
            .{ "3D bubble", &config.Visualizer.Bubble.Colors },
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
