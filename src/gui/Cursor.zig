//! Collect widget requests before changing the native cursor once per frame.
const Cursor = @This();
const rl = @import("raylib");

requested: c_int = rl.MOUSE_CURSOR_DEFAULT,
applied: c_int = rl.MOUSE_CURSOR_DEFAULT,

pub fn begin(self: *Cursor) void {
    self.requested = rl.MOUSE_CURSOR_DEFAULT;
}

pub fn request(self: *Cursor, cursor: c_int) void {
    self.requested = cursor;
}

pub fn change(self: *Cursor) ?c_int {
    if (self.requested == self.applied) return null;
    self.applied = self.requested;
    return self.applied;
}

test "hover requests change the native cursor only on entry and exit" {
    const testing = @import("std").testing;
    var cursor: Cursor = .{};
    cursor.begin();
    try testing.expectEqual(null, cursor.change());
    cursor.request(rl.MOUSE_CURSOR_POINTING_HAND);
    try testing.expectEqual(rl.MOUSE_CURSOR_POINTING_HAND, cursor.change().?);
    for (0..120) |_| {
        cursor.begin();
        cursor.request(rl.MOUSE_CURSOR_POINTING_HAND);
        try testing.expectEqual(null, cursor.change());
    }
    cursor.begin();
    try testing.expectEqual(rl.MOUSE_CURSOR_DEFAULT, cursor.change().?);
    cursor.begin();
    try testing.expectEqual(null, cursor.change());
}

test "only the final widget request reaches the native cursor" {
    const testing = @import("std").testing;
    var cursor: Cursor = .{};
    cursor.begin();
    cursor.request(rl.MOUSE_CURSOR_RESIZE_EW);
    cursor.request(rl.MOUSE_CURSOR_POINTING_HAND);
    try testing.expectEqual(rl.MOUSE_CURSOR_POINTING_HAND, cursor.change().?);
    cursor.begin();
    cursor.request(rl.MOUSE_CURSOR_IBEAM);
    cursor.request(rl.MOUSE_CURSOR_POINTING_HAND);
    try testing.expectEqual(null, cursor.change());
}
