const std = @import("std");
const rl = @import("raylibz");

const config = @import("core/config.zig");
const controls = @import("core/controls.zig");
const playback = @import("audio/playback.zig");

const Rectangle = rl.Rectangle;
const Panel = @import("ui/panel.zig").Panel;
const Direction = @import("core/event.zig").Direction;

pub const Tab = enum(c_int) { none, scalar, color };
var active_tab: Tab = .scalar;
var gui_xoffset: f32 = 0;

/// Moves the gui state to the desired tab
pub fn onTabChange(next: Tab) void {
    if (Layout.editState != null or active_tab == next) return;
    active_tab = next;
    gui_xoffset = -300;
}

var draggingSlider = false;

var scalar_panel = Panel.init(8, 24, 280, 700, "Scalars");
var color_panel = Panel.init(8, 24, 200, 700, "Colors");

pub fn frame() void {
    if (scalar_panel.begin()) |p| {
        var c = p.context();
        c.offset_y += 24;
        var b = c.bounds();
        b.height = 24;
        c.offset_y += 24;
        _ = rl.guiLabel(b, "WaveFormLine");
        renderSettings(&c, config.Visualizer.WaveFormLine.Settings);
        b = c.bounds();
        b.height = 24;
        c.offset_y += 24;
        _ = rl.guiLabel(b, "Bubbles");
        renderSettings(&c, config.Visualizer.Bubble.Settings);
    }
}

const Settings = std.StaticStringMap(controls.Setting);
pub fn renderSettings(ctx: *Panel.Context, comptime settings: Settings) void {
    var keyWidth: f32 = 0;
    for (settings.keys()) |key| {
        const text_width: f32 = @floatFromInt(rl.guiGetTextWidth(key.ptr));
        keyWidth = @max(keyWidth, text_width + 2);
    }
    for (settings.keys(), settings.values()) |key, v| {
        renderControl(ctx, key, keyWidth, v);
        ctx.offset_y += Panel.ROW_HEIGHT + Panel.PADDING;
    }
}
fn renderControl(ctx: *Panel.Context, key: []const u8, keyWidth: f32, v: controls.Setting) void {
    const bounds = ctx.bounds();
    const x = bounds.x;
    const y = bounds.y;
    switch (v) {
        .scalar => |s| {
            ctx.label(key.ptr, .{ .x = x, .y = y, .width = keyWidth, .height = Panel.ROW_HEIGHT });
            ctx.slider(s.value, .{
                .bounds = .{ .x = x + keyWidth, .y = y, .width = bounds.width - keyWidth, .height = Panel.ROW_HEIGHT },
                .min = s.range.@"0",
                .max = s.range.@"1",
            });
        },
        .color => |c| {
            ctx.label(key.ptr, .{ .x = x, .y = y, .width = keyWidth, .height = Panel.ROW_HEIGHT });
            ctx.colorPicker(c.value, .{
                .bounds = .{ .x = x + keyWidth, .y = y, .width = bounds.width - keyWidth, .height = Panel.ROW_HEIGHT },
            });
        },
    }
}

const Layout = struct {
    var editState: ?usize = null;
    /// Length of values in value buffer (+1 for zero)
    /// It is expected that values shouldn't go over 1000 for the tunables.
    const tunable_fmt = "{d:7.3}";
    const vlen = std.fmt.count(tunable_fmt, .{0}) + 5;
    var txt = [_]u8{0} ** 256;
    var value_buffer = [_]u8{0} ** vlen;
    var editing_buffer = [_]u8{0} ** vlen;
    //        ⬋ please be nice to him
    //   /\_/\
    // =(• . •)=
    //  /     \
};

pub fn onSwipe(dir: Direction, amount: f32) void {
    switch (dir) {
        .horizontal => {},
        .vertical => {},
    }
    _ = amount;
}
