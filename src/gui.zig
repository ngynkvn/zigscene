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
var active_tab: Tab = .inspector;
var path_entry = false;
var path_buffer: [4096]u8 = @splat(0);
var previous_tab: Tab = .inspector;
var fit_requested = false;
var welcome_open = false;
pub fn takeFitRequest() bool {
    const fit = fit_requested;
    fit_requested = false;
    return fit;
}
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
    if (next != .none) previous_tab = next;
    scroll = saved_scroll[@intCast(@intFromEnum(next))];
}

pub fn editingValue() bool {
    return editing != null or StudioPanel.text_editing or path_entry;
}

/// End transient UI gestures before entering the desktop pet's compact view.
pub fn cancelInteraction(audio: *AudioSession, script: *ScriptScene) void {
    audio.endSeek();
    dragging_seek = false;
    editing = null;
    StudioPanel.text_editing = false;
    active_slider = null;
    resize_mode = .none;
    State.history.record(script);
}

fn width() f32 {
    return ui.width();
}
fn height() f32 {
    return ui.height();
}
fn panelSize() geometry.Size {
    return geometry.panelSize(config.Interface.panel_width, config.Interface.panel_height, width(), height(), config.Interface.show_player);
}
fn panel() rl.Rectangle {
    const size = panelSize();
    return ui.rect(0, geometry.panel_top, size.width, size.height);
}
fn viewport() rl.Rectangle {
    const p = panel();
    const top = geometry.panel_header + 10;
    return ui.rect(p.x + 12, p.y + top, p.width - 24, p.height - top - 12);
}

/// UI wheel gestures must not also move the scene camera.
pub fn pointerOverUi() bool {
    return path_entry or ui.hovered(fitBounds()) or resize_mode != .none or @import("core/debug.zig").pointerOverUi() or
        (welcome_open and ui.hovered(welcomeBounds())) or
        ui.hovered(headerBounds()) or ui.hovered(statusBounds()) or
        (config.Interface.show_player and ui.hovered(dockBounds())) or
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
    ui.blocked = path_entry;
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
    drawStatusBar(audio, script);
    if ((audio.hasFile() or audio.captureActive()) and ui.button(fitBounds(), "Fit scene", false, script.usesBuiltin())) fit_requested = true;
    welcome_open = !audio.hasFile() and !audio.captureActive();
    if (welcome_open) drawWelcome(audio);
    ui.blocked = false;
    if (path_entry) drawPathEntry(audio);
}

pub fn openAudio(audio: *AudioSession) void {
    editing = null;
    active_slider = null;
    StudioPanel.text_editing = false;
    const picked = @import("audio/Picker.zig").open() catch {
        path_entry = true;
        rl.SetExitKey(rl.KEY_NULL);
        return;
    };
    if (picked) |path| audio.playFile(path);
}

fn welcomeBounds() rl.Rectangle {
    const scene = sceneBounds();
    const w = @min(360, scene.width - 32);
    const h: f32 = 214;
    return ui.rect(scene.x + (scene.width - w) / 2, scene.y + @max(0, (scene.height - h) / 2), w, h);
}

fn drawWelcome(audio: *AudioSession) void {
    const box = welcomeBounds();
    const w = box.width;
    ui.card(box);
    ui.centered("Bring your scene to life", ui.rect(box.x, box.y + 24, w, 24), 21, ui.text);
    ui.centered("Open a track or capture live audio.", ui.rect(box.x, box.y + 56, w, 18), 13, ui.muted);
    if (ui.primaryButton(ui.rect(box.x + 28, box.y + 90, w - 56, 34), "Open audio", !path_entry)) openAudio(audio);
    if (ui.secondaryButton(ui.rect(box.x + 28, box.y + 132, w - 56, 34), "Capture system audio", !path_entry and builtin.os.tag != .emscripten)) {
        audio.startCapture(.system, -1) catch onTabChange(.audio);
    }
    ui.centered("You can also drop an MP3, WAV or OGG.", ui.rect(box.x, box.y + 182, w, 18), 11, ui.muted);
}

// A path fallback keeps Open usable on minimal Linux desktops without a chooser.
fn drawPathEntry(audio: *AudioSession) void {
    const w = @min(520, width() - 40);
    const box = ui.rect((width() - w) / 2, (height() - 156) / 2, w, 156);
    ui.fill(ui.rect(0, 0, width(), height()), rl.Fade(ui.background, 0.8));
    ui.card(box);
    ui.label("Open audio file", box.x + 20, box.y + 16, 16, ui.text);
    ui.label("Paste the full path to an MP3, WAV or OGG.", box.x + 20, box.y + 42, 12, ui.muted);
    const submit = ui.textBox(ui.rect(box.x + 20, box.y + 66, w - 40, 30), &path_buffer, true);
    if (ui.secondaryButton(ui.rect(box.x + w - 200, box.y + 110, 84, 30), "Cancel", true) or rl.IsKeyPressed(rl.KEY_ESCAPE)) path_entry = false;
    if (ui.primaryButton(ui.rect(box.x + w - 104, box.y + 110, 84, 30), "Open", path_buffer[0] != 0) or (submit and path_buffer[0] != 0)) {
        audio.playFile(std.mem.sliceTo(&path_buffer, 0));
        path_entry = false;
    }
    if (!path_entry) rl.SetExitKey(rl.KEY_ESCAPE);
}

fn headerBounds() rl.Rectangle {
    return ui.rect(0, 0, width(), geometry.header_height);
}

fn drawHeader() void {
    const bar = headerBounds();
    ui.fill(bar, ui.surface);
    ui.hline(0, bar.height - 1, bar.width, ui.hairline);
    const middle = bar.height / 2;
    inline for (.{ 8, 16, 22, 13, 6 }, 0..) |h, i| {
        ui.rounded(ui.rect(18 + @as(f32, @floatFromInt(i)) * 4, middle - @as(f32, h) / 2, 2, h), 1, ui.accent);
    }
    const wide = width() >= 900;
    if (wide) ui.label("zigscene", 46, middle - 8, 15, ui.text);
    const tabs = .{ .{ "Layers", Tab.inspector }, .{ "Looks", Tab.presets }, .{ "Scene", Tab.scene }, .{ "Motion", Tab.motion }, .{ "Color", Tab.color }, .{ "Shape", Tab.scalar } };
    const tab_w: f32 = if (wide) 72 else 60;
    const tab_x: f32 = if (wide) 132 else 50;
    ui.vline(tab_x - 10, middle - 10, 20, ui.divider);
    inline for (tabs, 0..) |tab, i| {
        const bounds = ui.rect(tab_x + @as(f32, @floatFromInt(i)) * tab_w, 6, tab_w - 4, 28);
        if (ui.ghostButton(bounds, tab[0], active_tab == tab[1], true)) onTabChange(tab[1]);
    }
    if (ui.ghostButton(ui.rect(width() - 164, 6, 70, 28), if (active_tab == .none) "Panels" else "Hide / 1", false, true)) {
        onTabChange(if (active_tab == .none) previous_tab else .none);
    }
    if (ui.ghostButton(ui.rect(width() - 88, 6, 76, 28), "Settings", active_tab == .settings, true)) {
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
    if (resize_mode != .none or path_entry) return null;
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
    ui.fill(p, ui.surface);
    ui.vline(p.x + p.width - 1, p.y, p.height, ui.hairline);
    // A manually shortened panel ends above the player instead of meeting it.
    const full = geometry.panelSize(p.width, 0, width(), height(), config.Interface.show_player);
    if (p.height < full.height) ui.hline(p.x, p.y + p.height - 1, p.width, ui.hairline);
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
    // Photoshop-style tab strip: the active tab opens into the panel body.
    const strip_h = geometry.panel_header;
    ui.fill(ui.rect(p.x, p.y, p.width - 1, strip_h), ui.well);
    const tab = ui.rect(p.x, p.y, @min(p.width - 1, ui.textWidth(title, 13) + 32), strip_h);
    ui.fill(tab, ui.surface);
    ui.vline(tab.x + tab.width, p.y, strip_h, ui.hairline);
    ui.hline(tab.x + tab.width, p.y + strip_h - 1, p.width - 1 - tab.width, ui.hairline);
    ui.label(title, tab.x + 16, p.y + (strip_h - 13) / 2, 13, ui.text);
    ui.tooltip(tab, subtitle);
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
        const lit = active_slider == 2000 or ui.hovered(track);
        ui.rounded(ui.rect(p.x + p.width - 8, view.y + (view.height - thumb_h) * scroll / max_scroll, 4, thumb_h), 2, if (lit) ui.muted else ui.selection);
    }
    for (0..2) |i| {
        const offset = @as(f32, @floatFromInt(i)) * 4;
        rl.DrawLineEx(.{ .x = p.x + p.width - 11 + offset, .y = p.y + p.height - 4 }, .{ .x = p.x + p.width - 4, .y = p.y + p.height - 11 + offset }, 1, if (resize_mode != .none) ui.accent else ui.faint);
    }
}

fn statusBounds() rl.Rectangle {
    return ui.rect(0, height() - geometry.status_height, width(), geometry.status_height);
}

/// History, hints and workspace facts, laid out like an editor's status bar.
fn drawStatusBar(audio: *AudioSession, script: *ScriptScene) void {
    const bar = statusBounds();
    ui.fill(bar, ui.surface);
    ui.hline(0, bar.y, bar.width, ui.hairline);
    const y = bar.y + 3;
    const h = bar.height - 6;
    if (ui.ghostButton(ui.rect(6, y, 44, h), "Undo", false, State.history.position > 0)) {
        editing = null;
        active_slider = null;
        State.history.undo(script);
    }
    if (ui.ghostButton(ui.rect(52, y, 44, h), "Redo", false, State.history.position + 1 < State.history.len)) {
        editing = null;
        active_slider = null;
        State.history.redo(script);
    }
    ui.vline(102, y + 2, h - 4, ui.divider);
    // Segments are placed from the right edge; the hint takes what is left.
    var right = bar.width - 8;
    if (!config.Interface.show_player) {
        right -= 104;
        if (ui.ghostButton(ui.rect(right, y, 104, h), "Expand player", audio.notice != null, true)) config.Interface.show_player = true;
        right -= 8;
    }
    var buffers: [2][128]u8 = undefined;
    var shown: usize = 0;
    inline for (SceneItems) |item| shown += @intFromBool(item[2].*);
    const segments = [_][:0]const u8{
        std.fmt.bufPrintZ(&buffers[0], "UI {d:.0}%", .{ui.scale_factor * 100}) catch "",
        if (!script.usesBuiltin())
            std.fmt.bufPrintZ(&buffers[1], "Lua  \u{b7}  {s}", .{script.name()}) catch ""
        else if (script.runtime != null)
            std.fmt.bufPrintZ(&buffers[1], "Lua overlay  \u{b7}  {d} of {d} layers", .{ shown, SceneItems.len }) catch ""
        else
            std.fmt.bufPrintZ(&buffers[1], "{d} of {d} layers visible", .{ shown, SceneItems.len }) catch "",
    };
    for (segments) |segment| {
        const w = ui.textWidth(segment, 12);
        if (right - w - 24 < 260) break;
        right -= w;
        ui.label(segment, right, bar.y + 6, 12, ui.muted);
        right -= 12;
        ui.vline(right, y + 2, h - 4, ui.divider);
        right -= 12;
    }
    var hint: [256]u8 = undefined;
    const message = if (State.history.notice.len > 0) State.history.notice else "Right-click a control to reset it";
    ui.label(ui.fitted(message, 12, right - 114, &hint), 112, bar.y + 6, 12, ui.muted);
}

fn drawAudioDevices(view: rl.Rectangle, audio: *AudioSession) void {
    const top = view.y - scroll;
    const live = audio.captureActive();
    const supported = builtin.os.tag != .emscripten;
    const capture = @import("audio/capture.zig");
    const enabled = supported and !live and active_slider == null;
    groupHeading("Capture source", view, top, 0);
    const half = (view.width - 8) / 2;
    if (ui.button(ui.rect(view.x, top + 38, half, 30), "System audio", audio.selected_capture_mode == .system, enabled and buttonVisible(top + 38, view))) audio.selectCaptureMode(.system);
    if (ui.button(ui.rect(view.x + half + 8, top + 38, half, 30), "Input", audio.selected_capture_mode == .input, enabled and buttonVisible(top + 38, view))) audio.selectCaptureMode(.input);
    const hint: [:0]const u8 = if (!supported) "Live capture requires the native app." else if (live) "Stop capture to change the source." else if (audio.selected_capture_mode == .input) "Choose a microphone or audio input." else if (builtin.os.tag == .macos) "Choose a loopback input (e.g. BlackHole)." else if (builtin.os.tag == .windows) "Choose the output you want to capture." else "Choose a system-audio monitor input.";
    ui.label(hint, view.x + 4, top + 78, 11, ui.muted);
    if (ui.button(ui.rect(view.x, top + 102, view.width, 30), "Refresh devices", false, supported and active_slider == null and buttonVisible(top + 102, view))) audio.refreshCaptureDevices();
    const selected = audio.selectedCaptureDevice();
    ui.label(if (selected == -2) "Selected device disconnected. Choose another." else if (audio.capture_devices.count == 0) "No devices found. Connect one and refresh." else "Selection is kept until you close the app.", view.x + 4, top + 140, 11, if (selected == -2) ui.warning else ui.muted);
    const automatic: [:0]const u8 = if (audio.selected_capture_mode == capture.Mode.input) "Default input" else "Automatic system audio";
    if (radioRow(ui.rect(view.x, top + 166, view.width, 30), automatic, selected == -1, enabled and buttonVisible(top + 166, view))) audio.selectCaptureDevice(-1);
    for (0..audio.capture_devices.count) |index| {
        const y = top + 204 + @as(f32, @floatFromInt(index)) * 38;
        if (radioRow(ui.rect(view.x, y, view.width, 30), audio.capture_devices.name(index), selected == @as(i32, @intCast(index)), enabled and buttonVisible(y, view))) {
            audio.selectCaptureDevice(@intCast(index));
        }
    }
}

/// One choice in an exclusive list, marked with a filled radio dot.
fn radioRow(bounds: rl.Rectangle, value: [:0]const u8, chosen: bool, enabled: bool) bool {
    const over = enabled and ui.hovered(bounds);
    ui.rowFill(bounds, chosen, over);
    const dot = rl.Vector2{ .x = bounds.x + 15, .y = bounds.y + bounds.height / 2 };
    if (chosen) {
        rl.DrawCircleV(dot, 7, if (enabled) ui.accent else ui.accent_soft);
        rl.DrawCircleV(dot, 2.5, ui.on_accent);
    } else {
        rl.DrawCircleV(dot, 7, if (over) ui.muted else ui.border);
        rl.DrawCircleV(dot, 6, ui.field);
    }
    var buffer: [256]u8 = undefined;
    ui.label(ui.fitted(value, 13, bounds.width - 40, &buffer), bounds.x + 30, bounds.y + (bounds.height - 13) / 2, 13, if (enabled or chosen) ui.text else ui.muted);
    if (over) ui.requestCursor(rl.MOUSE_CURSOR_POINTING_HAND);
    return ui.activate(bounds, value, enabled);
}

fn buttonVisible(y: f32, view: rl.Rectangle) bool {
    return y >= view.y and y + 30 <= view.y + view.height;
}

const ScalarGroup = struct { [:0]const u8, []const controls.Scalar, ?Element };
const ShapeFields = [_]ScalarGroup{
    .{ "Waveform lines", &config.Visualizer.WaveFormLine.Scalars, .wave_lines },
    .{ "Waveform bars", &config.Visualizer.WaveFormBar.Scalars, .wave_bars },
    .{ "3D bubble", &config.Visualizer.Bubble.Scalars, .bubble },
    .{ "Texture & background", &config.Shader.Scalars, null },
};
const MotionFields = [_]ScalarGroup{
    .{ "Energy & envelope", &config.Motion.Scalars, null },
    .{ "Audio response", &config.Audio.Scalars, null },
    .{ "Spectrum", &config.Visualizer.Spectrum.Scalars, .spectrum },
    .{ "Frequency halo", &config.Visualizer.Halo.Scalars, .halo },
};
const SettingsFields = [_]ScalarGroup{
    .{ "Window", &config.Window.Scalars, null },
    .{ "Background & audio", &.{
        .{ "Background opacity", &config.Shader.alpha_factor, .{ 0, 1 } },
        .{ "Master volume", &config.Audio.volume, .{ 0, 1 } },
    }, null },
};
const settings_reset_height: f32 = 64;
const settings_prefix: f32 = settings_reset_height + 208;

fn drawSettings(view: rl.Rectangle) void {
    const reset_y = view.y - scroll;
    if (ui.button(ui.rect(view.x, reset_y, view.width, 32), "Reset all settings", false, reset_y >= view.y and reset_y + 32 <= view.y + view.height)) settings_reset_requested = true;
    ui.label("Restores defaults. Keeps saved presets and swatches.", view.x + 4, reset_y + 40, 11, ui.muted);
    const top = reset_y + settings_reset_height;
    groupHeading("Frame rate limit", view, top, 0);
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
    groupHeading("Interface size", view, top + 112, 0);
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
    ui.label("Automatically fits smaller windows", view.x + 4, top + 186, 11, ui.muted);
    drawScalars(SettingsFields, view, settings_prefix);
    const bottom = reset_y + settings_prefix + scalarHeight(SettingsFields);
    if (ui.checkbox(ui.rect(view.x, bottom, view.width, 32), "FPS counter", config.Interface.show_fps, bottom >= view.y and bottom + 32 <= view.y + view.height)) config.Interface.show_fps = !config.Interface.show_fps;
    if (ui.checkbox(ui.rect(view.x, bottom + 42, view.width, 32), if (builtin.os.tag == .emscripten) "Always on top (native only)" else "Always on top", config.Window.always_on_top, builtin.os.tag != .emscripten and bottom + 42 >= view.y and bottom + 74 <= view.y + view.height)) config.Window.always_on_top = !config.Window.always_on_top;
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
        const size = geometry.panelSize(resize_size.width + mouse.x - resize_origin.x, resize_size.height + mouse.y - resize_origin.y, width(), height(), config.Interface.show_player);
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
/// `reserve` leaves room at the right for an inline action such as Reset.
fn groupHeading(name: [:0]const u8, view: rl.Rectangle, y: f32, reserve: f32) void {
    ui.heading(name, view.x + 4, y + 8, view.width - 4 - (if (reserve > 0) reserve + 8 else 4));
}
fn rowVisible(y: f32, view: rl.Rectangle) bool {
    return y >= view.y and y + geometry.slider_top + geometry.slider_height <= view.y + view.height;
}

fn drawScalars(comptime groups: anytype, view: rl.Rectangle, offset: f32) void {
    var y = view.y - scroll + offset;
    var id: usize = 0;
    inline for (groups) |group| {
        groupHeading(group[0], view, y, 50);
        if (ui.ghostButton(ui.rect(view.x + view.width - 50, y + 3, 50, 22), "Reset", false, y >= view.y and y + 24 <= view.y + view.height)) {
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
    const was_editing = editing == id;
    const locked = if (current_script) |script| State.locked(value, script) else false;
    const row_enabled = rowVisible(y, view) and !locked;
    if (!row_enabled and editing == id) editing = null;
    if (locked and active_slider == id) active_slider = null;
    var fitted_buffer: [256]u8 = undefined;
    ui.label(ui.fitted(label, 13, view.width - 116, &fitted_buffer), view.x + 8, y + 5, 13, if (locked) ui.faint else ui.secondary);
    if (row_enabled) ui.tooltip(ui.rect(view.x, y, view.width - 106, 24), label);
    if (!locked and State.changed(value)) rl.DrawCircleV(.{ .x = view.x + 2, .y = y + 11 }, 2, ui.accent);
    const box = ui.rect(view.x + view.width - 98, y, 64, 24);
    const focused = ui.focusable(0x10000000 + id, box, row_enabled);
    if (focused and editing == null) {
        const step = (range[1] - range[0]) / (if (rl.IsKeyDown(rl.KEY_LEFT_SHIFT) or rl.IsKeyDown(rl.KEY_RIGHT_SHIFT)) @as(f32, 1000) else 100);
        if (rl.IsKeyPressed(rl.KEY_LEFT) or rl.IsKeyPressedRepeat(rl.KEY_LEFT)) value.* -= step;
        if (rl.IsKeyPressed(rl.KEY_RIGHT) or rl.IsKeyPressedRepeat(rl.KEY_RIGHT)) value.* += step;
        if (rl.IsKeyPressed(rl.KEY_HOME)) value.* = range[0];
        if (rl.IsKeyPressed(rl.KEY_END)) value.* = range[1];
    }
    if (editing == id) {
        if (ui.valueBox(box, &editing_buffer, value) or rl.IsKeyPressed(rl.KEY_TAB) or
            (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT) and !ui.hovered(box))) editing = null;
    } else {
        var buf: [32]u8 = undefined;
        const number = if (locked) "Lua" else if (range[1] <= 2)
            std.fmt.bufPrintZ(&buf, "{d:.3}", .{value.*}) catch unreachable
        else
            std.fmt.bufPrintZ(&buf, "{d:.1}", .{value.*}) catch unreachable;
        const over_box = row_enabled and ui.hovered(box);
        ui.framed(box, 3, ui.field, if (over_box) ui.muted else ui.divider);
        ui.label(number, box.x + box.width - 8 - ui.textWidth(number, 12), box.y + 6, 12, if (locked) ui.faint else ui.text);
        if (over_box) {
            ui.requestCursor(rl.MOUSE_CURSOR_IBEAM);
            if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
                editing = id;
                @memset(&editing_buffer, 0);
                _ = std.fmt.bufPrintZ(&editing_buffer, "{d:.3}", .{value.*}) catch unreachable;
            }
        }
    }
    if (focused and !was_editing and editing == null and rl.IsKeyPressed(rl.KEY_ENTER)) {
        editing = id;
        @memset(&editing_buffer, 0);
        _ = std.fmt.bufPrintZ(&editing_buffer, "{d:.3}", .{value.*}) catch unreachable;
    }
    // The reset icon appears only once a value differs from its default.
    const reset = ui.rect(view.x + view.width - 28, y, 24, 24);
    if (row_enabled and State.changed(value) and ui.iconButton(reset, .reset, "Reset this value to its default", false, true)) {
        if (current_script) |script| State.reset(value, script);
    }
    if (row_enabled) {
        ui.tooltip(box, "Enter a value; arrow keys adjust; Shift for finer steps");
        ui.tooltip(reset, "Reset this value to its default");
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
    // Host fields already register their numeric box. Standalone sliders
    // (volume and Lua parameters) need their own keyboard target.
    if ((id == 1001 or (id >= 4000 and id < 5000)) and ui.focusable(0x20000000 + id, bounds, enabled) and !ui.typing) {
        const step = (max - min) / (if (rl.IsKeyDown(rl.KEY_LEFT_SHIFT) or rl.IsKeyDown(rl.KEY_RIGHT_SHIFT)) @as(f32, 1000) else 100);
        if (rl.IsKeyPressed(rl.KEY_LEFT) or rl.IsKeyPressedRepeat(rl.KEY_LEFT)) value.* -= step;
        if (rl.IsKeyPressed(rl.KEY_RIGHT) or rl.IsKeyPressedRepeat(rl.KEY_RIGHT)) value.* += step;
        if (rl.IsKeyPressed(rl.KEY_HOME)) value.* = min;
        if (rl.IsKeyPressed(rl.KEY_END)) value.* = max;
        value.* = std.math.clamp(value.*, min, max);
    }
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
    if (hue) {
        for (0..6) |i| {
            const x = bounds.x + @as(f32, @floatFromInt(i)) * bounds.width / 6;
            const a = rl.ColorFromHSV(@as(f32, @floatFromInt(i)) * 60, 0.7, 0.92);
            const b = rl.ColorFromHSV(@as(f32, @floatFromInt(i + 1)) * 60, 0.7, 0.92);
            rl.DrawRectangleGradientEx(ui.rect(x, cy - 2, bounds.width / 6 + 1, 4), a, a, b, b);
        }
    } else {
        ui.rounded(ui.rect(bounds.x, cy - 1.5, bounds.width, 3), 1.5, ui.selection);
        if (ratio > 0) ui.rounded(ui.rect(bounds.x, cy - 1.5, @max(3, bounds.width * ratio), 3), 1.5, if (enabled) ui.accent else ui.faint);
    }
    // A white knob with a dark ring stays legible over both track colors.
    const center = rl.Vector2{ .x = bounds.x + ratio * bounds.width, .y = cy };
    const radius: f32 = if (over or dragging) 6.5 else 5.5;
    if (dragging) rl.DrawCircleV(center, 11, rl.Fade(ui.accent, 0.2));
    rl.DrawCircleV(center, radius + 1, ui.hairline);
    rl.DrawCircleV(center, radius, if (enabled or dragging) ui.text else ui.muted);
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
    groupHeading("Built-in layers", view, y + 2, 136);
    if (ui.ghostButton(ui.rect(view.x + view.width - 136, y + 5, 66, 24), "Show all", false, actions_enabled)) {
        inline for (SceneItems) |item| setLayerVisibility(item[2], true, script);
    }
    if (ui.ghostButton(ui.rect(view.x + view.width - 66, y + 5, 66, 24), "Hide all", false, actions_enabled)) {
        inline for (SceneItems) |item| setLayerVisibility(item[2], false, script);
    }
    y += geometry.scene_actions_height;
    // Rows read like an editor's layers list: visibility first, then the name.
    inline for (SceneItems, 0..) |item, i| {
        const bounds = ui.rect(view.x, y, view.width, geometry.scene_card_height);
        const visible = y >= view.y and y + geometry.scene_card_height <= view.y + view.height;
        const body = ui.rect(bounds.x + 40, bounds.y, bounds.width - 40, bounds.height);
        const over = visible and ui.hovered(bounds);
        ui.rowFill(bounds, false, over);
        if (i + 1 < SceneItems.len) ui.hline(view.x + 8, y + geometry.scene_card_height + 4, view.width - 16, ui.divider);
        const eye = ui.rect(bounds.x + 6, bounds.y + 15, 28, 28);
        if (ui.iconButton(eye, if (item[2].*) .eye else .eye_off, "Show or hide this layer", false, visible)) setLayerVisibility(item[2], !item[2].*, script);
        ui.label(item[0], body.x + 4, y + 11, 14, if (item[2].*) ui.text else ui.muted);
        ui.label(item[1], body.x + 4, y + 32, 11, ui.muted);
        ui.icon(.chevron_right, .{ .x = bounds.x + bounds.width - 16, .y = y + geometry.scene_card_height / 2 }, if (over) ui.text else ui.faint);
        if (visible and ui.hovered(body)) ui.requestCursor(rl.MOUSE_CURSOR_POINTING_HAND);
        if (ui.activate(body, item[0], visible)) {
            StudioPanel.selectLayer(item[3]);
            onTabChange(.inspector);
        }
        y += geometry.scene_row_height;
    }
}

pub fn onSwipe(dir: Direction, amount: f32) void {
    if (path_entry) return;
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
    return p.x + p.width;
}

/// The player dock, in logical UI coordinates.
pub fn dockBounds() rl.Rectangle {
    const h = geometry.dockHeight(width(), height());
    return ui.rect(0, height() - geometry.status_height - h, width(), h);
}

/// The canvas between the docked bars and panels.
pub fn sceneBounds() rl.Rectangle {
    const left = sceneLeft();
    const bottom = if (config.Interface.show_player) dockBounds().y else statusBounds().y;
    return ui.rect(left, geometry.panel_top, @max(1, width() - left), @max(1, bottom - geometry.panel_top));
}

fn fitBounds() rl.Rectangle {
    return ui.rect(width() - 96, geometry.panel_top + 10, 84, 26);
}

/// Round transport button; the accent fill marks a loaded track.
fn playButton(audio: *AudioSession, bounds: rl.Rectangle, file: bool) void {
    const enabled = file and !path_entry;
    const over = enabled and ui.hovered(bounds);
    const center = rl.Vector2{ .x = bounds.x + bounds.width / 2, .y = bounds.y + bounds.height / 2 };
    rl.DrawCircleV(center, bounds.width / 2, if (!file) ui.control else if (over) ui.accent_hover else ui.accent);
    ui.icon(if (audio.isFilePlaying()) .pause else .play, center, if (file) ui.on_accent else ui.faint);
    ui.tooltip(bounds, "Play or pause (Space / P)");
    if (over) ui.requestCursor(rl.MOUSE_CURSOR_POINTING_HAND);
    if (ui.activate(bounds, "Playback", enabled)) audio.togglePlayback();
}

/// Speaker icon, slider and level; returns the left edge it used.
fn drawVolume(right: f32, y: f32, slider_width: f32, enabled: bool) f32 {
    var volume_buffer: [16]u8 = undefined;
    const volume = std.fmt.bufPrintZ(&volume_buffer, "{d}%", .{@as(u32, @intFromFloat(config.Audio.volume * 100))}) catch unreachable;
    const level_x = right - 34;
    ui.label(volume, level_x, y + 7, 12, ui.secondary);
    const track = ui.rect(level_x - 12 - slider_width, y + 5, slider_width, 18);
    _ = slider(1001, track, &config.Audio.volume, 0, 1, enabled, false);
    ui.icon(.volume, .{ .x = track.x - 22, .y = y + 14 }, ui.muted);
    return track.x - 34;
}

fn formatTime(buffer: []u8, seconds: f32) [:0]const u8 {
    const whole: u32 = @intFromFloat(@max(0, seconds));
    return std.fmt.bufPrintZ(buffer, "{d}:{d:0>2}", .{ whole / 60, whole % 60 }) catch unreachable;
}

fn drawPlayer(audio: *AudioSession) void {
    if (!config.Interface.show_player) return;
    const dock = dockBounds();
    ui.fill(dock, ui.surface);
    ui.hline(dock.x, dock.y, dock.width, ui.hairline);
    if (geometry.compact(width(), height())) {
        drawCompactPlayer(audio, dock);
        return;
    }
    const live = audio.captureActive();
    const file = audio.hasFile() and !live;
    const capture_supported = builtin.os.tag != .emscripten;
    const row = dock.y + 10;
    playButton(audio, ui.rect(16, row, 32, 32), file);

    // Controls are placed from the right edge so the title gets what is left.
    var x = dock.width - 16 - 92;
    if (ui.button(ui.rect(x, row + 2, 92, 28), "Hide player", false, true)) {
        config.Interface.show_player = false;
        return;
    }
    x = drawVolume(x - 16, row + 2, if (dock.width < 960) 72 else 96, true);
    ui.vline(x, row + 6, 20, ui.divider);
    x -= 12 + 96;
    if (ui.button(ui.rect(x, row + 2, 96, 28), "Open audio", false, !path_entry)) openAudio(audio);
    x -= 8 + 76;
    if (ui.button(ui.rect(x, row + 2, 76, 28), "Devices", active_tab == .audio, capture_supported)) {
        onTabChange(if (active_tab == .audio) .none else .audio);
        if (active_tab == .audio) audio.refreshCaptureDevices();
    }
    x -= 8 + 124;
    if (ui.button(ui.rect(x, row + 2, 124, 28), if (live) "Stop capture / M" else if (capture_supported) "Capture / M" else "Live unavailable", live, capture_supported)) audio.toggleCapture();
    if (audio.notice != null) {
        x -= 8 + 76;
        if (ui.button(ui.rect(x, row + 2, 76, 28), "Dismiss", false, true)) audio.notice = null;
    }

    const title_x: f32 = 60;
    const title_w = @max(0, x - 16 - title_x);
    var buffer: [256]u8 = undefined;
    if (audio.notice) |notice| {
        ui.label(ui.fitted(notice, 13, title_w, &buffer), title_x, row + 9, 13, ui.warning);
        ui.tooltip(ui.rect(title_x, row, title_w, 32), notice);
    } else {
        var name_buffer: [512]u8 = undefined;
        const title: [:0]const u8 = if (live) "Live input" else if (file) (std.fmt.bufPrintZ(&name_buffer, "{s}", .{audio.filename()}) catch "Audio file") else "No audio loaded";
        const status: [:0]const u8 = if (live) (if (audio.captureMode() == .system) "System audio" else "Input device") else if (!file) "Open a file or capture live audio" else if (audio.seeking) "Seeking" else if (audio.isFilePlaying()) "Playing" else "Paused";
        ui.label(ui.fitted(title, 14, title_w, &buffer), title_x, row + 1, 14, ui.text);
        ui.label(status, title_x, row + 20, 11, if (live) ui.accent else ui.muted);
        // Band colors of the seek waveform, beside the status when there is room.
        var legend_x = title_x + ui.textWidth(status, 11) + 14;
        if (file and legend_x + 150 <= title_x + title_w) {
            for ([_][:0]const u8{ "Low", "Mid", "High" }, WaveformCache.colors) |band, color| {
                rl.DrawCircleV(.{ .x = legend_x + 3, .y = row + 26 }, 3, color);
                ui.label(band, legend_x + 10, row + 20, 11, ui.muted);
                legend_x += 18 + ui.textWidth(band, 11) + 12;
            }
        }
    }

    const track = ui.rect(68, dock.y + 52, dock.width - 136, 38);
    if (file) {
        var time_buffer: [24]u8 = undefined;
        const elapsed = formatTime(&time_buffer, audio.timePlayed());
        ui.label(elapsed, track.x - 12 - ui.textWidth(elapsed, 12), track.y + 12, 12, ui.secondary);
        const total = formatTime(&time_buffer, audio.timeLength());
        ui.label(total, track.x + track.width + 12, track.y + 12, 12, ui.muted);
        drawWaveformScrubber(audio, track, false);
    } else {
        const empty = ui.rect(16, track.y, dock.width - 32, track.height);
        ui.rounded(empty, 4, ui.background);
        rl.DrawCircleV(.{ .x = empty.x + 16, .y = empty.y + empty.height / 2 }, 3, if (live) ui.accent else ui.faint);
        ui.label(if (live) "Listening live. Drop a file to switch to playback." else "Drop an audio file anywhere to start listening.", empty.x + 28, empty.y + 12, 13, if (live) ui.secondary else ui.muted);
    }
}

fn drawCompactPlayer(audio: *AudioSession, dock: rl.Rectangle) void {
    const live = audio.captureActive();
    const file = audio.hasFile() and !live;
    const row = dock.y + 8;
    playButton(audio, ui.rect(dock.x + 10, row, 28, 28), file);
    if (ui.button(ui.rect(dock.x + 46, row, 60, 28), "Open", false, !path_entry)) openAudio(audio);
    if (ui.button(ui.rect(dock.x + 112, row, 80, 28), if (live) "Stop live" else "Capture", live, builtin.os.tag != .emscripten and !path_entry)) audio.toggleCapture();
    if (ui.button(ui.rect(dock.x + 198, row, 70, 28), "Devices", active_tab == .audio, builtin.os.tag != .emscripten and !path_entry)) onTabChange(.audio);
    if (ui.button(ui.rect(dock.x + dock.width - 62, row, 52, 28), "Hide", false, !path_entry)) config.Interface.show_player = false;
    _ = drawVolume(dock.x + dock.width - 74, row, 84, !path_entry);
    const lower = ui.rect(dock.x + 10, dock.y + 44, dock.width - 20, 28);
    if (audio.notice) |notice| {
        var buffer: [256]u8 = undefined;
        ui.label(ui.fitted(notice, 12, lower.width - 66, &buffer), lower.x, lower.y + 7, 12, ui.warning);
        if (ui.button(ui.rect(lower.x + lower.width - 62, lower.y, 62, 28), "Dismiss", false, true)) audio.notice = null;
    } else if (file) drawWaveformScrubber(audio, lower, true) else {
        ui.rounded(lower, 4, ui.background);
        ui.label(if (live) "Listening to live audio" else "Open audio or capture a live source", lower.x + 10, lower.y + 8, 12, ui.muted);
    }
}

/// `timer` overlays elapsed and total time where there is no room beside it.
fn drawWaveformScrubber(audio: *AudioSession, bounds: rl.Rectangle, timer: bool) void {
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
    ui.rounded(bounds, 4, ui.background);
    const waveform = audio.waveform();
    const played = std.math.clamp(audio.timePlayed() / @max(duration, 0.001), 0, 1);
    waveform_cache.draw(waveform, bounds, played);
    if (waveform.len == 0) {
        ui.label(if (@import("audio/playback.zig").previewPending()) "Building waveform..." else "Waveform unavailable; seeking still works.", bounds.x + 8, bounds.y + bounds.height / 2 - 14, 11, ui.muted);
        ui.hline(bounds.x, bounds.y + bounds.height / 2, bounds.width, ui.divider);
    }
    const playhead_x = bounds.x + bounds.width * played;
    rl.DrawLineEx(.{ .x = playhead_x, .y = bounds.y }, .{ .x = playhead_x, .y = bounds.y + bounds.height }, 1.5, ui.text);

    if (timer) {
        var elapsed_buffer: [24]u8 = undefined;
        var total_buffer: [24]u8 = undefined;
        var timer_buffer: [48]u8 = undefined;
        const value = std.fmt.bufPrintZ(&timer_buffer, "{s} / {s}", .{ formatTime(&elapsed_buffer, audio.timePlayed()), formatTime(&total_buffer, duration) }) catch unreachable;
        const timer_width = ui.textWidth(value, 12) + 16;
        const timer_bounds = ui.rect(bounds.x + bounds.width - timer_width - 3, bounds.y + 3, timer_width, bounds.height - 6);
        ui.framed(timer_bounds, 3, ui.well, ui.divider);
        ui.centered(value, timer_bounds, 12, ui.text);
    }
    if (hovering) {
        var preview_buffer: [48]u8 = undefined;
        var time_buffer: [24]u8 = undefined;
        const preview = std.fmt.bufPrintZ(&preview_buffer, "Seek to {s}", .{formatTime(&time_buffer, duration * std.math.clamp((mouse.x - bounds.x) / bounds.width, 0, 1))}) catch unreachable;
        const preview_width = ui.textWidth(preview, 12) + 20;
        const preview_x = std.math.clamp(mouse.x - preview_width / 2, bounds.x, bounds.x + bounds.width - preview_width);
        rl.DrawLineEx(.{ .x = mouse.x, .y = bounds.y }, .{ .x = mouse.x, .y = bounds.y + bounds.height }, 1, ui.accent);
        const preview_bounds = ui.rect(preview_x, bounds.y - 28, preview_width, 24);
        ui.framed(preview_bounds, 4, ui.well, ui.accent);
        ui.centered(preview, preview_bounds, 12, ui.text);
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
        try std.testing.expectEqual(p.x + p.width, sceneLeft());
    }
}

pub fn editorShortcuts(script: *ScriptScene) void {
    if (editingValue()) return;
    if (active_tab != .none) {
        if (rl.IsKeyPressed(rl.KEY_PAGE_DOWN)) scroll += viewport().height * 0.75;
        if (rl.IsKeyPressed(rl.KEY_PAGE_UP)) scroll -= viewport().height * 0.75;
    }
    const command = rl.IsKeyDown(rl.KEY_LEFT_CONTROL) or rl.IsKeyDown(rl.KEY_RIGHT_CONTROL) or rl.IsKeyDown(rl.KEY_LEFT_SUPER) or rl.IsKeyDown(rl.KEY_RIGHT_SUPER);
    if (!command) return;
    const shift = rl.IsKeyDown(rl.KEY_LEFT_SHIFT) or rl.IsKeyDown(rl.KEY_RIGHT_SHIFT);
    if (rl.IsKeyPressed(rl.KEY_Z)) {
        if (shift) State.history.redo(script) else State.history.undo(script);
    } else if (rl.IsKeyPressed(rl.KEY_Y)) State.history.redo(script);
}
