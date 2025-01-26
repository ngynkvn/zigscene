const music = @import("../audio/playback.zig");
const graphics = @import("../graphics.zig");
const gui = @import("../gui.zig");
const shader = @import("../shader/shader.zig");
const debug = @import("debug.zig");

const EventHandler = struct {
    fn dispatch(comptime modules: anytype, comptime handler: []const u8, args: anytype) void {
        inline for (modules) |module| {
            if (@hasDecl(module, handler)) {
                @call(.auto, @field(module, handler), args);
            }
        }
    }
};

pub inline fn onFilenameInput(filename: []const u8) void {
    EventHandler.dispatch(.{music}, "onFilenameInput", .{filename});
}

pub inline fn onTabChange(tab: gui.Tab) void {
    EventHandler.dispatch(.{gui}, "onTabChange", .{tab});
}

pub inline fn onWindowResize(width: i32, height: i32) void {
    EventHandler.dispatch(.{ graphics, shader, debug }, "onWindowResize", .{ width, height });
}

pub const Direction = enum { horizontal, vertical };
pub inline fn onSwipe(dir: Direction, amount: f32) void {
    gui.onSwipe(dir, amount);
}
