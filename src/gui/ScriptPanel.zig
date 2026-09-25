const std = @import("std");
const rl = @import("raylib");
const ui = @import("theme.zig");
const Scene = @import("../scripting/Scene.zig");

// The same wrapping routine measures and draws, keeping scrolling/hit areas aligned.
fn wrapped(text: []const u8, x: f32, y: f32, width: f32, color: rl.Color, paint: bool) f32 {
    var rest = text;
    var lines: usize = 0;
    while (rest.len > 0) {
        var buffer: [256]u8 = @splat(0);
        var end: usize = 0;
        var space: usize = 0;
        while (end < rest.len and end < buffer.len - 5 and rest[end] != '\n') {
            const length = std.unicode.utf8ByteSequenceLength(rest[end]) catch 1;
            const next = @min(rest.len, end + length);
            @memcpy(buffer[end..next], rest[end..next]);
            buffer[next] = 0;
            if (end > 0 and ui.textWidth(std.mem.span(@as([*:0]const u8, @ptrCast(&buffer))), 12) > width) break;
            if (rest[end] == ' ') space = end;
            end = next;
        }
        if (end < rest.len and rest[end] != '\n' and space > 0) end = space;
        if (end == 0 and rest[0] != '\n') end = 1;
        buffer[end] = 0;
        if (paint) ui.label(std.mem.span(@as([*:0]const u8, @ptrCast(&buffer))), x, y + @as(f32, @floatFromInt(lines)) * 17, 12, color);
        rest = rest[end..];
        if (rest.len > 0 and (rest[0] == '\n' or rest[0] == ' ')) rest = rest[1..];
        lines += 1;
    }
    return @as(f32, @floatFromInt(lines)) * 17;
}
fn noticeHeight(scene: *const Scene, width: f32) f32 {
    const message = if (scene.errorMessage().len > 0) scene.errorMessage() else scene.logMessage();
    return if (message.len == 0) 0 else 28 + wrapped(message, 0, 0, width - 16, ui.muted, false);
}
pub fn height(scene: *Scene, width: f32) f32 {
    return 208 + noticeHeight(scene, width) + @as(f32, @floatFromInt(scene.params().len)) * 52;
}
fn button(view: rl.Rectangle, x: f32, y: f32, width: f32, label: [:0]const u8, selected: bool, enabled: bool) bool {
    return ui.button(ui.rect(x, y, width, 30), label, selected, enabled and y >= view.y and y + 30 <= view.y + view.height);
}
pub fn draw(scene: *Scene, view: rl.Rectangle, scroll: f32, slider: anytype) void {
    var y = view.y - scroll;
    ui.label(scene.name(), view.x + 8, y, 16, ui.accent);
    ui.label(if (scene.runtime == null) "LUA SCENES" else if (scene.usesBuiltin()) "LUA / OVERLAY" else "LUA / CUSTOM SCENE", view.x + 8, y + 24, 10, ui.muted);
    var caption_buffer: [256]u8 = undefined;
    const caption = if (scene.path().len > 0)
        std.fmt.bufPrintZ(&caption_buffer, "File: {s}", .{std.fs.path.basename(scene.path())}) catch "External Lua file"
    else
        "Drop a .lua file here, or try an example.";
    ui.label(caption, view.x + 8, y + 44, 12, ui.muted);
    y += 70;
    const third = (view.width - 12) / 3;
    inline for (Scene.examples, 0..) |entry, i| {
        if (button(view, view.x + @as(f32, @floatFromInt(i)) * (third + 6), y, third, entry.label, scene.example == @as(Scene.Example, @enumFromInt(i)), true)) {
            scene.loadExample(@enumFromInt(i));
            return; // A new parameter list is drawn on the next frame.
        }
    }
    y += 40;
    const half = (view.width - 8) / 2;
    if (button(view, view.x, y, half, "Reload / F5", false, scene.canReload())) {
        scene.reload();
        return;
    }
    if (button(view, view.x + half + 8, y, half, "Use built-in", scene.runtime == null, scene.canReload() or scene.runtime != null)) {
        scene.unload();
        return;
    }
    y += 40;
    if (button(view, view.x, y, view.width, if (scene.auto_reload) "Auto reload: On" else "Auto reload: Off", scene.auto_reload, scene.path().len > 0)) scene.auto_reload = !scene.auto_reload;
    y += 46;
    const is_error = scene.errorMessage().len > 0;
    const message = if (is_error) scene.errorMessage() else scene.logMessage();
    if (message.len > 0) {
        ui.label(if (is_error) "SCRIPT ERROR" else "SCRIPT MESSAGE", view.x + 8, y, 10, if (is_error) .{ .r = 255, .g = 150, .b = 140, .a = 255 } else ui.accent);
        y += 22;
        y += wrapped(message, view.x + 8, y, view.width - 16, ui.muted, true) + 6;
    }
    for (scene.params(), 0..) |*param, i| {
        ui.label(std.mem.span(@as([*:0]const u8, @ptrCast(&param.label))), view.x + 8, y + 4, 14, ui.text);
        var number: [32]u8 = undefined;
        ui.label(std.fmt.bufPrintZ(&number, "{d:.2}", .{param.value}) catch "?", view.x + view.width - 58, y + 5, 12, ui.muted);
        _ = slider(4000 + i, ui.rect(view.x + 8, y + 27, view.width - 16, 18), &param.value, param.min, param.max, y >= view.y and y + 46 <= view.y + view.height, false);
        y += 52;
    }
}
