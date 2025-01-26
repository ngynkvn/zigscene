const rl = @import("../raylib.zig");

pub const Rectangle = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,
    pub fn from(x: f32, y: f32, width: f32, height: f32) Rectangle {
        return .{ .x = x, .y = y, .width = width, .height = height };
    }
    pub const Modifier = struct {
        width: ?f32 = null,
        height: ?f32 = null,
        x: ?f32 = null,
        y: ?f32 = null,
    };
    pub fn with(self: Rectangle, mod: Modifier) Rectangle {
        return .{
            .x = mod.x orelse self.x,
            .y = mod.y orelse self.y,
            .width = mod.width orelse self.width,
            .height = mod.height orelse self.height,
        };
    }
    pub fn resize(self: Rectangle, width: f32, height: f32) Rectangle {
        return .{ .x = self.x, .y = self.y, .width = width, .height = height };
    }
    pub fn translate(self: Rectangle, dx: f32, dy: f32) Rectangle {
        return .{ .x = self.x + dx, .y = self.y + dy, .width = self.width, .height = self.height };
    }
};
