//! Focus follows the enabled controls drawn in the previous frame.
const Focus = @This();
const std = @import("std");
items: [512]u64 = undefined,
len: usize = 0,
selected: ?u64 = null,
visible: bool = false,

pub fn begin(self: *Focus, tab: bool, reverse: bool, mouse: bool) void {
    if (mouse) self.visible = false;
    if (tab and self.len > 0) {
        var current: ?usize = null;
        for (self.items[0..self.len], 0..) |id, i| if (self.selected == id) {
            current = i;
        };
        const next = if (current) |i| (i + self.len + (if (reverse) self.len - 1 else 1)) % self.len else if (reverse) self.len - 1 else 0;
        self.selected = self.items[next];
        self.visible = true;
    }
    self.len = 0;
}
pub fn add(self: *Focus, id: u64, clicked: bool) bool {
    if (self.len < self.items.len) {
        self.items[self.len] = id;
        self.len += 1;
    }
    if (clicked) self.selected = id;
    return self.visible and self.selected == id;
}

pub fn finish(self: *Focus) void {
    for (self.items[0..self.len]) |id| if (self.selected == id) return;
    self.selected = null;
    self.visible = false;
}

test "tab navigation wraps, reverses, and recovers when a control disappears" {
    var focus: Focus = .{};
    _ = focus.add(11, false);
    _ = focus.add(22, false);
    focus.begin(true, false, false);
    try std.testing.expectEqual(@as(?u64, 11), focus.selected);
    _ = focus.add(11, false);
    _ = focus.add(22, false);
    focus.begin(true, true, false);
    try std.testing.expectEqual(@as(?u64, 22), focus.selected);
    _ = focus.add(33, false);
    focus.begin(true, false, false);
    try std.testing.expectEqual(@as(?u64, 33), focus.selected);
    focus.begin(false, false, true);
    try std.testing.expect(!focus.visible);
    _ = focus.add(44, true);
    focus.begin(true, false, false);
    _ = focus.add(55, false);
    focus.finish();
    try std.testing.expectEqual(@as(?u64, null), focus.selected);
    try std.testing.expect(!focus.visible);
}
