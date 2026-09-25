//! Stable Lua names for host settings. All writes are validated in the C bridge.
const Config = @import("../core/config.zig");
pub const c = @cImport({
    @cInclude("lua_scene.h");
});
const Target = union(enum) { scalar: *f32, boolean: *bool };
pub const Setting = struct {
    name: [:0]const u8,
    target: Target,
    min: f64 = 0,
    max: f64 = 1,

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
const V = Config.Visualizer;
pub const entries = [_]Setting{
    boolean("window.always_on_top", &Config.Window.always_on_top),
    scalar("window.fps_limit", &Config.Window.fps_limit, 0, 360),
    scalar("window.opacity", &Config.Window.opacity, 0.15, 1),
    scalar("interface.scale_percent", &Config.Interface.scale_percent, 75, 150),
    scalar("interface.panel_width", &Config.Interface.panel_width, 240, 2000),
    scalar("interface.panel_height", &Config.Interface.panel_height, 0, 2000),
    boolean("interface.show_fps", &Config.Interface.show_fps),
    scalar("audio.volume", &Config.Audio.volume, 0, 1),
    scalar("audio.wave_blend", &Config.Audio.wave_blend, 0, 0.98),
    scalar("audio.wave_gain", &Config.Audio.wave_gain, 0.1, 3),
    scalar("motion.energy_gain", &Config.Motion.energy_gain, 0.2, 6),
    scalar("motion.compression", &Config.Motion.compression, 0, 8),
    scalar("motion.attack_seconds", &Config.Motion.attack_seconds, 0.01, 0.5),
    scalar("motion.release_seconds", &Config.Motion.release_seconds, 0.03, 1.5),
    scalar("motion.beat_decay_seconds", &Config.Motion.beat_decay_seconds, 0.05, 1),
    boolean("scene.wave_lines", &Config.Scene.wave_lines),
    boolean("scene.wave_bars", &Config.Scene.wave_bars),
    boolean("scene.spectrum", &Config.Scene.spectrum),
    boolean("scene.bubble", &Config.Scene.bubble),
    boolean("scene.halo", &Config.Scene.halo),
    scalar("shader.chroma_factor", &Config.Shader.chroma_factor, 0, 0.01),
    scalar("shader.noise_factor", &Config.Shader.noise_factor, 0, 0.5),
    scalar("shader.alpha_factor", &Config.Shader.alpha_factor, 0, 1),
    scalar("wave_lines.amplitude", &V.WaveFormLine.amplitude, 0, 100),
    scalar("wave_bars.amplitude", &V.WaveFormBar.amplitude, 0, 100),
    scalar("wave_bars.base_h", &V.WaveFormBar.base_h, 0, 100),
    scalar("wave_bars.trail_decay", &V.WaveFormBar.trail_decay, 0.05, 2),
    scalar("spectrum.gain", &V.Spectrum.gain, 0.2, 10),
    scalar("spectrum.height", &V.Spectrum.height, 20, 300),
    scalar("halo.radius", &V.Halo.radius, 40, 260),
    scalar("halo.depth", &V.Halo.depth, 0, 220),
    scalar("halo.spin", &V.Halo.spin, -1, 1),
    scalar("halo.hue", &V.Halo.hue, 0, 359),
    scalar("bubble.ring_radius", &V.Bubble.ring_radius, 0.1, 8),
    scalar("bubble.sphere_radius", &V.Bubble.sphere_radius, 0.1, 4),
    scalar("bubble.effect", &V.Bubble.effect, 0.1, 1),
    scalar("bubble.color_scale", &V.Bubble.color_scale, 0, 100),
    scalar("bubble.bubble_color_scale", &V.Bubble.bubble_color_scale, 0, 100),
    scalar("bubble.height_ring", &V.Bubble.height_ring, 0, 1),
} ++ hsv("wave_lines.color1", &V.WaveFormLine.color1) ++ hsv("wave_lines.color2", &V.WaveFormLine.color2) ++
    hsv("wave_bars.color1", &V.WaveFormBar.color1) ++ hsv("wave_bars.color2", &V.WaveFormBar.color2) ++ hsv("wave_bars.trail_color", &V.WaveFormBar.trail_color) ++
    hsv("bubble.color1", &V.Bubble.color1) ++ hsv("bubble.color2", &V.Bubble.color2);

pub fn snapshot() [entries.len]c.ZsSetting {
    var result: [entries.len]c.ZsSetting = undefined;
    for (entries, &result) |entry, *out| out.* = .{ .name = entry.name.ptr, .value = entry.get(), .min = entry.min, .max = entry.max, .boolean = @intFromBool(entry.target == .boolean) };
    return result;
}
