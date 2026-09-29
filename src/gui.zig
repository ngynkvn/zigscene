const std = @import("std");
const builtin = @import("builtin");
const AudioSession = @import("audio/Session.zig");
const config = @import("core/config.zig");
const Direction = @import("core/event.zig").Direction;
const geometry = @import("gui/geometry.zig");
const State = @import("editor/State.zig");
const StudioPanel = @import("gui/StudioPanel.zig");
var current_script: ?*ScriptScene = null;
const controls = @import("gui/controls.zig");
const ui = @import("gui/theme.zig");
const rl = @import("raylib");
const WaveformCache = @import("gui/WaveformCache.zig");
const ScriptScene = @import("scripting/Scene.zig");
const ScriptPanel = @import("gui/ScriptPanel.zig");
var scene_prefix: f32 = 0;
var scene_revision: ?u64 = null;
var waveform_cache: WaveformCache = .{};
var audio_content_height: f32 = 210;

pub fn deinit() void {
    waveform_cache.deinit();
}

const Element = @import("graphics/Highlight.zig").Element;

pub const Tab = enum(c_int) { none, scalar, color, motion, scene, settings, audio, presets, inspector };
var active_tab: Tab = .scalar;
var scroll: f32 = 0;
var saved_scroll: [9]f32 = @splat(0);
var active_slider: ?usize = null;
var editing: ?usize = null;
var editing_buffer: [128]u8 = @splat(0);
var dragging_seek = false;
var settings_reset_requested = false;
const seek_id = 1000;
const resize_id = 3000;
const ResizeMode = enum { none, width, height, both };
var resize_mode: ResizeMode = .none;
var resize_origin: rl.Vector2 = .{};
var resize_size: geometry.Size = .{ .width = 320, .height = 500 };

/// Apply the reset between frames, before any controls or scripts run again.
pub fn takeSettingsReset() bool {
    const requested = settings_reset_requested;
    settings_reset_requested = false;
    return requested;
}

pub fn resetWorkspace() void {
    editing = null;
    active_slider = null;
    dragging_seek = false;
    resize_mode = .none;
    scroll = 0;
    saved_scroll = @splat(0);
    scene_revision = null;
    @import("graphics/Highlight.zig").solo = null;
    StudioPanel.resetWorkspace();
}

pub fn onTabChange(next: Tab) void {
    if (active_tab == next) return;
    editing = null;
    StudioPanel.text_editing = false;
    active_slider = null;
    resize_mode = .none;
    saved_scroll[@intCast(@intFromEnum(active_tab))] = scroll;
    active_tab = next;
    scroll = saved_scroll[@intCast(@intFromEnum(next))];
}

pub fn editingValue() bool {
    return editing != null or StudioPanel.text_editing;
}

fn width() f32 {
    return ui.width();
}
fn height() f32 {
    return ui.height();
}
fn panel() rl.Rectangle {
    const size = geometry.panelSize(config.Interface.panel_width, config.Interface.panel_height, width(), height());
    return ui.rect(geometry.margin, geometry.panel_top, size.width, size.height);
}
fn viewport() rl.Rectangle {
    const p = panel();
    return ui.rect(p.x + 12, p.y + 60, p.width - 24, p.height - 84);
}

/// UI wheel gestures must not also move the scene camera.
pub fn pointerOverUi() bool {
    return resize_mode != .none or @import("core/debug.zig").pointerOverUi() or
        ui.hovered(headerBounds()) or
        ui.hovered(if (config.Interface.show_player) dockBounds() else expandPlayerBounds()) or
        (active_tab != .none and ui.hovered(ui.rect(panel().x, panel().y, panel().width + 6, panel().height + 6)));
}

pub fn prepareScene(script: *ScriptScene) void {
    if (scene_revision != script.revision) {
        @import("graphics/Highlight.zig").solo = null;
        scene_revision = script.revision;
    }
    scene_prefix = ScriptPanel.height(script, viewport().width);
}

pub fn frame(audio: *AudioSession, script: *ScriptScene) void {
    current_script = script;
    State.history.sync(script);
    defer {
        if (!rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT) and !editingValue()) State.history.record(script);
    }
    if (active_tab == .audio and !audio.capture_devices_loaded) audio.refreshCaptureDevices();
    audio_content_height = 210 + @as(f32, @floatFromInt(audio.capture_devices.count)) * 38;
    if (!rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
        if (dragging_seek) audio.endSeek();
        dragging_seek = false;
        active_slider = null;
        resize_mode = .none;
    }
    if (dragging_seek and (!config.Interface.show_player or !audio.seeking or active_slider != seek_id or audio.captureActive() or !audio.hasFile())) {
        audio.endSeek();
        dragging_seek = false;
        if (active_slider == seek_id) active_slider = null;
    }
    if (!config.Interface.show_player and active_slider == 1001) active_slider = null;
    resizePanel();
    drawHeader();
    if (active_tab != .none) drawPanel(script, audio);
    drawPlayer(audio);
    if (config.Interface.show_player and !audio.hasFile() and !audio.captureActive() and width() >= 840) {
        const left = if (active_tab == .none) 16 else panel().x + panel().width + 24;
        ui.centered("Drop an audio file to bring the scene to life", ui.rect(left, dockBounds().y - 30, width() - left - 16, 24), 15, ui.muted);
    }
}

fn headerBounds() rl.Rectangle {
    return ui.rect(geometry.margin, geometry.margin, width() - 2 * geometry.margin, geometry.header_height);
}

fn drawHeader() void {
    ui.card(headerBounds());
    inline for (.{ 10, 22, 30, 17, 8 }, 0..) |h, i| {
        ui.rounded(ui.rect(32 + @as(f32, @floatFromInt(i)) * 5, 36 - @as(f32, h) / 2, 3, h), 1.5, ui.accent);
    }
    if (width() >= 900) {
        ui.label("zigscene", 68, 18, 21, ui.text);
        ui.label("AUDIO / VISUAL", 69, 42, 9, ui.muted);
    }
    const tabs = .{ .{ "Shape", Tab.scalar }, .{ "Color", Tab.color }, .{ "Motion", Tab.motion }, .{ "Scene", Tab.scene }, .{ "Presets", Tab.presets }, .{ "Layers", Tab.inspector } };
    const tab_w: f32 = if (width() < 900) 62 else 78;
    const tab_x: f32 = if (width() < 900) 64 else 174;
    inline for (tabs, 0..) |tab, i| {
        const bounds = ui.rect(tab_x + @as(f32, @floatFromInt(i)) * tab_w, 20, tab_w - 6, 32);
        if (ui.button(bounds, tab[0], active_tab == tab[1], true)) onTabChange(tab[1]);
    }
    if (ui.button(ui.rect(width() - 184, 20, 62, 32), if (active_tab == .none) "Show / 2" else "Hide / 1", false, true)) {
        onTabChange(if (active_tab == .none) .scalar else .none);
    }
    if (ui.button(ui.rect(width() - 116, 20, 84, 32), "Settings", active_tab == .settings, true)) {
        onTabChange(if (active_tab == .settings) .none else .settings);
    }
}

fn contentHeight(tab: Tab) f32 {
    return switch (tab) {
        .scalar => scalarHeight(ShapeFields),
        .motion => scalarHeight(MotionFields),
        .settings => settings_prefix + scalarHeight(SettingsFields) + 138,
        .color => StudioPanel.colorHeight(),
        .presets => StudioPanel.presetsHeight(),
        .inspector => StudioPanel.inspectorHeight(),
        .scene => scene_prefix + geometry.scene_actions_height + SceneItems.len * geometry.scene_row_height,
        .audio => audio_content_height,
        .none => 0,
    };
}

/// Resolve against current logical UI coordinates before the scene is drawn.
pub fn hoveredElement() ?Element {
    if (resize_mode != .none) return null;
    const view = viewport();
    const offset = std.math.clamp(scroll, 0, @max(0, contentHeight(active_tab) - view.height));
    const dragging = if (rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) active_slider else null;
    if (dragging == null and !rl.IsCursorOnScreen()) return null;
    return elementAt(active_tab, view, offset, ui.mousePosition(), dragging);
}

fn elementAt(tab: Tab, view: rl.Rectangle, offset: f32, mouse: rl.Vector2, dragging: ?usize) ?Element {
    return switch (tab) {
        .scalar => groupElementAt(ShapeFields, view, offset, mouse, dragging, 0),
        .motion => groupElementAt(MotionFields, view, offset, mouse, dragging, 0),
        .color => StudioPanel.colorElementAt(view, offset, mouse, dragging),
        .inspector => if (rl.CheckCollisionPointRec(mouse, view)) StudioPanel.inspectorElement() else null,
        .scene => blk: {
            if (!rl.CheckCollisionPointRec(mouse, view)) break :blk null;
            if (dragging != null) break :blk null;
            var y = view.y - offset + scene_prefix + geometry.scene_actions_height;
            inline for (SceneItems) |item| {
                if (rl.CheckCollisionPointRec(mouse, ui.rect(view.x, y, view.width, geometry.scene_card_height))) break :blk item[3];
                y += geometry.scene_row_height;
            }
            break :blk null;
        },
        .none, .settings, .audio, .presets => null,
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
        const group_height: f32 = geometry.group_height + group[1].len * geometry.row_height;
        if (rl.CheckCollisionPointRec(mouse, ui.rect(view.x, y, view.width, group_height))) return group[2];
        y += group_height;
    }
    return null;
}

fn drawPanel(script: *ScriptScene, audio: *AudioSession) void {
    const p = panel();
    ui.card(p);
    const title: [:0]const u8, const subtitle: [:0]const u8 = switch (active_tab) {
        .scalar => .{ "Shape & texture", "Fine-tune the form of your sound." },
        .color => .{ "Color palette", "Find a hue for every layer." },
        .motion => .{ "Motion & response", "Give every beat its own character." },
        .scene => .{ "Scene studio", "Script your visuals or mix built-in layers." },
        .settings => .{ "Settings", "Performance, display and workspace." },
        .audio => .{ "Audio devices", "Choose where your sound comes from." },
        .presets => .{ "Preset library", "Save, duplicate and revisit your looks." },
        .inspector => .{ "Layer inspector", "Search, solo and fine-tune a layer." },
        .none => unreachable,
    };
    ui.label(title, p.x + 20, p.y + 12, 21, ui.text);
    ui.label(subtitle, p.x + 20, p.y + 38, 13, ui.muted);
    const view = viewport();
    const content_h = contentHeight(active_tab);
    const max_scroll = @max(0, content_h - view.height);
    scroll = std.math.clamp(scroll, 0, max_scroll);
    // The scrollbar is draggable as well as wheel-controlled.
    const track = ui.rect(p.x + p.width - 14, view.y, 8, view.height);
    if (max_scroll > 0 and active_slider == null and ui.hovered(track) and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
        active_slider = 2000;
        editing = null;
    }
    if (max_scroll > 0 and active_slider == 2000) {
        const thumb_h = @max(24, view.height * view.height / content_h);
        scroll = std.math.clamp((ui.mousePosition().y - view.y - thumb_h / 2) / (view.height - thumb_h), 0, 1) * max_scroll;
    }
    ui.beginScissor(view);
    switch (active_tab) {
        .scalar => drawScalars(ShapeFields, view, 0),
        .motion => drawScalars(MotionFields, view, 0),
        .settings => drawSettings(view),
        .audio => drawAudioDevices(view, audio),
        .color => StudioPanel.drawColors(script, view, scroll, editorField),
        .presets => StudioPanel.drawPresets(script, view, scroll),
        .inspector => StudioPanel.drawInspector(script, view, scroll, editorField),
        .scene => drawScene(view, script),
        .none => unreachable,
    }
    rl.EndScissorMode();
    if (max_scroll > 0) {
        const thumb_h = @max(24, view.height * view.height / content_h);
        ui.rounded(ui.rect(p.x + p.width - 7, view.y, 3, view.height), 1.5, ui.raised);
        ui.rounded(ui.rect(p.x + p.width - 7, view.y + (view.height - thumb_h) * scroll / max_scroll, 3, thumb_h), 1.5, ui.muted);
    }
    if (ui.button(ui.rect(p.x + 12, p.y + p.height - 24, 48, 20), "Undo", false, State.history.position > 0)) {
        editing = null;
        active_slider = null;
        State.history.undo(script);
    }
    if (ui.button(ui.rect(p.x + 64, p.y + p.height - 24, 48, 20), "Redo", false, State.history.position + 1 < State.history.len)) {
        editing = null;
        active_slider = null;
        State.history.redo(script);
    }
    ui.label("Right-click a control to reset", p.x + 120, p.y + p.height - 18, 10, ui.muted);
    for (0..3) |i| {
        const offset = @as(f32, @floatFromInt(i)) * 4;
        rl.DrawLineEx(.{ .x = p.x + p.width - 15 + offset, .y = p.y + p.height - 5 }, .{ .x = p.x + p.width - 5, .y = p.y + p.height - 15 + offset }, 1, if (resize_mode != .none) ui.accent else ui.muted);
    }
}

fn drawAudioDevices(view: rl.Rectangle, audio: *AudioSession) void {
    const top = view.y - scroll;
    const live = audio.captureActive();
    const supported = builtin.os.tag != .emscripten;
    const capture = @import("audio/capture.zig");
    const enabled = supported and !live and active_slider == null;
    groupHeading("CAPTURE SOURCE", view, top);
    const half = (view.width - 8) / 2;
    if (ui.button(ui.rect(view.x, top + 38, half, 30), "System audio", audio.selected_capture_mode == .system, enabled and buttonVisible(top + 38, view))) audio.selectCaptureMode(.system);
    if (ui.button(ui.rect(view.x + half + 8, top + 38, half, 30), "Input", audio.selected_capture_mode == .input, enabled and buttonVisible(top + 38, view))) audio.selectCaptureMode(.input);
    const hint: [:0]const u8 = if (!supported) "Live capture requires the native app." else if (live) "Stop capture to change the source." else if (audio.selected_capture_mode == .input) "Choose a microphone or audio input." else if (builtin.os.tag == .macos) "Choose a loopback input (e.g. BlackHole)." else if (builtin.os.tag == .windows) "Choose the output you want to capture." else "Choose a system-audio monitor input.";
    ui.label(hint, view.x + 4, top + 78, 11, ui.muted);
    if (ui.button(ui.rect(view.x, top + 102, view.width, 30), "Refresh devices", false, supported and active_slider == null and buttonVisible(top + 102, view))) audio.refreshCaptureDevices();
    const selected = audio.selectedCaptureDevice();
    ui.label(if (selected == -2) "Selected device disconnected. Choose another." else if (audio.capture_devices.count == 0) "No devices found. Connect one and refresh." else "Selection is kept until you close the app.", view.x + 4, top + 140, 11, if (selected == -2) ui.accent else ui.muted);
    const automatic: [:0]const u8 = if (audio.selected_capture_mode == capture.Mode.input) "Default input" else "Automatic system audio";
    if (ui.button(ui.rect(view.x, top + 166, view.width, 30), automatic, selected == -1, enabled and buttonVisible(top + 166, view))) audio.selectCaptureDevice(-1);
    for (0..audio.capture_devices.count) |index| {
        const y = top + 204 + @as(f32, @floatFromInt(index)) * 38;
        const row = ui.rect(view.x, y, view.width, 30);
        const chosen = selected == @as(i32, @intCast(index));
        const over = enabled and buttonVisible(y, view) and ui.hovered(row);
        ui.rounded(row, 7, if (chosen) ui.accent_soft else if (over) ui.raised else ui.surface);
        ui.label(audio.capture_devices.name(index), row.x + 8, row.y + 8, 13, if (chosen) ui.accent else if (live) ui.muted else ui.text);
        if (over) {
            ui.requestCursor(rl.MOUSE_CURSOR_POINTING_HAND);
            if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) audio.selectCaptureDevice(@intCast(index));
        }
    }
}

fn buttonVisible(y: f32, view: rl.Rectangle) bool {
    return y >= view.y and y + 30 <= view.y + view.height;
}

const ScalarGroup = struct { [:0]const u8, []const controls.Scalar, ?Element };
const ShapeFields = [_]ScalarGroup{
    .{ "WAVEFORM / LINES", &config.Visualizer.WaveFormLine.Scalars, .wave_lines },
    .{ "WAVEFORM / BARS", &config.Visualizer.WaveFormBar.Scalars, .wave_bars },
    .{ "3D BUBBLE", &config.Visualizer.Bubble.Scalars, .bubble },
    .{ "TEXTURE & BACKGROUND", &config.Shader.Scalars, null },
};
const MotionFields = [_]ScalarGroup{
    .{ "ENERGY & ENVELOPE", &config.Motion.Scalars, null },
    .{ "AUDIO RESPONSE", &config.Audio.Scalars, null },
    .{ "SPECTRUM", &config.Visualizer.Spectrum.Scalars, .spectrum },
    .{ "FREQUENCY HALO", &config.Visualizer.Halo.Scalars, .halo },
};
const SettingsFields = [_]ScalarGroup{
    .{ "WINDOW", &config.Window.Scalars, null },
    .{ "BACKGROUND & AUDIO", &.{
        .{ "Background opacity", &config.Shader.alpha_factor, .{ 0, 1 } },
        .{ "Master volume", &config.Audio.volume, .{ 0, 1 } },
    }, null },
};
const settings_reset_height: f32 = 64;
const settings_prefix: f32 = settings_reset_height + 208;

fn drawSettings(view: rl.Rectangle) void {
    const reset_y = view.y - scroll;
    if (ui.button(ui.rect(view.x, reset_y, view.width, 32), "Reset all settings", false, reset_y >= view.y and reset_y + 32 <= view.y + view.height)) settings_reset_requested = true;
    ui.label("Restores defaults. Keeps saved presets and swatches.", view.x + 4, reset_y + 40, 10, ui.muted);
    const top = reset_y + settings_reset_height;
    groupHeading("FPS PRESETS  /  0 = UNLIMITED", view, top);
    const presets = [_]f32{ 0, 30, 60, 120, 144, 240 };
    for (presets, 0..) |fps, index| {
        const x = view.x + @as(f32, @floatFromInt(index % 3)) * (view.width + 6) / 3;
        const y = top + 38 + @as(f32, @floatFromInt(index / 3)) * 36;
        var buffer: [16]u8 = undefined;
        const label = if (fps == 0) "Unlimited" else std.fmt.bufPrintZ(&buffer, "{d:.0} FPS", .{fps}) catch unreachable;
        if (ui.button(ui.rect(x, y, (view.width - 12) / 3, 30), label, config.Window.fps_limit == fps, y >= view.y and y + 30 <= view.y + view.height)) {
            config.Window.fps_limit = fps;
            editing = null;
        }
    }
    groupHeading("UI SIZE", view, top + 112);
    for ([_]f32{ 75, 100, 125, 150 }, 0..) |percent, index| {
        const x = view.x + @as(f32, @floatFromInt(index)) * (view.width + 6) / 4;
        const y = top + 150;
        var buffer: [16]u8 = undefined;
        const label = std.fmt.bufPrintZ(&buffer, "{d:.0}%", .{percent}) catch unreachable;
        if (ui.button(ui.rect(x, y, (view.width - 18) / 4, 30), label, config.Interface.scale_percent == percent, y >= view.y and y + 30 <= view.y + view.height)) {
            config.Interface.scale_percent = percent;
            editing = null;
        }
    }
    ui.label("Automatically fits smaller windows", view.x + 8, top + 186, 11, ui.muted);
    drawScalars(SettingsFields, view, settings_prefix);
    const bottom = reset_y + settings_prefix + scalarHeight(SettingsFields);
    if (ui.button(ui.rect(view.x, bottom, view.width, 32), if (config.Interface.show_fps) "FPS counter: On" else "FPS counter: Off", config.Interface.show_fps, bottom >= view.y and bottom + 32 <= view.y + view.height)) config.Interface.show_fps = !config.Interface.show_fps;
    if (ui.button(ui.rect(view.x, bottom + 42, view.width, 32), if (builtin.os.tag == .emscripten) "Always on top: Native only" else if (config.Window.always_on_top) "Always on top: On" else "Always on top: Off", config.Window.always_on_top, builtin.os.tag != .emscripten and bottom + 42 >= view.y and bottom + 74 <= view.y + view.height)) config.Window.always_on_top = !config.Window.always_on_top;
    if (ui.button(ui.rect(view.x, bottom + 84, view.width, 32), "Reset UI size and panel", false, bottom + 84 >= view.y and bottom + 116 <= view.y + view.height)) {
        config.Interface.scale_percent = 100;
        config.Interface.panel_width = 320;
        config.Interface.panel_height = 0;
        scroll = 0;
        editing = null;
    }
}

fn resizeModeAt(p: rl.Rectangle, mouse: rl.Vector2) ResizeMode {
    const corner = rl.CheckCollisionPointRec(mouse, ui.rect(p.x + p.width - 18, p.y + p.height - 18, 24, 24));
    const right = rl.CheckCollisionPointRec(mouse, ui.rect(p.x + p.width - 2, p.y, 8, p.height + 6));
    const bottom = rl.CheckCollisionPointRec(mouse, ui.rect(p.x, p.y + p.height - 4, p.width + 6, 10));
    return if (corner or (right and bottom)) .both else if (right) .width else if (bottom) .height else .none;
}

fn resizePanel() void {
    if (active_tab == .none) return;
    const p = panel();
    const mouse = ui.mousePosition();
    const hover_mode = resizeModeAt(p, mouse);
    if (hover_mode != .none and active_slider == null and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
        resize_mode = hover_mode;
        active_slider = resize_id;
        editing = null;
        resize_origin = mouse;
        resize_size = .{ .width = p.width, .height = p.height };
    }
    if (resize_mode != .none and rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
        const size = geometry.panelSize(resize_size.width + mouse.x - resize_origin.x, resize_size.height + mouse.y - resize_origin.y, width(), height());
        if (resize_mode == .width or resize_mode == .both) config.Interface.panel_width = size.width;
        if (resize_mode == .height or resize_mode == .both) config.Interface.panel_height = size.height;
    }
    const cursor_mode = if (resize_mode != .none) resize_mode else if (active_slider == null) hover_mode else .none;
    switch (cursor_mode) {
        .width => ui.requestCursor(rl.MOUSE_CURSOR_RESIZE_EW),
        .height => ui.requestCursor(rl.MOUSE_CURSOR_RESIZE_NS),
        .both => ui.requestCursor(rl.MOUSE_CURSOR_RESIZE_NWSE),
        .none => {},
    }
}

fn scalarHeight(comptime groups: anytype) f32 {
    comptime var total: f32 = 0;
    inline for (groups) |group| total += geometry.group_height + group[1].len * geometry.row_height;
    return total;
}
fn groupHeading(name: [:0]const u8, view: rl.Rectangle, y: f32) void {
    ui.label(name, view.x + 8, y + 8, 11, ui.accent);
    rl.DrawLineEx(.{ .x = view.x + 8, .y = y + 23 }, .{ .x = view.x + view.width - 8, .y = y + 23 }, 1, ui.border);
}
fn rowVisible(y: f32, view: rl.Rectangle) bool {
    return y >= view.y and y + geometry.slider_top + geometry.slider_height <= view.y + view.height;
}

fn drawScalars(comptime groups: anytype, view: rl.Rectangle, offset: f32) void {
    var y = view.y - scroll + offset;
    var id: usize = 0;
    inline for (groups) |group| {
        groupHeading(group[0], view, y);
        if (ui.button(ui.rect(view.x + view.width - 54, y + 2, 50, 22), "Reset", false, y >= view.y and y + 24 <= view.y + view.height)) {
            if (current_script) |script| for (group[1]) |scalar| State.reset(scalar[1], script);
        }
        y += geometry.group_height;
        inline for (group[1]) |scalar| {
            var label_buffer: [64]u8 = undefined;
            const label = std.fmt.bufPrintZ(&label_buffer, "{s}", .{scalar[0]}) catch unreachable;
            editorField(id, label, scalar[1], .{ scalar[2][0], scalar[2][1] }, view, y, false);
            y += geometry.row_height;
            id += 1;
        }
    }
}

fn editorField(id: usize, label: [:0]const u8, value: *f32, range: [2]f32, view: rl.Rectangle, y: f32, hue: bool) void {
    const locked = if (current_script) |script| State.locked(value, script) else false;
    const row_enabled = rowVisible(y, view) and !locked;
    if (!row_enabled and editing == id) editing = null;
    if (locked and active_slider == id) active_slider = null;
    var fitted_buffer: [256]u8 = undefined;
    ui.label(ui.fitted(label, 14, view.width - 92, &fitted_buffer), view.x + 8, y + 4, 14, if (locked) ui.muted else ui.text);
    if (!locked and State.changed(value)) rl.DrawCircleV(.{ .x = view.x + 2, .y = y + 10 }, 2, ui.accent);
    const box = ui.rect(view.x + view.width - 76, y, 68, 24);
    if (editing == id) {
        if (ui.valueBox(box, &editing_buffer, value) or
            (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT) and !ui.hovered(box))) editing = null;
    } else {
        var buf: [32]u8 = undefined;
        const number = if (locked) "Lua" else if (range[1] <= 2)
            std.fmt.bufPrintZ(&buf, "{d:.3}", .{value.*}) catch unreachable
        else
            std.fmt.bufPrintZ(&buf, "{d:.1}", .{value.*}) catch unreachable;
        ui.rounded(box, 5, ui.raised);
        ui.centered(number, box, 12, ui.muted);
        if (row_enabled and ui.hovered(box)) {
            ui.requestCursor(rl.MOUSE_CURSOR_IBEAM);
            if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
                editing = id;
                @memset(&editing_buffer, 0);
                _ = std.fmt.bufPrintZ(&editing_buffer, "{d:.3}", .{value.*}) catch unreachable;
            }
        }
    }
    if (row_enabled and ui.hovered(ui.rect(view.x, y, view.width, geometry.row_height)) and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_RIGHT)) {
        if (current_script) |script| State.reset(value, script);
        editing = null;
    }
    _ = slider(id, ui.rect(view.x + 8, y + geometry.slider_top, view.width - 16, geometry.slider_height), value, range[0], range[1], row_enabled, hue);
    controls.constrainScalar(.{ label, value, .{ range[0], range[1] } });
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
        value.* = min + std.math.clamp((ui.mousePosition().x - bounds.x) / bounds.width, 0, 1) * (max - min);
    }
    if (over or dragging) ui.requestCursor(rl.MOUSE_CURSOR_POINTING_HAND);
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

const SceneItems = .{
    .{ "Waveform lines", "The outline of your audio", &config.Scene.wave_lines, Element.wave_lines },
    .{ "Waveform bars", "Rhythm with a trailing glow", &config.Scene.wave_bars, Element.wave_bars },
    .{ "Spectrum", "Sound across the frequencies", &config.Scene.spectrum, Element.spectrum },
    .{ "3D bubble", "A sculptural, reactive core", &config.Scene.bubble, Element.bubble },
    .{ "Frequency halo", "A ring of spectral energy", &config.Scene.halo, Element.halo },
};

fn setLayerVisibility(pointer: *bool, value: bool, script: *const ScriptScene) void {
    const settings = @import("scripting/settings.zig");
    for (settings.entries, script.owned) |entry, owned| {
        if (entry.target == .boolean and entry.target.boolean == pointer and owned) return;
    }
    pointer.* = value;
}

fn drawScene(view: rl.Rectangle, script: *ScriptScene) void {
    ScriptPanel.draw(script, view, scroll, slider);
    var y = view.y - scroll + scene_prefix;
    const actions_enabled = y >= view.y and y + 36 <= view.y + view.height;
    if (ui.button(ui.rect(view.x, y, (view.width - 8) / 2, 34), "Show all", false, actions_enabled)) {
        inline for (SceneItems) |item| setLayerVisibility(item[2], true, script);
    }
    if (ui.button(ui.rect(view.x + (view.width + 8) / 2, y, (view.width - 8) / 2, 34), "Hide all", false, actions_enabled)) {
        inline for (SceneItems) |item| setLayerVisibility(item[2], false, script);
    }
    y += geometry.scene_actions_height;
    inline for (SceneItems) |item| {
        const bounds = ui.rect(view.x, y, view.width, geometry.scene_card_height);
        const over = y >= view.y and y + geometry.scene_card_height <= view.y + view.height and ui.hovered(bounds);
        ui.rounded(bounds, 8, if (over) ui.raised else ui.background);
        ui.label(item[0], view.x + 12, y + 10, 15, if (item[2].*) ui.text else ui.muted);
        ui.label(item[1], view.x + 12, y + 32, 11, ui.muted);
        const toggle = ui.rect(view.x + view.width - 48, y + 15, 36, 20);
        ui.rounded(toggle, 10, if (item[2].*) ui.accent_soft else ui.border);
        rl.DrawCircleV(.{ .x = toggle.x + (if (item[2].*) @as(f32, 26) else 10), .y = toggle.y + 10 }, 6, if (item[2].*) ui.accent else ui.muted);
        if (over) {
            ui.requestCursor(rl.MOUSE_CURSOR_POINTING_HAND);
            if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
                if (ui.hovered(toggle)) {
                    setLayerVisibility(item[2], !item[2].*, script);
                } else {
                    StudioPanel.selectLayer(item[3]);
                    onTabChange(.inspector);
                }
            }
        }
        y += geometry.scene_row_height;
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

/// Left edge of the scene viewport in logical UI coordinates: right of the
/// open side panel, or the window edge when it is hidden.
pub fn sceneLeft() f32 {
    if (active_tab == .none) return 0;
    const p = panel();
    return p.x + p.width + 8;
}

/// The player dock, in logical UI coordinates.
pub fn dockBounds() rl.Rectangle {
    return ui.rect(geometry.margin, height() - geometry.margin - geometry.dock_height, width() - 2 * geometry.margin, geometry.dock_height);
}

fn expandPlayerBounds() rl.Rectangle {
    return ui.rect(width() - 144, height() - 46, 128, 30);
}

fn drawPlayer(audio: *AudioSession) void {
    if (!config.Interface.show_player) {
        if (ui.button(expandPlayerBounds(), "Expand player", audio.notice != null, true)) config.Interface.show_player = true;
        return;
    }
    const dock = dockBounds();
    ui.card(dock);
    if (ui.button(ui.rect(width() - 128, dock.y + 8, 96, 26), "Hide player", false, true)) {
        config.Interface.show_player = false;
        return;
    }
    const live = audio.captureActive();
    const file = audio.hasFile() and !live;
    const text_x: f32 = 32;
    var title_buffer: [512]u8 = undefined;
    const title = if (live) (if (audio.captureMode() == .system) "LIVE INPUT  /  System audio" else "LIVE INPUT  /  Input audio") else if (file) std.fmt.bufPrintZ(&title_buffer, "{s}  /  {s}", .{ if (audio.seeking) "SEEKING" else if (audio.isFilePlaying()) "PLAYING" else "PAUSED", audio.filename() }) catch "Audio file" else "Your sound. Your scene.";
    ui.beginScissor(ui.rect(text_x, dock.y + 10, dock.width - 104 - (if (audio.notice != null) @as(f32, 112) else if (file) @as(f32, 188) else 32), 24));
    if (audio.notice) |notice| {
        ui.label(notice, text_x, dock.y + 12, 14, rl.GetColor(0xffd28aff));
    } else ui.label(title, text_x, dock.y + 10, 15, ui.text);
    rl.EndScissorMode();
    if (audio.notice != null and ui.button(ui.rect(width() - 212, dock.y + 8, 76, 26), "Dismiss", false, true)) audio.notice = null;

    if (file and audio.notice == null) {
        for ([_][:0]const u8{ "Low", "Mid", "High" }, WaveformCache.colors, 0..) |label, color, index| {
            const x = dock.x + dock.width - 270 + @as(f32, @floatFromInt(index)) * 52;
            rl.DrawCircleV(.{ .x = x, .y = dock.y + 20 }, 3, color);
            ui.label(label, x + 8, dock.y + 14, 12, color);
        }
    }
    const play = ui.rect(30, dock.y + 32, 104, 30);
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
        ui.requestCursor(rl.MOUSE_CURSOR_POINTING_HAND);
        if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) audio.togglePlayback();
    }
    const capture_supported = builtin.os.tag != .emscripten;
    if (ui.button(ui.rect(146, dock.y + 32, 132, 30), if (live) "Stop capture / M" else if (capture_supported) "Capture / M" else "Live unavailable", live, capture_supported)) audio.toggleCapture();
    if (ui.button(ui.rect(286, dock.y + 32, 70, 30), "Devices", active_tab == .audio, capture_supported)) {
        onTabChange(if (active_tab == .audio) .none else .audio);
        if (active_tab == .audio) audio.refreshCaptureDevices();
    }
    ui.label("Volume", width() - 280, dock.y + 40, 13, ui.muted);
    _ = slider(1001, ui.rect(width() - 222, dock.y + 38, 132, 18), &config.Audio.volume, 0, 1, true, false);
    var volume_buffer: [16]u8 = undefined;
    const volume = std.fmt.bufPrintZ(&volume_buffer, "{d}%", .{@as(u32, @intFromFloat(config.Audio.volume * 100))}) catch unreachable;
    ui.label(volume, width() - 74, dock.y + 40, 13, ui.text);
    if (file) {
        drawWaveformScrubber(audio, ui.rect(30, dock.y + 68, width() - 60, 44));
    } else {
        ui.rounded(ui.rect(30, dock.y + 68, width() - 60, 44), 6, ui.background);
        rl.DrawCircleV(.{ .x = 44, .y = dock.y + 90 }, 3, if (live) ui.accent else ui.muted);
        ui.label(if (live) "Listening live. Drop a file to switch to playback." else "Drop an audio file anywhere to start listening.", 56, dock.y + 83, 13, if (live) ui.accent else ui.muted);
    }
}

fn drawWaveformScrubber(audio: *AudioSession, bounds: rl.Rectangle) void {
    const duration = audio.timeLength();
    const mouse = ui.mousePosition();
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
    if (hovering or dragging_seek) ui.requestCursor(rl.MOUSE_CURSOR_POINTING_HAND);
    ui.rounded(bounds, 6, ui.background);
    const waveform = audio.waveform();
    const played = std.math.clamp(audio.timePlayed() / @max(duration, 0.001), 0, 1);
    waveform_cache.draw(waveform, bounds, played);
    if (waveform.len == 0) {
        ui.label(if (@import("audio/playback.zig").previewPending()) "Building waveform..." else "Waveform unavailable; seeking still works.", bounds.x + 8, bounds.y + 25, 11, ui.muted);
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
    try std.testing.expectEqual(@as(?Element, .bubble), elementAt(.scalar, view, 236, .{ .x = 30, .y = 110 }, null));
    try std.testing.expectEqual(@as(?Element, .halo), elementAt(.color, view, 478, .{ .x = 30, .y = 110 }, null));
    try std.testing.expectEqual(@as(?Element, .spectrum), elementAt(.motion, view, 412, .{ .x = 30, .y = 110 }, null));
    try std.testing.expectEqual(@as(?Element, null), elementAt(.motion, view, 0, .{ .x = 30, .y = 110 }, null));
    try std.testing.expectEqual(@as(?Element, null), elementAt(.scalar, view, 530, .{ .x = 30, .y = 110 }, null));
    try std.testing.expectEqual(@as(?Element, null), elementAt(.scalar, view, 0, .{ .x = 30, .y = 90 }, null));
    try std.testing.expectEqual(@as(?Element, null), elementAt(.scalar, view, 0, .{ .x = 30, .y = 410 }, null));
    try std.testing.expectEqual(@as(?Element, null), elementAt(.scalar, view, 0, .{ .x = 400, .y = 110 }, null));
}

test "scene hover excludes bulk actions and drag focus follows its owner" {
    const view = ui.rect(10, 100, 300, 300);
    try std.testing.expectEqual(@as(?Element, null), elementAt(.scene, view, 0, .{ .x = 30, .y = 120 }, null));
    try std.testing.expectEqual(@as(?Element, .wave_lines), elementAt(.scene, view, 0, .{ .x = 30, .y = 160 }, null));
    try std.testing.expectEqual(@as(?Element, null), elementAt(.scene, view, 0, .{ .x = 30, .y = 200 }, null));
    try std.testing.expectEqual(@as(?Element, .wave_bars), elementAt(.scene, view, 0, .{ .x = 30, .y = 230 }, null));
    try std.testing.expectEqual(@as(?Element, .wave_lines), elementAt(.scalar, view, 0, .{ .x = 900, .y = 600 }, 0));
    try std.testing.expectEqual(@as(?Element, .wave_lines), elementAt(.color, view, 0, .{ .x = 900, .y = 600 }, 100));
    try std.testing.expectEqual(@as(?Element, null), elementAt(.scalar, view, 0, .{ .x = 30, .y = 110 }, 1001));
    try std.testing.expectEqual(@as(?Element, null), elementAt(.none, view, 0, .{ .x = 30, .y = 110 }, 0));
}

test "panel resize grip includes its visible corner and excludes the scrollbar" {
    const p = ui.rect(16, 88, 320, 500);
    try std.testing.expectEqual(ResizeMode.both, resizeModeAt(p, .{ .x = 326, .y = 578 }));
    try std.testing.expectEqual(ResizeMode.width, resizeModeAt(p, .{ .x = 336, .y = 300 }));
    try std.testing.expectEqual(ResizeMode.height, resizeModeAt(p, .{ .x = 100, .y = 588 }));
    try std.testing.expectEqual(ResizeMode.none, resizeModeAt(p, .{ .x = 328, .y = 300 }));
    try std.testing.expectEqual(ResizeMode.none, resizeModeAt(p, .{ .x = 100, .y = 300 }));
}

test "script controls do not highlight built-in scene layers" {
    const previous_prefix = scene_prefix;
    defer scene_prefix = previous_prefix;
    scene_prefix = 416;
    const view = ui.rect(20, 100, 300, 300);
    try std.testing.expectEqual(@as(?Element, null), elementAt(.scene, view, 0, .{ .x = 30, .y = 160 }, null));
    try std.testing.expectEqual(@as(?Element, .wave_lines), elementAt(.scene, view, 416, .{ .x = 30, .y = 160 }, null));
    try std.testing.expectEqual(@as(?Element, null), elementAt(.scene, view, 416, .{ .x = 30, .y = 160 }, 4000));
}

test "the scene viewport starts right of the open panel and at the edge when hidden" {
    const original_tab = active_tab;
    defer active_tab = original_tab;
    active_tab = .none;
    try std.testing.expectEqual(@as(f32, 0), sceneLeft());
    for ([_]Tab{ .scalar, .settings }) |tab| {
        active_tab = tab;
        const p = panel();
        try std.testing.expectEqual(p.x + p.width + 8, sceneLeft());
    }
}

pub fn editorShortcuts(script: *ScriptScene) void {
    if (editingValue()) return;
    const command = rl.IsKeyDown(rl.KEY_LEFT_CONTROL) or rl.IsKeyDown(rl.KEY_RIGHT_CONTROL) or rl.IsKeyDown(rl.KEY_LEFT_SUPER) or rl.IsKeyDown(rl.KEY_RIGHT_SUPER);
    if (!command) return;
    const shift = rl.IsKeyDown(rl.KEY_LEFT_SHIFT) or rl.IsKeyDown(rl.KEY_RIGHT_SHIFT);
    if (rl.IsKeyPressed(rl.KEY_Z)) {
        if (shift) State.history.redo(script) else State.history.undo(script);
    } else if (rl.IsKeyPressed(rl.KEY_Y)) State.history.redo(script);
}
