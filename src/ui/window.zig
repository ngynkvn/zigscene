const std = @import("std");
const rl = @import("../raylib.zig");

pub const Window = struct {
    bounds: rl.Rectangle,
    title: []const u8,
    dragging: bool = false,
    drag_start: ?rl.Vector2 = null,
    visible: bool = true,

    pub fn init(x: f32, y: f32, width: f32, height: f32, title: []const u8) Window {
        return .{
            .bounds = .{
                .x = x,
                .y = y,
                .width = width,
                .height = height,
            },
            .title = title,
        };
    }

    pub fn update(self: *Window) void {
        if (!self.visible) return;

        const mouse_pos = rl.GetMousePosition();
        const title_bar = rl.Rectangle{
            .x = self.bounds.x,
            .y = self.bounds.y,
            .width = self.bounds.width,
            .height = 30,
        };

        if (rl.IsMouseButtonPressed(rl.MOUSE_LEFT_BUTTON) and
            rl.CheckCollisionPointRec(mouse_pos, title_bar))
        {
            self.dragging = true;
            self.drag_start = mouse_pos;
        }

        if (rl.IsMouseButtonReleased(rl.MOUSE_LEFT_BUTTON)) {
            self.dragging = false;
            self.drag_start = null;
        }

        if (self.dragging) {
            const delta = rl.GetMouseDelta();
            self.bounds.x += delta.x;
            self.bounds.y += delta.y;
        }
    }

    pub fn context(self: *Window) Context {
        return .{ .root = self };
    }

    pub const Context = struct {
        root: *Window,
        pub fn bounds(self: Context) rl.Rectangle {
            const rt = self.root.bounds;
            return .{
                .x = rt.x + 10,
                .y = rt.y + 30,
                .width = rt.width - 20,
                .height = rt.height - 40,
            };
        }
    };

    pub fn begin(self: *Window) ?Context {
        if (!self.visible) return null;
        self.update();
        if (rl.GuiWindowBox(self.bounds, self.title.ptr) == 0) {
            return self.context();
        } else {
            self.visible = !self.visible;
            return null;
        }
    }

    pub fn toggle(self: *Window) void {
        self.visible = !self.visible;
    }
};
