//! Configurables. These are picked up and set in the UI
const std = @import("std");

/// name, value, range
pub const Scalar = struct { []const u8, *f32, struct { f32, f32 } };
pub const ScalarList = struct { name: []const []const u8, value: []f32, range: []struct { f32, f32 } };
pub const Color = struct { []const u8, *f32 };
