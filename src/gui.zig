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
        renderSettings(&c, config.Visualizer.WaveFormLine.Settings);
        renderSettings(&c, config.Visualizer.Bubble.Settings);
    }
}

const Settings = std.StaticStringMap(controls.Setting);
pub fn renderSettings(ctx: *Panel.Context, comptime settings: Settings) void {
    for (settings.keys(), settings.values()) |key, v| {
        renderControl(ctx, key, v);
        _ = ctx.nextRow(24);
    }
}
fn renderControl(ctx: *Panel.Context, key: []const u8, v: controls.Setting) void {
    const x = ctx.current_x;
    const y = ctx.current_y;
    switch (v) {
        .scalar => |s| ctx.slider(s.value, .{
            .text = key,
            .bounds = .{ .x = x, .y = y, .width = 200, .height = 24 },
            .min = s.range.@"0",
            .max = s.range.@"1",
        }),
        else => {},
        // .color => |c| ctx.colorPicker(c.value, .{
        //     .text = key,
        //     .bounds = .{ .x = x, .y = y, .width = 200, .height = 24 },
        // }),
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
