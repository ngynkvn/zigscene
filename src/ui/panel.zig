const std = @import("std");
const rl = @import("../raylib.zig");

pub const Panel = struct {
    bounds: rl.Rectangle,
    title: []const u8,
    visible: bool = true,
    content_padding: f32 = 10,

    pub fn init(x: f32, y: f32, width: f32, height: f32, title: []const u8) Panel {
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

    pub fn context(self: *Panel) Context {
        return .{ .root = self };
    }

    pub fn begin(self: *Panel) bool {
        if (!self.visible) return false;
        _ = rl.GuiPanel(self.bounds, self.title.ptr);
        return true;
    }

    pub const Context = struct {
        root: *Panel,
        current_y: f32 = 0,
        current_x: f32 = 0,

        pub fn bounds(self: Context) rl.Rectangle {
            const pad = self.root.content_padding;
            const rt = self.root.bounds;
            return .{
                .x = rt.x + pad,
                .y = rt.y + pad + 24,
                .width = rt.width - (pad * 2),
                .height = rt.height - (pad * 2),
            };
        }

        pub fn nextRow(self: *Context, height: f32) rl.Rectangle {
            const b = self.bounds();
            const result: rl.Rectangle = .{
                .x = b.x + self.current_x,
                .y = b.y + self.current_y,
                .width = b.width,
                .height = height,
            };
            self.current_y += height;
            return result;
        }

        pub fn spacer(self: *Context, amount: f32) void {
            self.current_y += amount;
        }

        pub fn label(self: *Context, text: [*c]const u8) void {
            _ = rl.GuiLabel(self.nextRow(24), text);
        }

        pub fn slider(self: *Context, text: [*c]const u8, value: *f32, min: f32, max: f32) void {
            var row = self.nextRow(16);
            row.width = 120;
            row.x += 60;
            _ = rl.GuiSlider(row, text, "", value, min, max);
        }

        pub fn group(self: *Context) Group {
            return .{ .ctx = self };
        }

        pub const Group = struct {
            ctx: *Context,
            pub fn begin(self: Group, spacing: f32) void {
                self.ctx.current_x += spacing;
            }

            pub fn end(self: Group) void {
                self.ctx.current_x = 0;
                self.ctx.spacer(8);
            }
        };
    };

    pub fn toggle(self: *Panel) void {
        self.visible = !self.visible;
    }
};
