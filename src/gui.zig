const std = @import("std");
const builtin = @import("builtin");
const AudioSession = @import("audio/Session.zig");
const config = @import("core/config.zig");
const Direction = @import("core/event.zig").Direction;
const controls = @import("gui/controls.zig");
const ui = @import("gui/theme.zig");
const rl = @import("raylib");
const WaveformCache = @import("gui/WaveformCache.zig");
var waveform_cache: WaveformCache = .{};

pub fn deinit() void {
    waveform_cache.deinit();
}

const Element = @import("graphics/Highlight.zig").Element;

pub const Tab = enum(c_int) { none, scalar, color, motion, scene };
var active_tab: Tab = .scalar;
var scroll: f32 = 0;
var saved_scroll: [5]f32 = @splat(0);
var active_slider: ?usize = null;
var editing: ?usize = null;
var editing_buffer: [128]u8 = @splat(0);
var dragging_seek = false;
const seek_id = 1000;

pub fn onTabChange(next: Tab) void {
    if (active_tab == next) return;
    editing = null;
    active_slider = null;
    saved_scroll[@intCast(@intFromEnum(active_tab))] = scroll;
    active_tab = next;
    scroll = saved_scroll[@intCast(@intFromEnum(next))];
}

pub fn editingValue() bool {
    return editing != null;
}

fn width() f32 {
    return @floatFromInt(rl.GetScreenWidth());
}
fn height() f32 {
    return @floatFromInt(rl.GetScreenHeight());
}
fn panel() rl.Rectangle {
    return ui.rect(16, 88, if (width() < 800) 280 else 320, @max(180, height() - 268));
}
fn viewport() rl.Rectangle {
    const p = panel();
    return ui.rect(p.x + 12, p.y + 72, p.width - 24, p.height - 108);
}

/// UI wheel gestures must not also move the scene camera.
pub fn pointerOverUi() bool {
    return @import("core/debug.zig").pointerOverUi() or
        ui.hovered(ui.rect(16, 16, width() - 32, 58)) or
        ui.hovered(ui.rect(16, height() - 164, width() - 32, 148)) or
        (active_tab != .none and ui.hovered(panel()));
}

pub fn frame(audio: *AudioSession) void {
    rl.SetMouseCursor(rl.MOUSE_CURSOR_DEFAULT);
    if (!rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
        if (dragging_seek) audio.endSeek();
        dragging_seek = false;
        active_slider = null;
    }
    if (dragging_seek and (!audio.seeking or active_slider != seek_id or audio.captureActive() or !audio.hasFile())) {
        audio.endSeek();
        dragging_seek = false;
        if (active_slider == seek_id) active_slider = null;
    }
    drawHeader();
    if (active_tab != .none) drawPanel();
    drawPlayer(audio);
    if (!audio.hasFile() and !audio.captureActive() and width() >= 840) {
        const left = if (active_tab == .none) 16 else panel().x + panel().width + 24;
        ui.centered("Drop an audio file to bring the scene to life", ui.rect(left, height() - 182, width() - left - 16, 24), 15, ui.muted);
    }
}

fn drawHeader() void {
    ui.card(ui.rect(16, 16, width() - 32, 58));
    inline for (.{ 10, 22, 30, 17, 8 }, 0..) |h, i| {
        ui.rounded(ui.rect(32 + @as(f32, @floatFromInt(i)) * 5, 45 - @as(f32, h) / 2, 3, h), 1.5, ui.accent);
    }
    ui.label("zigscene", 68, 26, 22, ui.text);
    ui.label("AUDIO / VISUAL", 69, 51, 9, ui.muted);
    const tabs = .{ .{ "Shape", Tab.scalar }, .{ "Color", Tab.color }, .{ "Motion", Tab.motion }, .{ "Scene", Tab.scene } };
    const tab_w: f32 = if (width() < 800) 72 else 88;
    inline for (tabs, 0..) |tab, i| {
        const bounds = ui.rect(190 + @as(f32, @floatFromInt(i)) * tab_w, 27, tab_w - 6, 36);
        if (ui.button(bounds, tab[0], active_tab == tab[1], true)) onTabChange(tab[1]);
    }
    if (ui.button(ui.rect(width() - 110, 27, 78, 36), if (active_tab == .none) "Settings" else "Hide  /  1", false, true)) {
        onTabChange(if (active_tab == .none) .scalar else .none);
    }
}

fn contentHeight(tab: Tab) f32 {
    return switch (tab) {
        .scalar => scalarHeight(ShapeFields),
        .motion => scalarHeight(MotionFields),
        .color => colorHeight(),
        .scene => 48 + SceneItems.len * 76,
        .none => 0,
    };
}

/// Resolve against current logical UI coordinates before the scene is drawn.
pub fn hoveredElement() ?Element {
    const view = viewport();
    const offset = std.math.clamp(scroll, 0, @max(0, contentHeight(active_tab) - view.height));
    const dragging = if (rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) active_slider else null;
    if (dragging == null and !rl.IsCursorOnScreen()) return null;
    return elementAt(active_tab, view, offset, rl.GetMousePosition(), dragging);
}

fn elementAt(tab: Tab, view: rl.Rectangle, offset: f32, mouse: rl.Vector2, dragging: ?usize) ?Element {
    return switch (tab) {
        .scalar => groupElementAt(ShapeFields, view, offset, mouse, dragging, 0),
        .motion => groupElementAt(MotionFields, view, offset, mouse, dragging, 0),
        .color => groupElementAt(ColorFields, view, offset, mouse, dragging, 100),
        .scene => blk: {
            if (!rl.CheckCollisionPointRec(mouse, view)) break :blk null;
            var y = view.y - offset + 48;
            inline for (SceneItems) |item| {
                if (rl.CheckCollisionPointRec(mouse, ui.rect(view.x, y, view.width, 66))) break :blk item[3];
                y += 76;
            }
            break :blk null;
        },
        .none => null,
    };
}

fn groupElementAt(comptime groups: anytype, view: rl.Rectangle, offset: f32, mouse: rl.Vector2, dragging: ?usize, first_id: usize) ?Element {
    // Drag ownership takes priority even if the pointer leaves the panel.
    if (dragging) |slider_id| {
        var id = first_id;
        inline for (groups) |group| {
            if (slider_id >= id and slider_id < id + group[1].len) return group[2];
            id += group[1].len;
        }
        return null;
    }
    if (!rl.CheckCollisionPointRec(mouse, view)) return null;
    var y = view.y - offset;
    inline for (groups) |group| {
        const group_height: f32 = 38 + group[1].len * 52;
        if (rl.CheckCollisionPointRec(mouse, ui.rect(view.x, y, view.width, group_height))) return group[2];
        y += group_height;
    }
    return null;
}

fn drawPanel() void {
    const p = panel();
    ui.card(p);
    const title: [:0]const u8, const subtitle: [:0]const u8 = switch (active_tab) {
        .scalar => .{ "Shape & texture", "Fine-tune the form of your sound." },
        .color => .{ "Color palette", "Find a hue for every layer." },
        .motion => .{ "Motion & response", "Give every beat its own character." },
        .scene => .{ "Scene layers", "Compose your own visual mix." },
        .none => unreachable,
    };
    ui.label(title, p.x + 20, p.y + 16, 21, ui.text);
    ui.label(subtitle, p.x + 20, p.y + 44, 13, ui.muted);
    const view = viewport();
    const content_h = contentHeight(active_tab);
    const max_scroll = @max(0, content_h - view.height);
    scroll = std.math.clamp(scroll, 0, max_scroll);
    // The scrollbar is draggable as well as wheel-controlled.
    const track = ui.rect(p.x + p.width - 12, view.y, 12, view.height);
    if (max_scroll > 0 and ui.hovered(track) and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
        active_slider = 2000;
        editing = null;
    }
    if (max_scroll > 0 and active_slider == 2000) {
        const thumb_h = @max(24, view.height * view.height / content_h);
        scroll = std.math.clamp((rl.GetMousePosition().y - view.y - thumb_h / 2) / (view.height - thumb_h), 0, 1) * max_scroll;
    }
    rl.BeginScissorMode(@intFromFloat(view.x), @intFromFloat(view.y), @intFromFloat(view.width), @intFromFloat(view.height));
    switch (active_tab) {
        .scalar => drawScalars(ShapeFields, view),
        .motion => drawScalars(MotionFields, view),
        .color => drawColors(view),
        .scene => drawScene(view),
        .none => unreachable,
    }
    rl.EndScissorMode();
    if (max_scroll > 0) {
        const thumb_h = @max(24, view.height * view.height / content_h);
        ui.rounded(ui.rect(p.x + p.width - 7, view.y, 3, view.height), 1.5, ui.raised);
        ui.rounded(ui.rect(p.x + p.width - 7, view.y + (view.height - thumb_h) * scroll / max_scroll, 3, thumb_h), 1.5, ui.muted);
    }
    ui.label(if (max_scroll > 0) "SCROLL TO EXPLORE" else "MAKE IT YOUR OWN", p.x + 20, p.y + p.height - 22, 10, ui.muted);
    ui.label("2 - 5", p.x + p.width - 50, p.y + p.height - 22, 10, ui.muted);
}

const ScalarGroup = struct { [:0]const u8, []const controls.Scalar, ?Element };
const ShapeFields = [_]ScalarGroup{
    .{ "WAVEFORM / LINES", &config.Visualizer.WaveFormLine.Scalars, .wave_lines },
    .{ "WAVEFORM / BARS", &config.Visualizer.WaveFormBar.Scalars, .wave_bars },
    .{ "3D BUBBLE", &config.Visualizer.Bubble.Scalars, .bubble },
    .{ "TEXTURE & BACKGROUND", &config.Shader.Scalars, null },
};
const MotionFields = [_]ScalarGroup{
    .{ "WINDOW", &config.Window.Scalars, null },
    .{ "ENERGY & ENVELOPE", &config.Motion.Scalars, null },
    .{ "AUDIO RESPONSE", &config.Audio.Scalars, null },
    .{ "SPECTRUM", &config.Visualizer.Spectrum.Scalars, .spectrum },
    .{ "FREQUENCY HALO", &config.Visualizer.Halo.Scalars, .halo },
};
fn scalarHeight(comptime groups: anytype) f32 {
    comptime var total: f32 = 0;
    inline for (groups) |group| total += 38 + group[1].len * 52;
    return total;
}
fn groupHeading(name: [:0]const u8, view: rl.Rectangle, y: f32) void {
    ui.label(name, view.x + 8, y + 8, 11, ui.accent);
    rl.DrawLineEx(.{ .x = view.x + 8, .y = y + 29 }, .{ .x = view.x + view.width - 8, .y = y + 29 }, 1, ui.border);
}
fn rowVisible(y: f32, view: rl.Rectangle) bool {
    return y >= view.y and y + 46 <= view.y + view.height;
}

fn drawScalars(comptime groups: anytype, view: rl.Rectangle) void {
    var y = view.y - scroll;
    var id: usize = 0;
    inline for (groups) |group| {
        groupHeading(group[0], view, y);
        y += 38;
        inline for (group[1]) |scalar| {
            const name, const value, const range = scalar;
            const row_enabled = rowVisible(y, view);
            if (!row_enabled and editing == id) editing = null;
            var name_buffer: [64]u8 = undefined;
            const label = std.fmt.bufPrintZ(&name_buffer, "{s}", .{name}) catch unreachable;
            ui.label(label, view.x + 8, y + 4, 14, ui.text);
            const box = ui.rect(view.x + view.width - 76, y, 68, 24);
            if (editing == id) {
                if (rl.GuiValueBoxFloat(box, null, &editing_buffer, value, true) != 0 or
                    (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT) and !ui.hovered(box))) editing = null;
            } else {
                var buf: [32]u8 = undefined;
                const number = if (range[1] <= 2)
                    std.fmt.bufPrintZ(&buf, "{d:.3}", .{value.*}) catch unreachable
                else
                    std.fmt.bufPrintZ(&buf, "{d:.1}", .{value.*}) catch unreachable;
                ui.rounded(box, 5, ui.raised);
                ui.centered(number, box, 12, ui.muted);
                if (row_enabled and ui.hovered(box)) {
                    rl.SetMouseCursor(rl.MOUSE_CURSOR_IBEAM);
                    if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
                        editing = id;
                        @memset(&editing_buffer, 0);
                        _ = std.fmt.bufPrintZ(&editing_buffer, "{d:.3}", .{value.*}) catch unreachable;
                    }
                }
            }
            _ = slider(id, ui.rect(view.x + 8, y + 27, view.width - 16, 18), value, range[0], range[1], row_enabled, false);
            controls.constrainScalar(scalar);
            y += 52;
            id += 1;
        }
    }
}

/// A generous hit area around a slim track; drag ownership survives leaving it.
fn slider(id: usize, bounds: rl.Rectangle, value: *f32, min: f32, max: f32, enabled: bool, hue: bool) bool {
    const over = enabled and ui.hovered(bounds);
    if (over and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT) and active_slider == null) {
        active_slider = id;
        editing = null;
    }
    const dragging = active_slider == id;
    if (dragging and rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
        value.* = min + std.math.clamp((rl.GetMousePosition().x - bounds.x) / bounds.width, 0, 1) * (max - min);
    }
    if (over or dragging) rl.SetMouseCursor(rl.MOUSE_CURSOR_POINTING_HAND);
    const ratio = if (max > min) std.math.clamp((value.* - min) / (max - min), 0, 1) else 0;
    const cy = bounds.y + bounds.height / 2;
    ui.rounded(ui.rect(bounds.x, cy - 2, bounds.width, 4), 2, ui.border);
    if (hue) {
        for (0..6) |i| {
            const x = bounds.x + @as(f32, @floatFromInt(i)) * bounds.width / 6;
            const a = rl.ColorFromHSV(@as(f32, @floatFromInt(i)) * 60, 0.65, 0.9);
            const b = rl.ColorFromHSV(@as(f32, @floatFromInt(i + 1)) * 60, 0.65, 0.9);
            rl.DrawRectangleGradientEx(ui.rect(x, cy - 3, bounds.width / 6 + 1, 6), a, a, b, b);
        }
    } else if (ratio > 0) ui.rounded(ui.rect(bounds.x, cy - 2, @max(4, bounds.width * ratio), 4), 2, ui.accent);
    const center = rl.Vector2{ .x = bounds.x + ratio * bounds.width, .y = cy };
    if (over or dragging) rl.DrawCircleV(center, 10, rl.Fade(ui.accent, 0.15));
    rl.DrawCircleV(center, if (over or dragging) 6 else 4, ui.text);
    return dragging;
}

const ColorFields = .{
    .{ "WAVEFORM / LINES", &config.Visualizer.WaveFormLine.Colors, Element.wave_lines },
    .{ "WAVEFORM / BARS", &config.Visualizer.WaveFormBar.Colors, Element.wave_bars },
    .{ "3D BUBBLE", &config.Visualizer.Bubble.Colors, Element.bubble },
    .{ "FREQUENCY HALO", &config.Visualizer.Halo.Colors, Element.halo },
};
fn colorHeight() f32 {
    comptime var total: f32 = 0;
    inline for (ColorFields) |group| total += 38 + group[1].len * 52;
    return total;
}
fn drawColors(view: rl.Rectangle) void {
    var y = view.y - scroll;
    var id: usize = 100;
    inline for (ColorFields) |group| {
        groupHeading(group[0], view, y);
        y += 38;
        inline for (group[1], 0..) |color, index| {
            const value = color[1];
            rl.DrawCircleV(.{ .x = view.x + 14, .y = y + 10 }, 6, rl.ColorFromHSV(value.*, 0.7, 1));
            ui.label(if (group[1].len == 1) "Hue" else if (index == 0) "Primary" else if (index == 1) "Secondary" else "Trail", view.x + 28, y + 2, 14, ui.text);
            var buf: [32]u8 = undefined;
            const number = std.fmt.bufPrintZ(&buf, "{d:.0} deg", .{value.*}) catch unreachable;
            ui.label(number, view.x + view.width - 62, y + 3, 12, ui.muted);
            _ = slider(id, ui.rect(view.x + 8, y + 27, view.width - 16, 18), value, 0, 359, rowVisible(y, view), true);
            y += 52;
            id += 1;
        }
    }
}

const SceneItems = .{
    .{ "Waveform lines", "The outline of your audio", &config.Scene.wave_lines, Element.wave_lines },
    .{ "Waveform bars", "Rhythm with a trailing glow", &config.Scene.wave_bars, Element.wave_bars },
    .{ "Spectrum", "Sound across the frequencies", &config.Scene.spectrum, Element.spectrum },
    .{ "3D bubble", "A sculptural, reactive core", &config.Scene.bubble, Element.bubble },
    .{ "Frequency halo", "A ring of spectral energy", &config.Scene.halo, Element.halo },
};

fn drawScene(view: rl.Rectangle) void {
    var y = view.y - scroll;
    const actions_enabled = y >= view.y and y + 36 <= view.y + view.height;
    if (ui.button(ui.rect(view.x, y, (view.width - 8) / 2, 34), "Show all", false, actions_enabled)) {
        inline for (SceneItems) |item| item[2].* = true;
    }
    if (ui.button(ui.rect(view.x + (view.width + 8) / 2, y, (view.width - 8) / 2, 34), "Hide all", false, actions_enabled)) {
        inline for (SceneItems) |item| item[2].* = false;
    }
    y += 48;
    inline for (SceneItems) |item| {
        const bounds = ui.rect(view.x, y, view.width, 66);
        const over = rowVisible(y, view) and ui.hovered(bounds) and ui.hovered(view);
        ui.rounded(bounds, 8, if (over) ui.raised else ui.background);
        ui.label(item[0], view.x + 12, y + 12, 15, if (item[2].*) ui.text else ui.muted);
        ui.label(item[1], view.x + 12, y + 36, 11, ui.muted);
        const toggle = ui.rect(view.x + view.width - 48, y + 15, 36, 20);
        ui.rounded(toggle, 10, if (item[2].*) ui.accent_soft else ui.border);
        rl.DrawCircleV(.{ .x = toggle.x + (if (item[2].*) @as(f32, 26) else 10), .y = toggle.y + 10 }, 6, if (item[2].*) ui.accent else ui.muted);
        if (over) {
            rl.SetMouseCursor(rl.MOUSE_CURSOR_POINTING_HAND);
            if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) item[2].* = !item[2].*;
        }
        y += 76;
    }
}

pub fn onSwipe(dir: Direction, amount: f32) void {
    applyScroll(dir, amount, active_tab != .none and ui.hovered(panel()));
}

fn applyScroll(dir: Direction, amount: f32, pointer_over_panel: bool) void {
    if (dir == .vertical and amount != 0 and pointer_over_panel and active_slider == null) {
        editing = null;
        scroll -= amount * 28;
    }
}

fn drawPlayer(audio: *AudioSession) void {
    const dock = ui.rect(16, height() - 164, width() - 32, 148);
    ui.card(dock);
    const live = audio.captureActive();
    const file = audio.hasFile() and !live;
    const text_x: f32 = 32;
    var title_buffer: [512]u8 = undefined;
    const title = if (live) (if (audio.captureMode() == .system) "LIVE INPUT  /  System audio" else "LIVE INPUT  /  Input audio") else if (file) std.fmt.bufPrintZ(&title_buffer, "{s}  /  {s}", .{ if (audio.seeking) "SEEKING" else if (audio.isFilePlaying()) "PLAYING" else "PAUSED", audio.filename() }) catch "Audio file" else "Your sound. Your scene.";
    rl.BeginScissorMode(@intFromFloat(text_x), @intFromFloat(dock.y + 10), @intFromFloat(dock.width - (if (audio.notice != null) @as(f32, 112) else if (file) @as(f32, 188) else 32)), 24);
    if (audio.notice) |notice| {
        ui.label(notice, text_x, dock.y + 12, 14, rl.GetColor(0xffd28aff));
    } else ui.label(title, text_x, dock.y + 12, 15, ui.text);
    rl.EndScissorMode();
    if (audio.notice != null and ui.button(ui.rect(width() - 108, dock.y + 8, 76, 26), "Dismiss", false, true)) audio.notice = null;

    if (file and audio.notice == null) {
        for ([_][:0]const u8{ "Low", "Mid", "High" }, WaveformCache.colors, 0..) |label, color, index| {
            const x = dock.x + dock.width - 166 + @as(f32, @floatFromInt(index)) * 52;
            rl.DrawCircleV(.{ .x = x, .y = dock.y + 20 }, 3, color);
            ui.label(label, x + 8, dock.y + 14, 12, color);
        }
    }
    const play = ui.rect(30, dock.y + 38, 104, 30);
    ui.rounded(play, 7, if (file) ui.accent_soft else ui.raised);
    const ink = if (file) ui.accent else ui.muted;
    if (audio.isFilePlaying()) {
        ui.rounded(ui.rect(play.x + 11, play.y + 9, 3, 12), 1, ink);
        ui.rounded(ui.rect(play.x + 17, play.y + 9, 3, 12), 1, ink);
    } else {
        rl.DrawTriangle(.{ .x = play.x + 11, .y = play.y + 8 }, .{ .x = play.x + 11, .y = play.y + 22 }, .{ .x = play.x + 22, .y = play.y + 15 }, ink);
    }
    ui.label(if (audio.isFilePlaying()) "Pause / P" else "Play / P", play.x + 30, play.y + 8, 13, ink);
    if (file and ui.hovered(play)) {
        rl.SetMouseCursor(rl.MOUSE_CURSOR_POINTING_HAND);
        if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) audio.togglePlayback();
    }
    const capture_supported = builtin.os.tag != .emscripten;
    if (ui.button(ui.rect(146, dock.y + 38, 170, 30), if (live) "Stop capture  /  M" else if (capture_supported) "Capture audio  /  M" else "Live unavailable", live, capture_supported)) audio.toggleSystemCapture();
    ui.label("Volume", width() - 280, dock.y + 46, 13, ui.muted);
    _ = slider(1001, ui.rect(width() - 222, dock.y + 44, 132, 18), &config.Audio.volume, 0, 1, true, false);
    var volume_buffer: [16]u8 = undefined;
    const volume = std.fmt.bufPrintZ(&volume_buffer, "{d}%", .{@as(u32, @intFromFloat(config.Audio.volume * 100))}) catch unreachable;
    ui.label(volume, width() - 74, dock.y + 46, 13, ui.text);
    if (file) {
        drawWaveformScrubber(audio, ui.rect(30, dock.y + 78, width() - 60, 56));
    } else {
        ui.rounded(ui.rect(30, dock.y + 80, width() - 60, 54), 6, ui.background);
        rl.DrawCircleV(.{ .x = 44, .y = dock.y + 107 }, 3, if (live) ui.accent else ui.muted);
        ui.label(if (live) "Listening live. Drop a file to switch to playback." else "Drop an audio file anywhere to start listening.", 56, dock.y + 100, 13, if (live) ui.accent else ui.muted);
    }
}

fn drawWaveformScrubber(audio: *AudioSession, bounds: rl.Rectangle) void {
    const duration = audio.timeLength();
    const mouse = rl.GetMousePosition();
    const hovering = ui.hovered(bounds) and duration > 0;
    if (hovering and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT) and active_slider == null) {
        active_slider = seek_id;
        dragging_seek = true;
        editing = null;
        audio.beginSeek();
    }
    if (dragging_seek and rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
        audio.seekTo(duration * std.math.clamp((mouse.x - bounds.x) / bounds.width, 0, 1));
    }
    if (hovering or dragging_seek) rl.SetMouseCursor(rl.MOUSE_CURSOR_POINTING_HAND);
    ui.rounded(bounds, 6, ui.background);
    const waveform = audio.waveform();
    const played = std.math.clamp(audio.timePlayed() / @max(duration, 0.001), 0, 1);
    waveform_cache.draw(waveform, bounds, played);
    if (waveform.len == 0) {
        const center_y = bounds.y + bounds.height / 2;
        rl.DrawLineEx(.{ .x = bounds.x, .y = center_y }, .{ .x = bounds.x + bounds.width, .y = center_y }, 1, ui.border);
    }
    const playhead_x = bounds.x + bounds.width * played;
    rl.DrawLineEx(.{ .x = playhead_x, .y = bounds.y + 2 }, .{ .x = playhead_x, .y = bounds.y + bounds.height - 2 }, 1, ui.text);

    const elapsed: u32 = @intFromFloat(@max(0, audio.timePlayed()));
    const total: u32 = @intFromFloat(@max(0, duration));
    var timer_buffer: [48]u8 = undefined;
    const timer = std.fmt.bufPrintZ(&timer_buffer, "{d}:{d:0>2} / {d}:{d:0>2}", .{ elapsed / 60, elapsed % 60, total / 60, total % 60 }) catch unreachable;
    const timer_width = ui.textWidth(timer, 12) + 16;
    const timer_bounds = ui.rect(bounds.x + bounds.width - timer_width - 4, bounds.y + 4, timer_width, 22);
    ui.rounded(timer_bounds, 4, ui.surface);
    ui.centered(timer, timer_bounds, 12, ui.text);
    if (hovering) {
        const seconds: u32 = @intFromFloat(duration * std.math.clamp((mouse.x - bounds.x) / bounds.width, 0, 1));
        var preview_buffer: [48]u8 = undefined;
        const preview = std.fmt.bufPrintZ(&preview_buffer, "Seek to {d}:{d:0>2}", .{ seconds / 60, seconds % 60 }) catch unreachable;
        const preview_width = ui.textWidth(preview, 12) + 20;
        const preview_x = std.math.clamp(mouse.x - preview_width / 2, bounds.x, bounds.x + bounds.width - preview_width);
        rl.DrawLineEx(.{ .x = mouse.x, .y = bounds.y }, .{ .x = mouse.x, .y = bounds.y + bounds.height }, 1, ui.accent);
        const preview_bounds = ui.rect(preview_x, bounds.y - 26, preview_width, 24);
        ui.rounded(preview_bounds, 5, ui.accent_soft);
        ui.centered(preview, preview_bounds, 12, ui.accent);
    }
}

test "idle wheel input preserves numeric editing and only panel scrolling consumes it" {
    const original_scroll = scroll;
    const original_editing = editing;
    const original_slider = active_slider;
    defer {
        scroll = original_scroll;
        editing = original_editing;
        active_slider = original_slider;
    }
    scroll = 80;
    editing = 2;
    active_slider = null;
    applyScroll(.vertical, 0, true);
    try std.testing.expectEqual(@as(?usize, 2), editing);
    applyScroll(.vertical, 1, false);
    applyScroll(.horizontal, 1, true);
    try std.testing.expectEqual(@as(f32, 80), scroll);
    try std.testing.expectEqual(@as(?usize, 2), editing);
    active_slider = 2;
    applyScroll(.vertical, 1, true);
    try std.testing.expectEqual(@as(f32, 80), scroll);
    active_slider = null;
    applyScroll(.vertical, 1, true);
    try std.testing.expectEqual(@as(f32, 52), scroll);
    try std.testing.expectEqual(@as(?usize, null), editing);
}

test "tab navigation restores scroll position and releases field editing" {
    const original_tab = active_tab;
    const original_scroll = scroll;
    const original_saved = saved_scroll;
    const original_editing = editing;
    const original_slider = active_slider;
    defer {
        active_tab = original_tab;
        scroll = original_scroll;
        saved_scroll = original_saved;
        editing = original_editing;
        active_slider = original_slider;
    }
    active_tab = .scalar;
    saved_scroll = @splat(0);
    scroll = 120;
    editing = 3;
    active_slider = 4;
    onTabChange(.motion);
    try std.testing.expectEqual(@as(f32, 0), scroll);
    try std.testing.expectEqual(@as(?usize, null), editing);
    try std.testing.expectEqual(@as(?usize, null), active_slider);
    scroll = 48;
    onTabChange(.scalar);
    try std.testing.expectEqual(@as(f32, 120), scroll);
    onTabChange(.motion);
    try std.testing.expectEqual(@as(f32, 48), scroll);
}

test "hover selects the current scrolled group without leaking through clipped UI" {
    const view = ui.rect(10, 100, 300, 300);
    try std.testing.expectEqual(@as(?Element, .wave_lines), elementAt(.scalar, view, 0, .{ .x = 30, .y = 110 }, null));
    try std.testing.expectEqual(@as(?Element, .wave_bars), elementAt(.scalar, view, 0, .{ .x = 30, .y = 220 }, null));
    try std.testing.expectEqual(@as(?Element, .bubble), elementAt(.scalar, view, 284, .{ .x = 30, .y = 110 }, null));
    try std.testing.expectEqual(@as(?Element, .halo), elementAt(.color, view, 478, .{ .x = 30, .y = 110 }, null));
    try std.testing.expectEqual(@as(?Element, .spectrum), elementAt(.motion, view, 634, .{ .x = 30, .y = 110 }, null));
    try std.testing.expectEqual(@as(?Element, null), elementAt(.motion, view, 0, .{ .x = 30, .y = 110 }, null));
    try std.testing.expectEqual(@as(?Element, null), elementAt(.scalar, view, 634, .{ .x = 30, .y = 110 }, null));
    try std.testing.expectEqual(@as(?Element, null), elementAt(.scalar, view, 0, .{ .x = 30, .y = 90 }, null));
    try std.testing.expectEqual(@as(?Element, null), elementAt(.scalar, view, 0, .{ .x = 30, .y = 410 }, null));
    try std.testing.expectEqual(@as(?Element, null), elementAt(.scalar, view, 0, .{ .x = 400, .y = 110 }, null));
}

test "scene hover excludes bulk actions and drag focus follows its owner" {
    const view = ui.rect(10, 100, 300, 300);
    try std.testing.expectEqual(@as(?Element, null), elementAt(.scene, view, 0, .{ .x = 30, .y = 120 }, null));
    try std.testing.expectEqual(@as(?Element, .wave_lines), elementAt(.scene, view, 0, .{ .x = 30, .y = 160 }, null));
    try std.testing.expectEqual(@as(?Element, null), elementAt(.scene, view, 0, .{ .x = 30, .y = 218 }, null));
    try std.testing.expectEqual(@as(?Element, .wave_bars), elementAt(.scene, view, 0, .{ .x = 30, .y = 230 }, null));
    try std.testing.expectEqual(@as(?Element, .wave_lines), elementAt(.scalar, view, 0, .{ .x = 900, .y = 600 }, 0));
    try std.testing.expectEqual(@as(?Element, .wave_lines), elementAt(.color, view, 0, .{ .x = 900, .y = 600 }, 100));
    try std.testing.expectEqual(@as(?Element, null), elementAt(.scalar, view, 0, .{ .x = 30, .y = 110 }, 1001));
    try std.testing.expectEqual(@as(?Element, null), elementAt(.none, view, 0, .{ .x = 30, .y = 110 }, 0));
}
