const std = @import("std");
const tracy = @import("tracy");
const rl = @import("raylibz");

const config = @import("core/config.zig");
const controls = @import("core/controls.zig");
const playback = @import("audio/playback.zig");

const Rectangle = rl.Rectangle;
const panel = @import("ui/panel.zig");
const Panel = @import("ui/panel.zig").Panel;
const LayZ = @import("ui/panel.zig").LayZ;
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
// var color_panel = Panel.init(8, 24, 200, 700, "Colors");

var node_buffer: [1024]LayZ.Node = undefined;
pub fn frame() void {
    const t = tracy.traceNamed(@src(), "gui frame");
    defer t.end();

    var layz = LayZ.init(&node_buffer);
    layz.startElement(.{
        .tag = .{ .panel = .{
            .title = "Scalars",
        } },
        .direction = .vertical,
        .layout = .{ .x = 8, .y = 24, .width = .{ .fixed = 280 }, .height = .{ .fixed = 700 } },
        .bounds = .{ .x = 8, .y = 24, .width = 280, .height = 700 },
    });
    const wave_settings = config.Visualizer.WaveFormLine.Settings;
    var keyWidth: f32 = 0;
    for (wave_settings.keys()) |key| {
        const text_width: f32 = @floatFromInt(rl.guiGetTextWidth(key.ptr));
        keyWidth = @max(keyWidth, text_width + 2);
    }
    for (wave_settings.keys(), wave_settings.values()) |key, v| {
        layz.startElement(.{
            .tag = .group,
            .direction = .horizontal,
            .layout = .{ .x = 0, .y = 24, .width = .fill, .height = .{ .fixed = 24 } },
            .bounds = .{ .x = 0, .y = 24, .width = 280, .height = 24 },
        });
        {
            layz.startElement(.{
                .tag = .{ .label = .{
                    .text = key,
                } },
                .direction = .vertical,
                .layout = .{ .x = 0, .y = 24, .width = .{ .fixed = keyWidth }, .height = .{ .fixed = 24 } },
                .bounds = .{ .x = 0, .y = 24, .width = keyWidth, .height = 24 },
            });
            layz.endElement();
            layz.startElement(.{
                .tag = .{ .slider = switch (v) {
                    .scalar => .{
                        .value = v.scalar.value,
                    },
                    .color => .{
                        .value = v.color.value,
                    },
                } },
                .direction = .horizontal,
                .layout = .{ .x = 0, .y = 24, .width = .fill, .height = .{ .fixed = 24 } },
                .bounds = .{ .x = 0, .y = 24, .width = 280, .height = 24 },
            });
            layz.endElement();
        }
        layz.endElement();
    }
    layz.endElement();
    const rendered = layz.endLayout();
    for (rendered) |node| {
        switch (node.tag) {
            .panel => {
                _ = rl.guiPanel(node.bounds, node.tag.panel.title.ptr);
            },
            .label => {
                _ = rl.guiLabel(node.bounds, node.tag.label.text.ptr);
            },
            .slider => {
                _ = rl.guiSlider(node.bounds, null, null, node.tag.slider.value, 0, 1);
            },
            else => {},
        }
    }
    // if (scalar_panel.begin()) |p| {
    //     var bounds = ctx.bounds();
    //     const wave_settings = config.Visualizer.WaveFormLine.Settings;
    //     var keyWidth: f32 = 0;
    //     for (wave_settings.keys()) |key| {
    //         const text_width: f32 = @floatFromInt(rl.guiGetTextWidth(key.ptr));
    //         keyWidth = @max(keyWidth, text_width + 2);
    //     }
    //     for (wave_settings.keys(), wave_settings.values()) |key, v| {
    //         switch (v) {
    //             .scalar => {
    //                 const label = bounds.resize(keyWidth, Panel.ROW_HEIGHT);
    //                 _ = rl.guiLabel(label, key.ptr);
    //             },
    //             .color => {
    //                 const label = bounds.resize(keyWidth, Panel.ROW_HEIGHT);
    //                 _ = rl.guiLabel(label, key.ptr);
    //             },
    //         }
    //         bounds.y += Panel.ROW_HEIGHT;
    //     }
    // }
    // const bubble_settings = config.Visualizer.Bubble.Settings;
    // for (bubble_settings.keys()) |key| {
    //     const text_width: f32 = @floatFromInt(rl.guiGetTextWidth(key.ptr));
    //     keyWidth = @max(keyWidth, text_width + 2);
    // }
    // for (bubble_settings.keys(), bubble_settings.values()) |key, v| {
    //     switch (v) {
    //         .scalar => {
    //             _ = rl.guiLabel(.{
    //                 .x = ctx.x,
    //                 .y = ctx.y,
    //                 .width = keyWidth,
    //                 .height = Panel.ROW_HEIGHT,
    //             }, key.ptr);
    //         },
    //         .color => {
    //             _ = rl.guiLabel(.{
    //                 .x = ctx.x,
    //                 .y = ctx.y,
    //                 .width = keyWidth,
    //                 .height = Panel.ROW_HEIGHT,
    //             }, key.ptr);
    //         },
    //     }
    //     ctx.y += Panel.ROW_HEIGHT;
    // }
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
