// Configurables. These are picked up and set in the UI
pub const Scalar = struct {
    name: []const u8,
    value: *f32,
    range: struct { f32, f32 },
};
pub const Color = struct {
    name: []const u8,
    hue: *f32,
};
