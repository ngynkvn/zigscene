//! Preset library, searchable layer inspector and full HSV palette controls.
const std = @import("std");
const rl = @import("raylib");
const ui = @import("theme.zig");
const geometry = @import("geometry.zig");
const config = @import("../core/config.zig");
const settings = @import("../scripting/settings.zig");
const State = @import("../editor/State.zig");
const Presets = @import("../editor/Presets.zig");
const Scene = @import("../scripting/Scene.zig");
const Highlight = @import("../graphics/Highlight.zig");
const Element = Highlight.Element;

pub var text_editing = false;
var name_buffer: [64]u8 = initName();
var search: [64]u8 = @splat(0);
var selected_preset: ?usize = null;
var selected_layer: usize = 0;
var expanded_color: ?usize = 0;
var collapsed: [3]bool = @splat(false);
var notice: [:0]const u8 = "";
var color_notice: [:0]const u8 = "";

pub fn resetWorkspace() void {
    text_editing = false;
    name_buffer = initName();
    search = @splat(0);
    selected_preset = null;
    selected_layer = 0;
    expanded_color = 0;
    collapsed = @splat(false);
    notice = "";
    color_notice = "";
}

const layers = [_]struct { name: [:0]const u8, prefix: []const u8, element: Element, enabled: *bool }{
    .{ .name = "Lines", .prefix = "wave_lines.", .element = .wave_lines, .enabled = &config.Scene.wave_lines },
    .{ .name = "Bars", .prefix = "wave_bars.", .element = .wave_bars, .enabled = &config.Scene.wave_bars },
    .{ .name = "Spectrum", .prefix = "spectrum.", .element = .spectrum, .enabled = &config.Scene.spectrum },
    .{ .name = "Bubble", .prefix = "bubble.", .element = .bubble, .enabled = &config.Scene.bubble },
    .{ .name = "Halo", .prefix = "halo.", .element = .halo, .enabled = &config.Scene.halo },
};
const V = config.Visualizer;
const Color = struct { name: [:0]const u8, h: *f32, s: *f32, v: *f32, element: Element };
fn color(name: [:0]const u8, vector: *@import("../ext/vector.zig").Vector3, element: Element) Color {
    return .{ .name = name, .h = &vector.x, .s = &vector.y, .v = &vector.z, .element = element };
}
pub const colors = [_]Color{
    color("Lines / Primary", &V.WaveFormLine.color1, .wave_lines),
    color("Lines / Secondary", &V.WaveFormLine.color2, .wave_lines),
    color("Bars / Primary", &V.WaveFormBar.color1, .wave_bars),
    color("Bars / Secondary", &V.WaveFormBar.color2, .wave_bars),
    color("Bars / Trail", &V.WaveFormBar.trail_color, .wave_bars),
    color("Bubble / Primary", &V.Bubble.color1, .bubble),
    color("Bubble / Secondary", &V.Bubble.color2, .bubble),
    .{ .name = "Halo", .h = &V.Halo.hue, .s = &V.Halo.saturation, .v = &V.Halo.brightness, .element = .halo },
    color("Spectrum / Tips", &V.Spectrum.color1, .spectrum),
    color("Spectrum / Body", &V.Spectrum.color2, .spectrum),
};
fn initName() [64]u8 {
    var result: [64]u8 = @splat(0);
    @memcpy(result[0..7], "My look");
    return result;
}
fn visible(view: rl.Rectangle, y: f32, h: f32) bool {
    return y >= view.y and y + h <= view.y + view.height;
}
fn button(view: rl.Rectangle, x: f32, y: f32, width: f32, label: [:0]const u8, selected: bool, enabled: bool) bool {
    return ui.button(ui.rect(x, y, width, 28), label, selected, enabled and visible(view, y, 28));
}
fn textInput(view: rl.Rectangle, y: f32, buffer: []u8) void {
    const bounds = ui.rect(view.x + 4, y, view.width - 8, 28);
    if (!visible(view, y, 28)) {
        text_editing = false;
        return;
    }
    if (ui.textBox(bounds, buffer, text_editing)) text_editing = !text_editing;
    if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT) and !ui.hovered(bounds)) text_editing = false;
}

pub fn presetsHeight() f32 {
    return 164 + @as(f32, @floatFromInt(Presets.store.len)) * 36;
}
pub fn drawPresets(scene: *Scene, view: rl.Rectangle, scroll: f32) void {
    const y = view.y - scroll;
    ui.label("Name your look", view.x + 4, y, 12, ui.muted);
    textInput(view, y + 20, &name_buffer);
    const half = (view.width - 8) / 2;
    if (button(view, view.x, y + 56, half, "Save / replace", false, !Presets.load_failed)) {
        const item = Presets.Preset.capture(scene, std.mem.sliceTo(&name_buffer, 0)) catch {
            notice = "Enter a name; scene file must still exist.";
            return;
        };
        selected_preset = Presets.savePreset(item, true) catch {
            notice = "Save failed. Check library space and permissions.";
            return;
        };
        notice = if (Presets.persistent()) "Saved to your preset library." else "Saved for this session.";
    }
    if (button(view, view.x + half + 8, y + 56, half, "Duplicate", false, selected_preset != null and !Presets.load_failed)) {
        var item = Presets.store.items[selected_preset.?];
        const typed = std.mem.trim(u8, std.mem.sliceTo(&name_buffer, 0), " \t\r\n");
        if (typed.len == 0) {
            notice = "Enter a name for the duplicate.";
            return;
        }
        if (std.mem.eql(u8, typed, item.name())) {
            var unique = false;
            for (1..100) |i| {
                var buffer: [64]u8 = @splat(0);
                const label = std.fmt.bufPrintZ(&buffer, "{s:.40} copy {d}", .{ item.name(), i }) catch unreachable;
                var exists = false;
                for (Presets.store.items[0..Presets.store.len]) |*other| if (std.mem.eql(u8, other.name(), label)) {
                    exists = true;
                };
                if (!exists) {
                    item.name_buffer = buffer;
                    unique = true;
                    break;
                }
            }
            if (!unique) {
                notice = "Choose a different name.";
                return;
            }
        } else {
            item.name_buffer = @splat(0);
            @memcpy(item.name_buffer[0..typed.len], typed);
        }
        selected_preset = Presets.savePreset(item, false) catch {
            notice = "Name exists, library full, or save failed.";
            return;
        };
        name_buffer = item.name_buffer;
        notice = "Duplicated. Click its name below to load.";
    }
    ui.label(if (Presets.load_failed) "Library unreadable; existing file kept." else if (notice.len > 0) notice else if (Presets.persistent()) "Click a saved look to load it." else "Session library (preferences unavailable).", view.x + 4, y + 94, 11, ui.muted);
    ui.label("Visuals and scene parameters; no device settings", view.x + 4, y + 114, 11, ui.muted);
    if (Presets.store.len == 0) ui.label("No saved looks yet.", view.x + 4, y + 142, 14, ui.muted);
    for (Presets.store.items[0..Presets.store.len], 0..) |*item, i| {
        const row_y = y + 140 + @as(f32, @floatFromInt(i)) * 36;
        if (button(view, view.x, row_y, view.width, item.name(), selected_preset == i, true)) {
            item.apply(scene) catch {
                notice = "Scene unavailable. Current look kept.";
                return;
            };
            selected_preset = i;
            name_buffer = item.name_buffer;
            notice = "Loaded. Undo history starts with this look.";
            text_editing = false;
            Highlight.solo = null;
        }
    }
}

const expanded_height: f32 = 3 * geometry.row_height + 62;
pub fn colorHeight() f32 {
    return 28 + colors.len * 38 + (if (expanded_color != null) expanded_height else 0);
}
pub fn colorElementAt(view: rl.Rectangle, scroll: f32, mouse: rl.Vector2, dragging: ?usize) ?Element {
    if (dragging) |id| {
        if (id >= 100 and id < 100 + colors.len * 3) return colors[(id - 100) / 3].element;
        return null;
    }
    if (!rl.CheckCollisionPointRec(mouse, view)) return null;
    var y = view.y - scroll + 28;
    for (colors, 0..) |entry, i| {
        const h: f32 = 38 + (if (expanded_color == i) expanded_height else 0);
        if (rl.CheckCollisionPointRec(mouse, ui.rect(view.x, y, view.width, h))) return entry.element;
        y += h;
    }
    return null;
}
pub fn drawColors(scene: *Scene, view: rl.Rectangle, scroll: f32, field: anytype) void {
    var y = view.y - scroll;
    ui.label("Expand a color to edit hue, saturation and brightness", view.x + 4, y + 4, 10, ui.muted);
    y += 28;
    for (colors, 0..) |entry, i| {
        ui.rounded(ui.rect(view.x + 4, y + 4, 22, 22), 4, rl.ColorFromHSV(entry.h.*, entry.s.*, entry.v.*));
        if (button(view, view.x + 32, y, view.width - 32, entry.name, expanded_color == i, true)) expanded_color = if (expanded_color == i) null else i;
        y += 38;
        if (expanded_color != i) continue;
        const pointers = [_]*f32{ entry.h, entry.s, entry.v };
        for (pointers, [_][:0]const u8{ "Hue", "Saturation", "Brightness" }, 0..) |pointer, label, j| {
            field(100 + i * 3 + j, label, pointer, .{ 0, if (j == 0) 359 else 1 }, view, y, j == 0);
            y += geometry.row_height;
        }
        ui.label("Swatches: click to apply, right-click to save", view.x + 4, y + 2, 11, ui.muted);
        const size = (view.width - 8 * 4) / 8;
        for (Presets.store.swatches, 0..) |swatch, j| {
            const bounds = ui.rect(view.x + 4 + @as(f32, @floatFromInt(j)) * (size + 4), y + 22, size, 26);
            ui.rounded(bounds, 4, rl.ColorFromHSV(swatch[0], swatch[1], swatch[2]));
            if (!visible(view, bounds.y, bounds.height) or !ui.hovered(bounds)) continue;
            ui.requestCursor(rl.MOUSE_CURSOR_POINTING_HAND);
            if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_RIGHT)) {
                color_notice = "Swatch saved.";
                Presets.saveSwatch(j, .{ entry.h.*, entry.s.*, entry.v.* }) catch {
                    color_notice = "Could not save swatch; previous color kept.";
                };
            } else if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
                for (pointers, swatch) |pointer, value| if (!State.locked(pointer, scene)) {
                    pointer.* = value;
                };
            }
        }
        ui.label(color_notice, view.x + 4, y + 50, 10, ui.muted);
        y += 62;
    }
}

fn category(entry: settings.Setting) usize {
    if (std.mem.startsWith(u8, entry.name, "motion.") or std.mem.startsWith(u8, entry.name, "audio.")) return 2;
    if (std.mem.indexOf(u8, entry.name, "color") != null or std.mem.startsWith(u8, entry.name, "halo.hue") or std.mem.startsWith(u8, entry.name, "halo.saturation") or std.mem.startsWith(u8, entry.name, "halo.brightness")) return 1;
    return 0;
}
fn friendly(entry: settings.Setting, buffer: *[96]u8) [:0]const u8 {
    const groups = .{ &V.WaveFormLine.Scalars, &V.WaveFormBar.Scalars, &V.Bubble.Scalars, &V.Halo.Scalars, &V.Spectrum.Scalars, &config.Motion.Scalars, &config.Audio.Scalars };
    inline for (groups) |group| for (group) |scalar| if (entry.target == .scalar and entry.target.scalar == scalar[1]) {
        return std.fmt.bufPrintZ(buffer, "{s}", .{scalar[0]}) catch unreachable;
    };
    for (colors) |entry_color| {
        for ([_]*f32{ entry_color.h, entry_color.s, entry_color.v }, [_][]const u8{ "hue", "saturation", "brightness" }) |pointer, suffix| {
            if (entry.target == .scalar and entry.target.scalar == pointer) {
                const name = if (std.mem.indexOf(u8, entry_color.name, " / ")) |split| entry_color.name[split + 3 ..] else entry_color.name;
                return std.fmt.bufPrintZ(buffer, "{s} {s}", .{ name, suffix }) catch unreachable;
            }
        }
    }
    return std.fmt.bufPrintZ(buffer, "{s}", .{entry.name}) catch unreachable;
}
fn matches(entry: settings.Setting, group: usize) bool {
    if (entry.target != .scalar or !entry.visual() or category(entry) != group) return false;
    if (group != 2 and !std.mem.startsWith(u8, entry.name, layers[selected_layer].prefix)) return false;
    var buffer: [96]u8 = undefined;
    const query = std.mem.sliceTo(&search, 0);
    return query.len == 0 or std.ascii.indexOfIgnoreCase(entry.name, query) != null or std.ascii.indexOfIgnoreCase(friendly(entry, &buffer), query) != null;
}
pub fn inspectorHeight() f32 {
    var height: f32 = 160;
    for (0..3) |group| {
        height += 34;
        if (collapsed[group] and search[0] == 0) continue;
        for (settings.entries) |entry| if (matches(entry, group)) {
            height += geometry.row_height;
        };
    }
    return height + 24;
}
pub fn inspectorElement() Element {
    return layers[selected_layer].element;
}
pub fn selectLayer(element: Element) void {
    for (layers, 0..) |layer, i| if (layer.element == element) {
        selected_layer = i;
    };
    search = @splat(0);
}
pub fn drawInspector(scene: *Scene, view: rl.Rectangle, scroll: f32, field: anytype) void {
    var y = view.y - scroll;
    ui.label("Search controls", view.x + 4, y, 11, ui.muted);
    textInput(view, y + 18, &search);
    const third = (view.width - 12) / 3;
    for (layers, 0..) |layer, i| {
        if (button(view, view.x + @as(f32, @floatFromInt(i % 3)) * (third + 6), y + 54 + @as(f32, @floatFromInt(i / 3)) * 32, third, layer.name, selected_layer == i, true)) selected_layer = i;
    }
    const layer = layers[selected_layer];
    const owned = blk: {
        for (settings.entries, scene.owned) |entry, owns| if (entry.target == .boolean and entry.target.boolean == layer.enabled) break :blk owns;
        break :blk false;
    };
    if (button(view, view.x, y + 122, third, if (owned) "Lua owns" else if (layer.enabled.*) "Visible" else "Hidden", layer.enabled.*, !owned)) layer.enabled.* = !layer.enabled.*;
    if (button(view, view.x + third + 6, y + 122, third, "Solo", Highlight.solo == layer.element, scene.usesBuiltin())) Highlight.solo = if (Highlight.solo == layer.element) null else layer.element;
    if (button(view, view.x + 2 * (third + 6), y + 122, third, "Reset layer", false, true)) State.resetPrefix(layer.prefix, scene);
    y += 160;
    var count: usize = 0;
    for ([_][:0]const u8{ "Shape", "Color", "Global response" }, 0..) |label, group| {
        if (button(view, view.x, y, view.width - 62, label, !collapsed[group] or search[0] != 0, true)) collapsed[group] = !collapsed[group];
        if (button(view, view.x + view.width - 60, y, 60, "Reset", false, true)) {
            for (settings.entries, 0..) |entry, i| if (matches(entry, group) and !scene.owned[i]) entry.set(State.defaults[i]);
        }
        y += 34;
        if (collapsed[group] and search[0] == 0) continue;
        for (settings.entries, 0..) |entry, i| {
            if (!matches(entry, group)) continue;
            var buffer: [96]u8 = undefined;
            field(5000 + i, friendly(entry, &buffer), entry.target.scalar, .{ @floatCast(entry.min), @floatCast(entry.max) }, view, y, false);
            y += geometry.row_height;
            count += 1;
        }
    }
    if (count == 0) ui.label("No matching controls. Try another search.", view.x + 4, y + 4, 12, ui.muted);
}
