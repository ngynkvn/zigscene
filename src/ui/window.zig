const std = @import("std");

const rl = @import("raylibz");

pub const Window = struct {
    bounds: rl.Rectangle,
    title: []const u8,
    dragging: DragState = .None,
    drag_start: ?rl.Vector2 = null,
    visible: bool = true,
    resize_target: bool = false,
    drag_target: bool = false,

    const DragState = enum {
        None,
        Dragging,
        Resizing,
    };

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

        const mouse_pos = rl.getMousePosition();
        const title_bar = rl.Rectangle{
            .x = self.bounds.x,
            .y = self.bounds.y,
            .width = self.bounds.width,
            .height = 30,
        };
        if (rl.checkCollisionPointRec(mouse_pos, self.bounds)) {
            rl.drawRectangleLines(
                @intFromFloat(self.bounds.x - 1),
                @intFromFloat(self.bounds.y - 1),
                @intFromFloat(self.bounds.width + 2),
                @intFromFloat(self.bounds.height + 2),
                rl.RED,
            );
        }

        if (rl.checkCollisionPointRec(mouse_pos, title_bar)) {
            if (!self.drag_target) {
                rl.setMouseCursor(rl.MouseCursor.pointing_hand);
            }
            self.drag_target = true;
            if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
                self.dragging = .Dragging;
                self.drag_start = mouse_pos;
            }
        } else {
            if (self.drag_target) {
                rl.setMouseCursor(rl.MouseCursor.default);
            }
            self.drag_target = false;
        }

        // Check if mouse is on corner of window
        const corner = rl.Rectangle{
            .x = self.bounds.x + self.bounds.width - 20,
            .y = self.bounds.y + self.bounds.height - 20,
            .width = 20,
            .height = 20,
        };
        if (rl.checkCollisionPointRec(mouse_pos, corner)) {
            if (!self.resize_target) {
                rl.setMouseCursor(rl.MouseCursor.resize_nwse);
            }
            self.resize_target = true;
            if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
                self.dragging = .Resizing;
                self.drag_start = mouse_pos;
            }
        } else {
            if (self.resize_target) {
                rl.setMouseCursor(rl.MouseCursor.default);
            }
            self.resize_target = false;
        }

        if (rl.isMouseButtonReleased(rl.MouseButton.left)) {
            self.dragging = .None;
            self.drag_start = null;
        }

        switch (self.dragging) {
            .Resizing => {
                const delta = rl.getMouseDelta();
                self.bounds.width += delta.x;
                self.bounds.height += delta.y;
            },
            .Dragging => {
                const delta = rl.getMouseDelta();
                self.bounds.x += delta.x;
                self.bounds.y += delta.y;
            },
            .None => {},
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
        if (rl.guiWindowBox(self.bounds, self.title.ptr) == 0) {
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
