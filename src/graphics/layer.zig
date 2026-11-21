//! Identity of the built-in scene layers. The layer list, inspector and hover
//! emphasis are all derived from this enum, so a new layer's name, toggle and
//! settings prefix are declared once here rather than in each of them.
const std = @import("std");
const Config = @import("../core/config.zig");

pub const Layer = enum {
    wave_lines,
    wave_bars,
    spectrum,
    bubble,
    halo,
    marbling,

    pub const all = std.enums.values(Layer);

    /// When set, only this layer is drawn. Never saved.
    pub var solo: ?Layer = null;

    pub const Info = struct {
        /// Layer list card.
        title: [:0]const u8,
        summary: [:0]const u8,
        /// Compact label for the inspector's layer picker.
        short: [:0]const u8,
    };

    pub fn info(self: Layer) Info {
        return switch (self) {
            .wave_lines => .{ .title = "Waveform lines", .summary = "The outline of your audio", .short = "Lines" },
            .wave_bars => .{ .title = "Waveform bars", .summary = "Rhythm with a trailing glow", .short = "Bars" },
            .spectrum => .{ .title = "Spectrum", .summary = "Sound across the frequencies", .short = "Spectrum" },
            .bubble => .{ .title = "3D bubble", .summary = "A sculptural, reactive core", .short = "Bubble" },
            .halo => .{ .title = "Frequency halo", .summary = "A ring of spectral energy", .short = "Halo" },
            .marbling => .{ .title = "Marbling", .summary = "Flowing ink, dots, and grain", .short = "Marbling" },
        };
    }

    /// The user's visibility toggle. Most are `Config.Scene.<tag>`, saved as
    /// `scene.<tag>`; the setting names are stable, so exceptions stay as they are.
    pub fn enabled(self: Layer) *bool {
        return switch (self) {
            .marbling => &Config.Marbling.enabled,
            inline else => |tag| &@field(Config.Scene, @tagName(tag)),
        };
    }

    /// Prefix of the layer's own settings, e.g. `halo.` in `halo.radius`.
    pub fn prefix(self: Layer) []const u8 {
        return switch (self) {
            inline else => |tag| @tagName(tag) ++ ".",
        };
    }

    pub fn visible(self: Layer) bool {
        if (solo != null and solo != self) return false;
        return self.enabled().*;
    }
};

test "each layer has a registered toggle and settings under its prefix" {
    const settings = @import("../scripting/settings.zig");
    for (Layer.all, 0..) |layer, i| {
        // Scripts, presets and preferences reach the toggle through the registry.
        var registered = false;
        var tunable = false;
        for (settings.entries) |entry| {
            registered = registered or (entry.target == .boolean and entry.target.boolean == layer.enabled());
            tunable = tunable or std.mem.startsWith(u8, entry.name, layer.prefix());
        }
        try std.testing.expect(registered and tunable);
        for (Layer.all[i + 1 ..]) |other| try std.testing.expect(layer.enabled() != other.enabled());
    }
}

test "solo hides every other layer without changing saved visibility" {
    const before = Layer.solo;
    defer Layer.solo = before;
    const Scene = Config.Scene;
    const original = Scene.halo;
    defer Scene.halo = original;
    Scene.halo = true;
    Layer.solo = .halo;
    for (Layer.all) |layer| try std.testing.expectEqual(layer == .halo, layer.visible());
    try std.testing.expect(Scene.halo);
    Layer.solo = null;
    Scene.halo = false;
    try std.testing.expect(!Layer.halo.visible());
}
