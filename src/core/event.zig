const deque = @import("../deque.zig");
const Deque = deque.Deque;
const gui = @import("../gui.zig");
const apprt = @import("apprt.zig");

pub const Event = union(enum) {
    filename_input: []const u8,
    tab_change: gui.Tab,
    toggle_capture,
    window_resize: struct {
        width: i32,
        height: i32,
    },
    swipe: struct {
        direction: enum { horizontal, vertical },
        amount: f32,
    },
};

pub fn emit(app: *apprt.App, event: Event) !void {
    try app.events.pushBack(app.allocator, event);
}
