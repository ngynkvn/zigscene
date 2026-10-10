//! Built-in starting points stay separate from the user's preset library.
const std = @import("std");
const Presets = @import("Presets.zig");
const State = @import("State.zig");
const settings = @import("../scripting/settings.zig");

pub const Kind = enum { calm, pulse, sculpture };
pub const descriptions = [_][:0]const u8{ "A quiet halo and a soft spectrum", "Violet waves with a trailing glow", "A warm, slowly turning sculpture" };
pub const names = [_][:0]const u8{ "Calm", "Pulse", "Sculpture" };

fn set(look: *Presets.Preset, name: []const u8, value: f64) void {
    look.values[settings.find(name) orelse unreachable] = value;
}
fn hsv(look: *Presets.Preset, comptime prefix: []const u8, h: f64, s: f64, v: f64) void {
    set(look, prefix ++ ".h", h);
    set(look, prefix ++ ".s", s);
    set(look, prefix ++ ".v", v);
}

pub fn preset(kind: Kind) Presets.Preset {
    var result: Presets.Preset = .{ .values = State.defaults };
    const name = names[@intFromEnum(kind)];
    @memcpy(result.name_buffer[0..name.len], name);
    for ([_][]const u8{ "scene.wave_lines", "scene.wave_bars", "scene.spectrum", "scene.bubble", "scene.halo" }) |key| set(&result, key, 0);
    set(&result, "shader.chroma_factor", 0);
    set(&result, "shader.noise_factor", 0);
    switch (kind) {
        .calm => {
            set(&result, "scene.halo", 1);
            set(&result, "scene.spectrum", 1);
            set(&result, "halo.radius", 115);
            set(&result, "halo.depth", 45);
            set(&result, "halo.spin", 0.06);
            set(&result, "halo.hue", 185);
            set(&result, "halo.saturation", 0.45);
            set(&result, "halo.brightness", 0.85);
            set(&result, "spectrum.height", 90);
            hsv(&result, "spectrum.color1", 185, 0.35, 0.85);
            hsv(&result, "spectrum.color2", 210, 0.55, 0.4);
        },
        .pulse => {
            set(&result, "scene.wave_lines", 1);
            set(&result, "scene.wave_bars", 1);
            set(&result, "wave_lines.amplitude", 45);
            set(&result, "wave_bars.base_h", 3);
            set(&result, "wave_bars.amplitude", 65);
            hsv(&result, "wave_lines.color1", 270, 0.3, 0.9);
            hsv(&result, "wave_lines.color2", 310, 0.5, 0.85);
            hsv(&result, "wave_bars.color1", 270, 0.6, 0.7);
            hsv(&result, "wave_bars.color2", 290, 0.45, 0.85);
            hsv(&result, "wave_bars.trail_color", 260, 0.45, 0.3);
        },
        .sculpture => {
            set(&result, "scene.bubble", 1);
            set(&result, "bubble.ring_radius", 3.1);
            set(&result, "bubble.sphere_radius", 2.3);
            set(&result, "bubble.effect", 0.25);
            set(&result, "bubble.color_scale", 4);
            set(&result, "bubble.bubble_color_scale", 4);
            hsv(&result, "bubble.color1", 35, 0.35, 0.9);
            hsv(&result, "bubble.color2", 185, 0.35, 0.7);
        },
    }
    return result;
}

test "starter looks stay valid and do not overwrite machine settings" {
    State.initDefaults();
    var scene: @import("../scripting/Scene.zig") = .{};
    defer scene.deinit();
    const snapshot = settings.snapshot();
    defer for (settings.entries, snapshot) |entry, old| entry.set(old.value);
    const config = @import("../core/config.zig");
    config.Audio.volume = 0.123;
    inline for (std.meta.tags(Kind)) |kind| {
        const look = preset(kind);
        for (settings.entries, look.values) |entry, value| {
            try std.testing.expect(value >= entry.min and value <= entry.max);
        }
        try look.apply(&scene);
        try std.testing.expectEqual(@as(f32, 0.123), config.Audio.volume);
        var layers: usize = 0;
        for (settings.entries) |entry| if (std.mem.startsWith(u8, entry.name, "scene.") and entry.get() != 0) {
            layers += 1;
        };
        try std.testing.expect(layers >= 1 and layers <= 2);
    }
}
