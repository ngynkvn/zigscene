const std = @import("std");

pub inline fn frameMarkNamed(comptime name: [:0]const u8) void {
    _ = name;
}

pub const struct____tracy_c_zone_context = extern struct {
    pub inline fn end(self: @This()) void {
        _ = self;
    }
};
pub const TracyCZoneCtx = struct____tracy_c_zone_context;

pub inline fn ___tracy_emit_zone_end() void {}

pub inline fn traceNamed(comptime src: std.builtin.SourceLocation, comptime name: [*:0]const u8) TracyCZoneCtx {
    _ = name; // autofix
    _ = src; // autofix
    return .{};
}
