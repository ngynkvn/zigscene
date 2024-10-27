//! Configurables. These are picked up and set in the UI

/// name, value, range
pub const Scalar = struct { []const u8, *f32, struct { f32, f32 } };
pub const Color = struct { []const u8, *f32 };
