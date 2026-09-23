//! Shared palette, typography and drawing primitives for the studio UI.
const rl = @import("raylib");

pub const background = rl.Color{ .r = 11, .g = 15, .b = 24, .a = 255 };
pub const surface = rl.Color{ .r = 19, .g = 25, .b = 37, .a = 250 };
pub const raised = rl.Color{ .r = 28, .g = 36, .b = 50, .a = 255 };
pub const border = rl.Color{ .r = 43, .g = 53, .b = 69, .a = 255 };
pub const text = rl.Color{ .r = 230, .g = 237, .b = 246, .a = 255 };
pub const muted = rl.Color{ .r = 147, .g = 161, .b = 181, .a = 255 };
pub const accent = rl.Color{ .r = 119, .g = 225, .b = 203, .a = 255 };
pub const accent_soft = rl.Color{ .r = 33, .g = 66, .b = 66, .a = 255 };
// Bake the sizes we actually draw instead of shrinking one atlas for every
// label. A 14-point label on a 2x Retina display gets a 28-pixel glyph bitmap.
const font_sizes = [_]f32{ 9, 10, 11, 12, 13, 14, 15, 16, 21, 22 };
const FontEntry = struct { font: rl.Font, owned: bool };
var fonts: [font_sizes.len]FontEntry = undefined;
var fonts_loaded = false;
var display_scale = rl.Vector2{ .x = 1, .y = 1 };

pub fn init() void {
    updateScale();
    rl.GuiSetAlpha(1);
    const styles = .{
        .{ rl.BORDER_COLOR_NORMAL, border },
        .{ rl.BASE_COLOR_NORMAL, raised },
        .{ rl.TEXT_COLOR_NORMAL, text },
        .{ rl.BORDER_COLOR_FOCUSED, accent },
        .{ rl.BASE_COLOR_FOCUSED, accent_soft },
        .{ rl.TEXT_COLOR_FOCUSED, text },
        .{ rl.BORDER_COLOR_PRESSED, accent },
        .{ rl.BASE_COLOR_PRESSED, accent_soft },
        .{ rl.TEXT_COLOR_PRESSED, accent },
    };
    inline for (styles) |entry| rl.GuiSetStyle(rl.DEFAULT, entry[0], @bitCast(rl.ColorToInt(entry[1])));
    rl.GuiSetStyle(rl.DEFAULT, rl.BACKGROUND_COLOR, @bitCast(rl.ColorToInt(surface)));
    rl.GuiSetStyle(rl.DEFAULT, rl.LINE_COLOR, @bitCast(rl.ColorToInt(border)));
    rl.GuiSetStyle(rl.DEFAULT, rl.TEXT_SIZE, 14);
    rl.GuiSetStyle(rl.DEFAULT, rl.TEXT_SPACING, 0);
    rl.GuiSetStyle(rl.DEFAULT, rl.BORDER_WIDTH, 1);
}

/// Called before drawing, including after a move between different-DPI screens.
pub fn updateScale() void {
    const scale = rl.GetWindowScaleDPI();
    if (fonts_loaded and scale.x == display_scale.x and scale.y == display_scale.y) return;
    deinit();
    display_scale = .{ .x = @max(1, scale.x), .y = @max(1, scale.y) };
    const data = @embedFile("assets/Lato-Regular.ttf");
    // ASCII and printable Latin-1 include accented filenames without requesting
    // control-code glyphs that TrueType fonts do not contain.
    var codepoints: [190]c_int = undefined;
    for (&codepoints, 0..) |*codepoint, index| {
        codepoint.* = @intCast(if (index < 95) index + 32 else index - 95 + 161);
    }
    for (&fonts, font_sizes) |*entry, size| {
        const pixels: c_int = @intFromFloat(@round(size * @max(display_scale.x, display_scale.y)));
        var font = rl.LoadFontFromMemory(".ttf", data, data.len, pixels, &codepoints, codepoints.len);
        const owned = font.texture.id != 0 and font.texture.id != rl.GetFontDefault().texture.id;
        if (!owned) font = rl.GetFontDefault();
        rl.SetTextureFilter(font.texture, rl.TEXTURE_FILTER_BILINEAR);
        entry.* = .{ .font = font, .owned = owned };
    }
    fonts_loaded = true;
    rl.GuiSetFont(fontForSize(14));
    // GuiSetFont uses the atlas's physical size by default; raygui needs points.
    rl.GuiSetStyle(rl.DEFAULT, rl.TEXT_SIZE, 14);
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

pub fn card(bounds: rl.Rectangle) void {
    rounded(rect(bounds.x, bounds.y + 4, bounds.width, bounds.height), 12, rl.Fade(rl.BLACK, 0.18));
    rounded(bounds, 12, border);
    rounded(rect(bounds.x + 1, bounds.y + 1, bounds.width - 2, bounds.height - 2), 11, surface);
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

pub fn centered(value: [:0]const u8, bounds: rl.Rectangle, size: f32, color: rl.Color) void {
    label(value, bounds.x + (bounds.width - textWidth(value, size)) / 2, bounds.y + (bounds.height - size) / 2, size, color);
}

pub fn hovered(bounds: rl.Rectangle) bool {
    return rl.CheckCollisionPointRec(rl.GetMousePosition(), bounds);
}

pub fn button(bounds: rl.Rectangle, value: [:0]const u8, selected: bool, enabled: bool) bool {
    const over = enabled and hovered(bounds);
    rounded(bounds, 7, if (selected) accent_soft else if (over) raised else surface);
    centered(value, bounds, 14, if (!enabled) border else if (selected) accent else if (over) text else muted);
    if (over) rl.SetMouseCursor(rl.MOUSE_CURSOR_POINTING_HAND);
    return over and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT);
}
