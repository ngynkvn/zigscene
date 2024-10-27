// @floatFromInt shortcut
pub fn ffi(T: type, x: anytype) T {
    return @as(T, @floatFromInt(x));
}
// @intFromFloat shortcut
pub fn iff(T: type, x: anytype) T {
    return @as(T, @intFromFloat(x));
}
