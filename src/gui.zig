const std = @import("std");
const tracy = @import("tracy");
const rl = @import("raylibz");

const config = @import("core/config.zig");
const controls = @import("core/controls.zig");
const playback = @import("audio/playback.zig");

const LayZ = @import("ui/panel.zig").LayZ;

pub const Tab = enum(c_int) { none, scalar, color };
var active_tab: Tab = .scalar;

pub fn onTabChange(next: Tab) void {
    if (active_tab == next) return;
    active_tab = next;
}

var node_buffer: [1024]LayZ.Node = undefined;

pub fn frame() void {
    const t = tracy.traceNamed(@src(), "gui frame");
    defer t.end();

    var layz = LayZ.init(&node_buffer);

    // Root panel
    layz.startElement(.{
        .tag = .{ .panel = .{ .title = "Settings" } },
        .direction = .vertical,
        .bounds = .{ .x = 8, .y = 24, .width = 300, .height = 700 },
    });

    addSettingsGroup(&layz, "Audio", config.Audio.Settings);
    addSettingsGroup(&layz, "Shader", config.Shader.Settings);
    addSettingsGroup(&layz, "WaveFormLine", config.Visualizer.WaveFormLine.Settings);
    addSettingsGroup(&layz, "WaveFormBar", config.Visualizer.WaveFormBar.Settings);
    addSettingsGroup(&layz, "Bubble", config.Visualizer.Bubble.Settings);

    layz.endElement();

    const rendered = layz.endLayout();
    for (rendered) |node| {
        switch (node.tag) {
            .panel => |p| {
                _ = rl.guiPanel(node.bounds, p.title.ptr);
            },
            .label => |l| {
                _ = rl.guiLabel(node.bounds, l.text.ptr);
            },
            .slider => |s| {
                _ = rl.guiSlider(node.bounds, null, null, s.value, s.min, s.max);
            },
            else => {},
        }
    }
}

fn addSettingsGroup(layz: *LayZ, comptime section_name: [:0]const u8, comptime settings: anytype) void {
    const ROW_HEIGHT: f32 = 24;

    // Section header
    layz.startElement(.{
        .tag = .{ .label = .{ .text = "  " ++ section_name } },
        .direction = .vertical,
        .bounds = .{ .x = 0, .y = 0, .width = 300, .height = ROW_HEIGHT },
    });
    layz.endElement();

    // Compute max label width
    var key_width: f32 = 0;
    for (settings.keys()) |key| {
        const text_width: f32 = @floatFromInt(rl.guiGetTextWidth(key.ptr));
        key_width = @max(key_width, text_width + 8);
    }

    for (settings.keys(), settings.values()) |key, v| {
        switch (v) {
            .scalar => |scalar| {
                // Row: label + slider
                layz.startElement(.{
                    .tag = .group,
                    .direction = .horizontal,
                    .bounds = .{ .x = 0, .y = 0, .width = 300, .height = ROW_HEIGHT },
                });
                {
                    layz.startElement(.{
                        .tag = .{ .label = .{ .text = key } },
                        .direction = .vertical,
                        .bounds = .{ .x = 0, .y = 0, .width = key_width, .height = ROW_HEIGHT },
                    });
                    layz.endElement();
                    layz.startElement(.{
                        .tag = .{ .slider = .{
                            .value = scalar.value,
                            .min = scalar.range[0],
                            .max = scalar.range[1],
                        } },
                        .direction = .horizontal,
                        .bounds = .{ .x = 0, .y = 0, .width = 300 - key_width, .height = ROW_HEIGHT },
                    });
                    layz.endElement();
                }
                layz.endElement();
            },
            .color => {
                // Color settings not yet supported in slider UI
            },
        }
    }
}

pub fn onSwipe(dir: anytype, amount: f32) void {
    _ = dir;
    _ = amount;
}
