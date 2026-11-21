//! The transport dock: playback, capture and volume controls above a
//! seekable waveform. Requests that belong to the wider workspace are
//! returned to the caller rather than acted on here.
const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");
const AudioSession = @import("../audio/Session.zig");
const processor = @import("../audio/processor.zig");
const config = @import("../core/config.zig");
const fields = @import("fields.zig");
const geometry = @import("geometry.zig");
const ui = @import("theme.zig");
const WaveformCache = @import("WaveformCache.zig");

pub const Action = enum { open_audio, toggle_devices, show_devices };
pub const Context = struct {
    /// A dialog is open over the workspace, so the dock must not start one.
    modal: bool,
    devices_open: bool,
};

/// A seek drag is in progress.
pub var seeking = false;
var waveform_cache: WaveformCache = .{};
var modal = false;
var devices_open = false;
var request: ?Action = null;

pub fn deinit() void {
    waveform_cache.deinit();
}

/// Ends a seek or volume drag whose button, track or dock went away.
pub fn update(audio: *AudioSession) void {
    const held = rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT);
    if (seeking and (!held or !config.Interface.show_player or !audio.seeking or fields.active_slider != fields.seek_id or audio.captureActive() or !audio.hasFile())) {
        audio.endSeek();
        seeking = false;
        if (fields.active_slider == fields.seek_id) fields.active_slider = null;
    }
    if (!config.Interface.show_player and fields.active_slider == fields.volume_id) fields.active_slider = null;
}

pub fn draw(audio: *AudioSession, dock: rl.Rectangle, context: Context) ?Action {
    if (!config.Interface.show_player) return null;
    modal = context.modal;
    devices_open = context.devices_open;
    request = null;
    ui.fill(dock, ui.surface);
    ui.hline(dock.x, dock.y, dock.width, ui.hairline);
    if (geometry.compact(ui.width(), ui.height())) drawCompact(audio, dock) else drawWide(audio, dock);
    return request;
}

/// Round transport button; the accent fill marks a loaded track.
fn playButton(audio: *AudioSession, bounds: rl.Rectangle, file: bool) void {
    const enabled = file and !modal;
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
    const volume = std.mem.printSentinel(&volume_buffer, "{d}%", .{@as(u32, @intFromFloat(config.Audio.volume * 100))}, 0) catch unreachable;
    const level_x = right - 34;
    ui.label(volume, level_x, y + 7, 12, ui.secondary);
    const track = ui.rect(level_x - 12 - slider_width, y + 5, slider_width, 18);
    _ = fields.slider(fields.volume_id, track, &config.Audio.volume, 0, 1, enabled, false);
    ui.icon(.volume, .{ .x = track.x - 22, .y = y + 14 }, ui.muted);
    return track.x - 34;
}

fn formatTime(buffer: []u8, seconds: f32) [:0]const u8 {
    const whole: u32 = @intFromFloat(@max(0, seconds));
    return std.mem.printSentinel(buffer, "{d}:{d:0>2}", .{ whole / 60, whole % 60 }, 0) catch unreachable;
}

fn drawWide(audio: *AudioSession, dock: rl.Rectangle) void {
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
    if (ui.button(ui.rect(x, row + 2, 96, 28), "Open audio", false, !modal)) request = .open_audio;
    x -= 8 + 76;
    if (ui.button(ui.rect(x, row + 2, 76, 28), "Devices", devices_open, capture_supported)) request = .toggle_devices;
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
        const title: [:0]const u8 = if (live) "Live input" else if (file) (std.mem.printSentinel(&name_buffer, "{s}", .{audio.filename()}, 0) catch "Audio file") else "No audio loaded";
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
    } else if (live) {
        drawInputMeter(ui.rect(16, track.y, dock.width - 32, track.height));
    } else {
        const empty = ui.rect(16, track.y, dock.width - 32, track.height);
        ui.rounded(empty, 4, ui.background);
        ui.label("Drop an audio file anywhere to start listening.", empty.x + 12, empty.y + 12, 13, ui.muted);
    }
}

fn drawCompact(audio: *AudioSession, dock: rl.Rectangle) void {
    const live = audio.captureActive();
    const file = audio.hasFile() and !live;
    const row = dock.y + 8;
    playButton(audio, ui.rect(dock.x + 10, row, 28, 28), file);
    if (ui.button(ui.rect(dock.x + 46, row, 60, 28), "Open", false, !modal)) request = .open_audio;
    if (ui.button(ui.rect(dock.x + 112, row, 80, 28), if (live) "Stop live" else "Capture", live, builtin.os.tag != .emscripten and !modal)) audio.toggleCapture();
    if (ui.button(ui.rect(dock.x + 198, row, 70, 28), "Devices", devices_open, builtin.os.tag != .emscripten and !modal)) request = .show_devices;
    if (ui.button(ui.rect(dock.x + dock.width - 62, row, 52, 28), "Hide", false, !modal)) config.Interface.show_player = false;
    _ = drawVolume(dock.x + dock.width - 74, row, 84, !modal);
    const lower = ui.rect(dock.x + 10, dock.y + 44, dock.width - 20, 28);
    if (audio.notice) |notice| {
        var buffer: [256]u8 = undefined;
        ui.label(ui.fitted(notice, 12, lower.width - 66, &buffer), lower.x, lower.y + 7, 12, ui.warning);
        if (ui.button(ui.rect(lower.x + lower.width - 62, lower.y, 62, 28), "Dismiss", false, true)) audio.notice = null;
    } else if (file) {
        drawWaveformScrubber(audio, lower, true);
    } else if (live) {
        drawInputMeter(lower);
    } else {
        ui.rounded(lower, 4, ui.background);
        ui.label("Open audio or capture a live source", lower.x + 10, lower.y + 8, 12, ui.muted);
    }
}

fn drawInputMeter(bounds: rl.Rectangle) void {
    const db = 20 * @log10(@max(0.001, processor.input_peak));
    const clipped = processor.clip_seconds_remaining > 0;
    const color = if (clipped) rl.RED else if (db >= -6) ui.warning else ui.accent;
    var buffer: [32]u8 = undefined;
    const label: [:0]const u8 = if (clipped) "Input clipping" else if (db <= -60) "No input signal" else std.mem.printSentinel(&buffer, "Peak {d:.0} dBFS", .{db}, 0) catch unreachable;
    ui.rounded(bounds, 4, ui.background);
    const middle = bounds.y + bounds.height / 2;
    ui.label(label, bounds.x + 10, middle - 7, 12, if (clipped) ui.warning else ui.secondary);
    const bar = ui.rect(bounds.x + 128, middle - 3, bounds.width - 140, 6);
    ui.fill(bar, ui.divider);
    const level = std.math.clamp((db + 60) / 60, 0, 1);
    if (level > 0) ui.fill(ui.rect(bar.x, bar.y, bar.width * level, bar.height), color);
    ui.tooltip(bounds, "Captured stereo peak, from -60 to 0 dBFS");
}

/// `timer` overlays elapsed and total time where there is no room beside it.
fn drawWaveformScrubber(audio: *AudioSession, bounds: rl.Rectangle, timer: bool) void {
    const duration = audio.timeLength();
    const mouse = ui.mousePosition();
    const hovering = ui.hovered(bounds) and duration > 0;
    if (hovering and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT) and fields.active_slider == null) {
        fields.active_slider = fields.seek_id;
        seeking = true;
        fields.editing = null;
        audio.beginSeek();
    }
    if (seeking and rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
        audio.seekTo(duration * std.math.clamp((mouse.x - bounds.x) / bounds.width, 0, 1));
    }
    if (hovering or seeking) ui.requestCursor(rl.MOUSE_CURSOR_POINTING_HAND);
    ui.rounded(bounds, 4, ui.background);
    const waveform = audio.waveform();
    const played = std.math.clamp(audio.timePlayed() / @max(duration, 0.001), 0, 1);
    waveform_cache.draw(waveform, bounds, played);
    if (waveform.len == 0) {
        ui.label(if (@import("../audio/playback.zig").previewPending()) "Building waveform..." else "Waveform unavailable; seeking still works.", bounds.x + 8, bounds.y + bounds.height / 2 - 14, 11, ui.muted);
        ui.hline(bounds.x, bounds.y + bounds.height / 2, bounds.width, ui.divider);
    }
    const playhead_x = bounds.x + bounds.width * played;
    rl.DrawLineEx(.{ .x = playhead_x, .y = bounds.y }, .{ .x = playhead_x, .y = bounds.y + bounds.height }, 1.5, ui.text);

    if (timer) {
        var elapsed_buffer: [24]u8 = undefined;
        var total_buffer: [24]u8 = undefined;
        var timer_buffer: [48]u8 = undefined;
        const value = std.mem.printSentinel(&timer_buffer, "{s} / {s}", .{ formatTime(&elapsed_buffer, audio.timePlayed()), formatTime(&total_buffer, duration) }, 0) catch unreachable;
        const timer_width = ui.textWidth(value, 12) + 16;
        const timer_bounds = ui.rect(bounds.x + bounds.width - timer_width - 3, bounds.y + 3, timer_width, bounds.height - 6);
        ui.framed(timer_bounds, 3, ui.well, ui.divider);
        ui.centered(value, timer_bounds, 12, ui.text);
    }
    if (hovering) {
        var preview_buffer: [48]u8 = undefined;
        var time_buffer: [24]u8 = undefined;
        const preview = std.mem.printSentinel(&preview_buffer, "Seek to {s}", .{formatTime(&time_buffer, duration * std.math.clamp((mouse.x - bounds.x) / bounds.width, 0, 1))}, 0) catch unreachable;
        const preview_width = ui.textWidth(preview, 12) + 20;
        const preview_x = std.math.clamp(mouse.x - preview_width / 2, bounds.x, bounds.x + bounds.width - preview_width);
        rl.DrawLineEx(.{ .x = mouse.x, .y = bounds.y }, .{ .x = mouse.x, .y = bounds.y + bounds.height }, 1, ui.accent);
        const preview_bounds = ui.rect(preview_x, bounds.y - 28, preview_width, 24);
        ui.framed(preview_bounds, 4, ui.well, ui.accent);
        ui.centered(preview, preview_bounds, 12, ui.text);
    }
}
