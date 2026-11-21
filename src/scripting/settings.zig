//! Stable Lua names for host settings. All writes are validated in the C bridge.
const std = @import("std");
const Config = @import("../core/config.zig");
pub const c = @import("lua-scene");
pub const Target = union(enum) { scalar: *f32, boolean: *bool };
pub const Setting = struct {
    name: [:0]const u8,
    /// Control label, for settings that have a slider.
    label: ?[:0]const u8 = null,
    target: Target,
    min: f64 = 0,
    max: f64 = 1,

    pub fn visual(self: Setting) bool {
        return !std.mem.startsWith(u8, self.name, "window.") and
            !std.mem.startsWith(u8, self.name, "interface.") and
            !std.mem.eql(u8, self.name, "audio.volume");
    }

    pub fn get(self: Setting) f64 {
        return switch (self.target) {
            .scalar => |p| p.*,
            .boolean => |p| if (p.*) 1 else 0,
        };
    }
    pub fn set(self: Setting, value: f64) void {
        switch (self.target) {
            .scalar => |p| p.* = @floatCast(value),
            .boolean => |p| p.* = value != 0,
        }
    }
};
fn scalar(name: [:0]const u8, target: *f32, min: f64, max: f64) Setting {
    return .{ .name = name, .target = .{ .scalar = target }, .min = min, .max = max };
}
fn boolean(name: [:0]const u8, target: *bool) Setting {
    return .{ .name = name, .target = .{ .boolean = target } };
}
fn hsv(comptime name: [:0]const u8, value: *@import("../ext/vector.zig").Vector3) [3]Setting {
    return .{ scalar(name ++ ".h", &value.x, 0, 359), scalar(name ++ ".s", &value.y, 0, 1), scalar(name ++ ".v", &value.z, 0, 1) };
}
/// One setting per slider a config group declares, named `<prefix>.<variable>`
/// with the slider's label and range, so those are written once.
fn sliders(comptime prefix: []const u8, comptime Group: type) [Group.Scalars.len]Setting {
    var result: [Group.Scalars.len]Setting = undefined;
    for (Group.Scalars, &result) |control, *out| {
        const label, const value, const range = control;
        out.* = .{ .name = prefix ++ "." ++ variable(Group, value), .label = label, .target = .{ .scalar = value }, .min = range[0], .max = range[1] };
    }
    return result;
}
fn variable(comptime Group: type, comptime value: *f32) [:0]const u8 {
    for (std.meta.declarations(Group)) |name| {
        if (@TypeOf(@field(Group, name)) == f32 and &@field(Group, name) == value) return name;
    }
    @compileError("a slider in " ++ @typeName(Group) ++ " edits a variable of another group");
}
const V = Config.Visualizer;
pub const entries = [_]Setting{
    boolean("window.always_on_top", &Config.Window.always_on_top),
    scalar("interface.scale_percent", &Config.Interface.scale_percent, 75, 150),
    scalar("interface.panel_width", &Config.Interface.panel_width, 240, 2000),
    scalar("interface.panel_height", &Config.Interface.panel_height, 0, 2000),
    boolean("interface.show_fps", &Config.Interface.show_fps),
    boolean("interface.show_player", &Config.Interface.show_player),
    boolean("scene.wave_lines", &Config.Scene.wave_lines),
    boolean("scene.wave_bars", &Config.Scene.wave_bars),
    boolean("scene.spectrum", &Config.Scene.spectrum),
    boolean("scene.bubble", &Config.Scene.bubble),
    boolean("scene.halo", &Config.Scene.halo),
    boolean("marbling.enabled", &Config.Marbling.enabled),
    scalar("halo.hue", &V.Halo.hue, 0, 359),
    scalar("halo.saturation", &V.Halo.saturation, 0, 1),
    scalar("halo.brightness", &V.Halo.brightness, 0, 1),
} ++ sliders("window", Config.Window) ++ sliders("audio", Config.Audio) ++ sliders("motion", Config.Motion) ++ sliders("shader", Config.Shader) ++
    sliders("marbling", Config.Marbling) ++ sliders("wave_lines", V.WaveFormLine) ++ sliders("wave_bars", V.WaveFormBar) ++ sliders("spectrum", V.Spectrum) ++
    sliders("halo", V.Halo) ++ sliders("bubble", V.Bubble) ++ hsv("spectrum.color1", &V.Spectrum.color1) ++ hsv("spectrum.color2", &V.Spectrum.color2) ++ hsv("wave_lines.color1", &V.WaveFormLine.color1) ++ hsv("wave_lines.color2", &V.WaveFormLine.color2) ++
    hsv("wave_bars.color1", &V.WaveFormBar.color1) ++ hsv("wave_bars.color2", &V.WaveFormBar.color2) ++ hsv("wave_bars.trail_color", &V.WaveFormBar.trail_color) ++
    hsv("bubble.color1", &V.Bubble.color1) ++ hsv("bubble.color2", &V.Bubble.color2);

pub fn snapshot() [entries.len]c.ZsSetting {
    var result: [entries.len]c.ZsSetting = undefined;
    for (entries, &result) |entry, *out| out.* = .{ .name = entry.name.ptr, .value = entry.get(), .min = entry.min, .max = entry.max, .boolean = @intFromBool(entry.target == .boolean) };
    return result;
}

pub fn indexOf(pointer: *f32) ?usize {
    for (entries, 0..) |entry, i| if (entry.target == .scalar and entry.target.scalar == pointer) return i;
    return null;
}

pub fn find(name: []const u8) ?usize {
    for (entries, 0..) |entry, i| if (std.mem.eql(u8, entry.name, name)) return i;
    return null;
}
