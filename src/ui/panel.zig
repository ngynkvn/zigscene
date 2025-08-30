const std = @import("std");
const rl = @import("raylibz");

pub const Panel = struct {
    bounds: rl.Rectangle,
    title: []const u8,
    visible: bool = true,
    content_padding: f32 = 8,
    pub const ROW_HEIGHT: f32 = 24;
    pub const PADDING: f32 = 8;

    pub fn init(x: f32, y: f32, width: f32, height: f32, title: []const u8) Panel {
        return .{
            .bounds = .{ .x = x, .y = y, .width = width, .height = height },
            .title = title,
        };
    }

    pub fn context(self: Panel) Context {
        return .{ .root = self };
    }

    pub fn begin(self: Panel) ?Panel {
        if (!self.visible) return null;
        _ = rl.guiPanel(self.bounds, self.title.ptr);
        return self;
    }

    pub const Context = struct {
        root: Panel,
        offset_x: f32 = 0,
        offset_y: f32 = 0,

        pub fn bounds(self: Context) rl.Rectangle {
            const pad = self.root.content_padding;
            const rt = self.root.bounds;
            return .{
                .x = rt.x + pad + self.offset_x,
                .y = rt.y + pad + self.offset_y,
                .width = rt.width - (pad * 2),
                .height = rt.height - (pad * 2),
            };
        }

        pub fn label(_: *Context, text: [*c]const u8, label_bounds: rl.Rectangle) void {
            _ = rl.guiLabel(label_bounds, text);
        }

        const SliderOptions = struct {
            bounds: rl.Rectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0 },
            min: f32,
            max: f32,
            valueBox: bool = true,
            editing: bool = false,
        };
        pub fn slider(_: *const Context, value: *f32, so: SliderOptions) void {
            const VALUE_BOX_WIDTH: f32 = 48;
            var b = so.bounds;
            b.width -= VALUE_BOX_WIDTH;
            _ = rl.guiSlider(b, "", null, value, so.min, so.max);
            if (so.valueBox) {
                const adj = rl.Rectangle{
                    .x = b.x + b.width + 8,
                    .y = so.bounds.y,
                    .width = VALUE_BOX_WIDTH,
                    .height = ROW_HEIGHT,
                };
                const buf = std.fmt.bufPrintZ(&value_buffer, tunable_fmt, .{value.*}) catch unreachable;
                _ = rl.guiValueBoxFloat(adj, "", buf.ptr, value, so.editing);
            }
        }
        const ColorPickerOptions = struct {
            bounds: rl.Rectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0 },
        };
        pub fn colorPicker(_: *const Context, value: *f32, cp: ColorPickerOptions) void {
            _ = rl.guiColorBarHueH(cp.bounds, "", value);
        }
    };
    pub fn toggle(self: *Panel) void {
        self.visible = !self.visible;
    }
};

const tunable_fmt = "{d:7.3}";
const vlen = std.fmt.count(tunable_fmt, .{0}) + 5;
var txt = [_]u8{0} ** 256;
var value_buffer = [_]u8{0} ** vlen;
var editing_buffer = [_]u8{0} ** vlen;
