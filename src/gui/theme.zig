//! Shared palette, typography and drawing primitives for the studio UI.
const rl = @import("raylib");
const std = @import("std");
const config = @import("../core/config.zig");
const geometry = @import("geometry.zig");
const Cursor = @import("Cursor.zig");
var cursor: Cursor = .{};
pub var scale_factor: f32 = 1;
pub var blocked = false;
var focus: @import("Focus.zig") = .{};
pub var typing = false;
var tip_buffer: [256]u8 = @splat(0);
var tip_id: u64 = 0;
var previous_tip: u64 = 0;
var tip_start: f64 = 0;

pub fn keyboardActive() bool {
    return focus.visible;
}
fn controlId(bounds: rl.Rectangle, name: []const u8) u64 {
    var hash = std.hash.Wyhash.init(0);
    hash.update(name);
    const position = [_]i32{ @intFromFloat(bounds.x), @intFromFloat(bounds.y) };
    hash.update(std.mem.asBytes(&position));
    return hash.final();
}
pub fn focusable(id: u64, bounds: rl.Rectangle, enabled: bool) bool {
    if (blocked or !enabled) return false;
    const active = focus.add(id, hovered(bounds) and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT));
    if (active) rl.DrawRectangleRoundedLinesEx(rect(bounds.x - 2, bounds.y - 2, bounds.width + 4, bounds.height + 4), 0.15, 6, 1, accent);
    return active;
}
pub fn activate(bounds: rl.Rectangle, name: []const u8, enabled: bool) bool {
    const focused = focusable(controlId(bounds, name), bounds, enabled);
    const space = rl.IsKeyPressed(rl.KEY_SPACE) and !rl.IsKeyDown(rl.KEY_LEFT_SHIFT) and !rl.IsKeyDown(rl.KEY_RIGHT_SHIFT);
    return !blocked and enabled and ((hovered(bounds) and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) or
        (focused and !typing and (rl.IsKeyPressed(rl.KEY_ENTER) or space)));
}
pub fn tooltip(bounds: rl.Rectangle, value: [:0]const u8) void {
    if (!hovered(bounds)) return;
    tip_id = controlId(bounds, value);
    const n = @min(value.len, tip_buffer.len - 1);
    @memcpy(tip_buffer[0..n], value[0..n]);
    tip_buffer[n] = 0;
}

fn rgb(r: u8, g: u8, b: u8) rl.Color {
    return .{ .r = r, .g = g, .b = b, .a = 255 };
}

// Neutral graphite chrome with zigscene's mint accent, after PhotoCraft's
// docked workspace. The canvas is the darkest surface so the visuals carry the color.
pub const background = rgb(30, 30, 30); // Canvas, previews and window clear
pub const well = rgb(40, 40, 40); // Panel tab strips
pub const surface = rgb(50, 50, 50); // Docked bars and panels
pub const field = rgb(36, 36, 36); // Text and number entry
pub const control = rgb(60, 60, 60); // Button fill
pub const raised = rgb(68, 68, 68); // Hover
pub const selection = rgb(84, 84, 84); // Selected rows, tabs and toggles
pub const border = rgb(86, 86, 86); // Control outlines
pub const divider = rgb(66, 66, 66); // Rules inside a panel
pub const hairline = rgb(24, 24, 24); // Seams between docked areas
pub const text = rgb(232, 232, 232);
pub const secondary = rgb(200, 200, 200); // Field labels
pub const muted = rgb(156, 156, 156);
pub const faint = rgb(108, 108, 108); // Disabled
pub const accent = rgb(119, 225, 203);
pub const accent_hover = rgb(152, 236, 218);
pub const accent_soft = rgb(33, 66, 66);
pub const on_accent = rgb(18, 42, 37); // Ink on accent fills
pub const warning = rgb(255, 210, 138);
pub const danger = rgb(255, 150, 140);
// Bake each font size at the largest UI scale. Resizing the UI then reuses
// the atlases instead of rebuilding every font while the window is dragged.
const font_sizes = [_]f32{ 9, 10, 11, 12, 13, 14, 15, 16, 21, 22 };
const FontEntry = struct { font: rl.Font, owned: bool };
var fonts: [font_sizes.len]FontEntry = undefined;
var fonts_loaded = false;
var font_scale: f32 = 0;
var display_scale = rl.Vector2{ .x = 1, .y = 1 };

pub fn init() void {
    cursor = .{};
    updateScale();
    rl.GuiSetAlpha(1);
    // raygui only draws text and number entry; match the inset field style.
    const styles = .{
        .{ rl.BORDER_COLOR_NORMAL, border },
        .{ rl.BASE_COLOR_NORMAL, field },
        .{ rl.TEXT_COLOR_NORMAL, text },
        .{ rl.BORDER_COLOR_FOCUSED, accent },
        .{ rl.BASE_COLOR_FOCUSED, field },
        .{ rl.TEXT_COLOR_FOCUSED, text },
        .{ rl.BORDER_COLOR_PRESSED, accent },
        .{ rl.BASE_COLOR_PRESSED, field },
        .{ rl.TEXT_COLOR_PRESSED, text },
    };
    inline for (styles) |entry| rl.GuiSetStyle(rl.DEFAULT, entry[0], @bitCast(rl.ColorToInt(entry[1])));
    rl.GuiSetStyle(rl.DEFAULT, rl.BACKGROUND_COLOR, @bitCast(rl.ColorToInt(surface)));
    rl.GuiSetStyle(rl.DEFAULT, rl.LINE_COLOR, @bitCast(rl.ColorToInt(border)));
    rl.GuiSetStyle(rl.DEFAULT, rl.TEXT_SIZE, 13);
    rl.GuiSetStyle(rl.DEFAULT, rl.TEXT_SPACING, 0);
    rl.GuiSetStyle(rl.DEFAULT, rl.BORDER_WIDTH, 1);
}

/// Called before drawing, including after a move between different-DPI screens.
pub fn updateScale() void {
    scale_factor = geometry.scaleForWindow(config.Interface.scale_percent, @floatFromInt(rl.GetScreenWidth()), @floatFromInt(rl.GetScreenHeight()));
    const dpi = rl.GetWindowScaleDPI();
    display_scale = .{ .x = @max(1, dpi.x) * scale_factor, .y = @max(1, dpi.y) * scale_factor };
    const atlas_scale = @max(1, @max(dpi.x, dpi.y)) * 1.5;
    if (fonts_loaded and atlas_scale == font_scale) return;
    deinit();
    font_scale = atlas_scale;
    const data = @embedFile("assets/Lato-Regular.ttf");
    // ASCII and printable Latin-1 include accented filenames without requesting
    // control-code glyphs that TrueType fonts do not contain.
    var codepoints: [190]c_int = undefined;
    for (&codepoints, 0..) |*codepoint, index| {
        codepoint.* = @intCast(if (index < 95) index + 32 else index - 95 + 161);
    }
    for (&fonts, font_sizes) |*entry, size| {
        const pixels: c_int = @intFromFloat(@round(size * font_scale));
        var font = rl.LoadFontFromMemory(".ttf", data, data.len, pixels, &codepoints, codepoints.len);
        const owned = font.texture.id != 0 and font.texture.id != rl.GetFontDefault().texture.id;
        if (!owned) font = rl.GetFontDefault();
        rl.SetTextureFilter(font.texture, rl.TEXTURE_FILTER_BILINEAR);
        entry.* = .{ .font = font, .owned = owned };
    }
    fonts_loaded = true;
    rl.GuiSetFont(fontForSize(13));
    // GuiSetFont uses the atlas's physical size by default; raygui needs points.
    rl.GuiSetStyle(rl.DEFAULT, rl.TEXT_SIZE, 13);
}

pub fn deinit() void {
    if (!fonts_loaded) return;
    rl.GuiSetFont(rl.GetFontDefault());
    for (fonts) |entry| {
        if (entry.owned) rl.UnloadFont(entry.font);
    }
    fonts_loaded = false;
}

fn fontForSize(size: f32) rl.Font {
    var nearest: usize = 0;
    for (font_sizes, 0..) |candidate, index| {
        if (@abs(candidate - size) < @abs(font_sizes[nearest] - size)) nearest = index;
    }
    return fonts[nearest].font;
}

pub fn rect(x: f32, y: f32, w: f32, h: f32) rl.Rectangle {
    return .{ .x = x, .y = y, .width = w, .height = h };
}

pub fn rounded(bounds: rl.Rectangle, radius: f32, color: rl.Color) void {
    rl.DrawRectangleRounded(bounds, @min(1, radius * 2 / @min(bounds.width, bounds.height)), 8, color);
}

/// A filled rounded rectangle with a one-pixel edge.
pub fn framed(bounds: rl.Rectangle, radius: f32, body: rl.Color, edge: rl.Color) void {
    rounded(bounds, radius, edge);
    rounded(rect(bounds.x + 1, bounds.y + 1, bounds.width - 2, bounds.height - 2), @max(0, radius - 1), body);
}

pub fn fill(bounds: rl.Rectangle, color: rl.Color) void {
    rl.DrawRectangleRec(bounds, color);
}

/// One logical pixel: seams between docked areas and rules inside panels.
pub fn hline(x: f32, y: f32, w: f32, color: rl.Color) void {
    if (w > 0) rl.DrawRectangleRec(rect(x, y, w, 1), color);
}
pub fn vline(x: f32, y: f32, h: f32, color: rl.Color) void {
    if (h > 0) rl.DrawRectangleRec(rect(x, y, 1, h), color);
}

/// Floating surfaces over the canvas: dialogs, the welcome card, diagnostics.
pub fn card(bounds: rl.Rectangle) void {
    rounded(rect(bounds.x - 2, bounds.y + 2, bounds.width + 4, bounds.height + 6), 10, rl.Fade(rl.BLACK, 0.28));
    framed(bounds, 8, surface, divider);
}

/// Section title followed by a rule, like "Character" in a properties panel.
pub fn heading(value: [:0]const u8, x: f32, y: f32, w: f32) void {
    label(value, x, y, 13, text);
    const start = textWidth(value, 13) + 10;
    hline(x + start, y + 8, w - start, divider);
}

/// List rows highlight on hover and stay lit while selected.
pub fn rowFill(bounds: rl.Rectangle, selected: bool, over: bool) void {
    if (selected) rounded(bounds, 4, selection) else if (over) rounded(bounds, 4, raised);
}

pub fn label(value: [:0]const u8, x: f32, y: f32, size: f32, color: rl.Color) void {
    // Align glyph origins to physical pixels, including centered labels.
    const origin = rl.Vector2{
        .x = @round(x * display_scale.x) / display_scale.x,
        .y = @round(y * display_scale.y) / display_scale.y,
    };
    rl.DrawTextEx(fontForSize(size), value, origin, size, 0, color);
}

pub fn textWidth(value: [:0]const u8, size: f32) f32 {
    return rl.MeasureTextEx(fontForSize(size), value, size, 0).x;
}

/// Keep long names and control labels inside their allotted width.
pub fn fitted(value: [:0]const u8, size: f32, available: f32, buffer: *[256]u8) [:0]const u8 {
    if (textWidth(value, size) <= available) return value;
    var length = @min(value.len, buffer.len - 4);
    while (length > 0) {
        // Do not split a UTF-8 sequence when shortening user-entered names.
        while (length > 0 and value[length] & 0xc0 == 0x80) length -= 1;
        @memcpy(buffer[0..length], value[0..length]);
        @memcpy(buffer[length..][0..3], "...");
        buffer[length + 3] = 0;
        const result = buffer[0 .. length + 3 :0];
        if (length == 0 or textWidth(result, size) <= available) return result;
        length -= 1;
    }
    return "...";
}

pub fn centered(value: [:0]const u8, bounds: rl.Rectangle, size: f32, color: rl.Color) void {
    label(value, bounds.x + (bounds.width - textWidth(value, size)) / 2, bounds.y + (bounds.height - size) / 2, size, color);
}

pub fn hovered(bounds: rl.Rectangle) bool {
    return !blocked and rl.CheckCollisionPointRec(mousePosition(), bounds);
}

const ButtonKind = enum {
    /// Outlined control; "selected" marks an active toggle or segment.
    normal,
    /// Filled accent pill for the main action in a dialog.
    primary,
    /// Outlined pill beside a primary action.
    secondary,
    /// Flat until hovered: tabs, status bar and inline actions.
    ghost,
};

pub fn button(bounds: rl.Rectangle, value: [:0]const u8, selected: bool, enabled: bool) bool {
    return styledButton(bounds, value, .normal, selected, enabled);
}
pub fn primaryButton(bounds: rl.Rectangle, value: [:0]const u8, enabled: bool) bool {
    return styledButton(bounds, value, .primary, false, enabled);
}
pub fn secondaryButton(bounds: rl.Rectangle, value: [:0]const u8, enabled: bool) bool {
    return styledButton(bounds, value, .secondary, false, enabled);
}
pub fn ghostButton(bounds: rl.Rectangle, value: [:0]const u8, selected: bool, enabled: bool) bool {
    return styledButton(bounds, value, .ghost, selected, enabled);
}

fn styledButton(bounds: rl.Rectangle, value: [:0]const u8, kind: ButtonKind, selected: bool, enabled: bool) bool {
    const over = enabled and hovered(bounds);
    const pill = bounds.height / 2;
    switch (kind) {
        .normal => framed(bounds, 4, if (!enabled) surface else if (selected) selection else if (over) raised else control, if (!enabled) divider else if (selected) accent else border),
        .primary => rounded(bounds, pill, if (!enabled) accent_soft else if (over) accent_hover else accent),
        .secondary => framed(bounds, pill, if (over) raised else surface, if (enabled) muted else divider),
        .ghost => rowFill(bounds, selected, over),
    }
    const ink = if (!enabled) faint else if (kind == .primary) on_accent else if (kind == .ghost and !selected and !over) muted else text;
    const hint = if (!enabled) faint else if (kind == .primary) rl.Fade(on_accent, 0.7) else muted;
    buttonLabel(value, bounds, if (bounds.height < 24) 12 else 13, ink, hint);
    if (over) requestCursor(rl.MOUSE_CURSOR_POINTING_HAND);
    tooltip(bounds, value);
    return activate(bounds, value, enabled);
}

/// "Capture / M" shows its shortcut dimmer, like a menu accelerator.
fn buttonLabel(value: [:0]const u8, bounds: rl.Rectangle, size: f32, ink: rl.Color, hint: rl.Color) void {
    if (std.mem.lastIndexOf(u8, value, " / ")) |split| {
        const key = value[split + 3 ..];
        if (key.len > 0 and key.len <= 2 and split < 128) {
            var main_buffer: [128:0]u8 = undefined;
            @memcpy(main_buffer[0..split], value[0..split]);
            main_buffer[split] = 0;
            const main = main_buffer[0..split :0];
            const gap: f32 = 6;
            const main_width = textWidth(main, size);
            const total = main_width + gap + textWidth(key, size - 1);
            if (total <= bounds.width - 12) {
                const x = bounds.x + (bounds.width - total) / 2;
                const y = bounds.y + (bounds.height - size) / 2;
                label(main, x, y, size, ink);
                label(key, x + main_width + gap, y + 1, size - 1, hint);
                return;
            }
        }
    }
    var label_buffer: [256]u8 = undefined;
    centered(fitted(value, size, bounds.width - 8, &label_buffer), bounds, size, ink);
}

pub const Icon = enum { reset, chevron_left, chevron_right, chevron_down, eye, eye_off, search, volume, check, play, pause };

/// raylib culls clockwise triangles; accept either winding.
fn triangle(a: rl.Vector2, b: rl.Vector2, c: rl.Vector2, color: rl.Color) void {
    const cross = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
    if (cross > 0) rl.DrawTriangle(a, c, b, color) else rl.DrawTriangle(a, b, c, color);
}
fn stroke(points: []const rl.Vector2, thickness: f32, color: rl.Color) void {
    for (points[0 .. points.len - 1], points[1..]) |a, b| rl.DrawLineEx(a, b, thickness, color);
}
fn at(c: rl.Vector2, dx: f32, dy: f32) rl.Vector2 {
    return .{ .x = c.x + dx, .y = c.y + dy };
}

/// Small line icons drawn from primitives, about 14 logical pixels across.
pub fn icon(kind: Icon, c: rl.Vector2, color: rl.Color) void {
    switch (kind) {
        .reset => {
            // An open ring with its arrowhead turning counter-clockwise.
            rl.DrawRing(c, 4, 5.3, -50, 215, 24, color);
            const angle = std.math.degreesToRadians(@as(f32, -50));
            const tip = at(c, @cos(angle) * 4.65, @sin(angle) * 4.65);
            const radial = rl.Vector2{ .x = @cos(angle), .y = @sin(angle) };
            const tangent = rl.Vector2{ .x = @sin(angle), .y = -@cos(angle) };
            triangle(at(tip, tangent.x * 3.2, tangent.y * 3.2), at(tip, radial.x * 3, radial.y * 3), at(tip, -radial.x * 3, -radial.y * 3), color);
        },
        .chevron_left => stroke(&.{ at(c, 2, -4), at(c, -2, 0), at(c, 2, 4) }, 1.6, color),
        .chevron_right => stroke(&.{ at(c, -2, -4), at(c, 2, 0), at(c, -2, 4) }, 1.6, color),
        .chevron_down => stroke(&.{ at(c, -4, -2), at(c, 0, 2), at(c, 4, -2) }, 1.6, color),
        .eye, .eye_off => {
            // Two arcs of an 8.1px circle meet at the corners of a 14x8 eye.
            rl.DrawRing(at(c, 0, 4.1), 7.5, 8.8, 210, 330, 16, color);
            rl.DrawRing(at(c, 0, -4.1), 7.5, 8.8, 30, 150, 16, color);
            rl.DrawCircleV(c, 2.2, color);
            if (kind == .eye_off) rl.DrawLineEx(at(c, -6, 5), at(c, 6, -5), 1.6, color);
        },
        .search => {
            rl.DrawRing(at(c, -1.5, -1.5), 3.6, 4.9, 0, 360, 24, color);
            rl.DrawLineEx(at(c, 2, 2), at(c, 5.5, 5.5), 1.8, color);
        },
        .volume => {
            rl.DrawRectangleRec(rect(c.x - 6, c.y - 2.5, 3, 5), color);
            triangle(at(c, -3.5, -2.5), at(c, 1, -6), at(c, -3.5, 2.5), color);
            triangle(at(c, -3.5, 2.5), at(c, 1, -6), at(c, 1, 6), color);
            rl.DrawRing(at(c, 1, 0), 3.4, 4.6, -45, 45, 8, color);
            rl.DrawRing(at(c, 1, 0), 6.2, 7.4, -45, 45, 10, color);
        },
        .check => stroke(&.{ at(c, -3.5, 0), at(c, -1, 2.8), at(c, 3.8, -2.8) }, 1.8, color),
        .play => triangle(at(c, -3.5, -6), at(c, -3.5, 6), at(c, 6, 0), color),
        .pause => {
            rounded(rect(c.x - 4.5, c.y - 5.5, 3, 11), 1, color);
            rounded(rect(c.x + 1.5, c.y - 5.5, 3, 11), 1, color);
        },
    }
}

fn middle(bounds: rl.Rectangle) rl.Vector2 {
    return .{ .x = bounds.x + bounds.width / 2, .y = bounds.y + bounds.height / 2 };
}

pub fn iconButton(bounds: rl.Rectangle, kind: Icon, tip: [:0]const u8, selected: bool, enabled: bool) bool {
    const over = enabled and hovered(bounds);
    if (over) rounded(bounds, 4, selection) else if (selected) rounded(bounds, 4, raised);
    icon(kind, middle(bounds), if (!enabled) faint else if (over or selected) text else muted);
    if (over) requestCursor(rl.MOUSE_CURSOR_POINTING_HAND);
    tooltip(bounds, tip);
    return activate(bounds, tip, enabled);
}

/// A labelled check box; the whole row is the hit target.
pub fn checkbox(bounds: rl.Rectangle, value: [:0]const u8, checked: bool, enabled: bool) bool {
    const over = enabled and hovered(bounds);
    const box = rect(bounds.x + 4, bounds.y + (bounds.height - 14) / 2, 14, 14);
    if (checked) {
        rounded(box, 3, if (!enabled) accent_soft else if (over) accent_hover else accent);
        icon(.check, middle(box), if (enabled) on_accent else faint);
    } else framed(box, 3, field, if (over) muted else if (enabled) border else divider);
    var buffer: [256]u8 = undefined;
    label(fitted(value, 13, bounds.width - 30, &buffer), box.x + box.width + 9, bounds.y + (bounds.height - 13) / 2, 13, if (enabled) text else faint);
    if (over) requestCursor(rl.MOUSE_CURSOR_POINTING_HAND);
    return activate(bounds, value, enabled);
}

/// A collapsible section header with a turning chevron.
pub fn disclosure(bounds: rl.Rectangle, value: [:0]const u8, open: bool, enabled: bool) bool {
    const over = enabled and hovered(bounds);
    rowFill(bounds, false, over);
    icon(if (open) .chevron_down else .chevron_right, .{ .x = bounds.x + 11, .y = bounds.y + bounds.height / 2 }, if (over) text else muted);
    label(value, bounds.x + 24, bounds.y + (bounds.height - 13) / 2, 13, if (enabled) text else faint);
    if (over) requestCursor(rl.MOUSE_CURSOR_POINTING_HAND);
    return activate(bounds, value, enabled);
}

/// A closed select field: current value on the left, a chevron on the right.
pub fn dropdown(bounds: rl.Rectangle, value: [:0]const u8, open: bool, enabled: bool) bool {
    const over = enabled and hovered(bounds);
    framed(bounds, 4, field, if (open) accent else if (over) muted else border);
    var buffer: [256]u8 = undefined;
    label(fitted(value, 13, bounds.width - 36, &buffer), bounds.x + 10, bounds.y + (bounds.height - 13) / 2, 13, if (enabled) text else faint);
    icon(.chevron_down, .{ .x = bounds.x + bounds.width - 14, .y = bounds.y + bounds.height / 2 }, if (over or open) text else muted);
    if (over) requestCursor(rl.MOUSE_CURSOR_POINTING_HAND);
    tooltip(bounds, value);
    return activate(bounds, value, enabled);
}

/// Draw and hit-test in the same logical coordinates. Scene rendering stays in
/// window coordinates; UI scaling never changes the camera or audio visuals.
pub fn width() f32 {
    return @as(f32, @floatFromInt(rl.GetScreenWidth())) / scale_factor;
}
pub fn height() f32 {
    return @as(f32, @floatFromInt(rl.GetScreenHeight())) / scale_factor;
}
pub fn mousePosition() rl.Vector2 {
    const mouse = rl.GetMousePosition();
    return .{ .x = mouse.x / scale_factor, .y = mouse.y / scale_factor };
}
pub fn beginDrawing() void {
    cursor.begin();
    focus.begin(rl.IsKeyPressed(rl.KEY_TAB), rl.IsKeyDown(rl.KEY_LEFT_SHIFT) or rl.IsKeyDown(rl.KEY_RIGHT_SHIFT), rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT));
    tip_id = 0;
    resumeDrawing();
}
pub fn endDrawing() void {
    focus.finish();
    if (tip_id != previous_tip) tip_start = rl.GetTime();
    previous_tip = tip_id;
    if (tip_id != 0 and rl.GetTime() - tip_start > 0.6) {
        const value = std.mem.span(@as([*:0]const u8, @ptrCast(&tip_buffer)));
        const w = textWidth(value, 12) + 20;
        const mouse = mousePosition();
        const box = rect(std.math.clamp(mouse.x + 12, 4, @max(4, width() - w - 4)), @min(mouse.y + 20, height() - 32), w, 26);
        framed(box, 4, well, border);
        centered(value, box, 12, text);
    }
    suspendDrawing();
    // Raylib creates a GLFW cursor on each call. Resetting it between widgets
    // needlessly alternates arrow/hand every frame and causes native redraws.
    if (cursor.change()) |next| rl.SetMouseCursor(next);
}
// Offscreen waveform rasterization changes matrices, not input-frame ownership.
pub fn suspendDrawing() void {
    rl.rlPopMatrix();
}
pub fn resumeDrawing() void {
    rl.rlPushMatrix();
    rl.rlScalef(scale_factor, scale_factor, 1);
}
pub fn requestCursor(shape: c_int) void {
    cursor.request(shape);
}
/// Clear a widget cursor when switching to a view without the regular UI.
pub fn resetCursor() void {
    cursor.begin();
    if (cursor.change()) |next| rl.SetMouseCursor(next);
}
pub fn beginScissor(bounds: rl.Rectangle) void {
    rl.BeginScissorMode(@intFromFloat(bounds.x * scale_factor), @intFromFloat(bounds.y * scale_factor), @intFromFloat(bounds.width * scale_factor), @intFromFloat(bounds.height * scale_factor));
}
pub fn valueBox(bounds: rl.Rectangle, buffer: [*]u8, value: *f32) bool {
    // raygui performs its own hit testing, so give it the matching mouse scale.
    rl.SetMouseScale(1 / scale_factor, 1 / scale_factor);
    defer rl.SetMouseScale(1, 1);
    return rl.GuiValueBoxFloat(bounds, null, buffer, value, true) != 0;
}

/// Text entry uses logical mouse coordinates just like numeric fields.
pub fn textBox(bounds: rl.Rectangle, buffer: []u8, editing: bool) bool {
    if (blocked) {
        framed(bounds, 3, field, divider);
        return false;
    }
    rl.SetMouseScale(1 / scale_factor, 1 / scale_factor);
    defer rl.SetMouseScale(1, 1);
    const focused = focusable(controlId(bounds, "text"), bounds, true);
    if (!editing and focused and rl.IsKeyPressed(rl.KEY_ENTER)) return true;
    if (editing and rl.IsKeyPressed(rl.KEY_TAB)) return true;
    return rl.GuiTextBox(bounds, buffer.ptr, @intCast(buffer.len), editing) != 0;
}
