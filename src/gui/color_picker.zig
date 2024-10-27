const std = @import("std");
const rl = @import("../raylib.zig");
const cnv = @import("../ext/convert.zig");
const iff = cnv.iff;
const ffi = cnv.ffi;
const Rectangle = rl.Rectangle;
const GuiState = rl.GuiState;
const GuiGetState = rl.GuiGetState;
const GuiGetStyle = rl.GuiGetStyle;
const GuiIsLocked = rl.GuiIsLocked;
const COLORPICKER: c_int = rl.COLORPICKER;
const HUEBAR_SELECTOR_HEIGHT: c_int = rl.HUEBAR_SELECTOR_HEIGHT;
const HUEBAR_SELECTOR_OVERFLOW: c_int = rl.HUEBAR_SELECTOR_OVERFLOW;
const STATE_DISABLED: c_int = rl.STATE_DISABLED;
const GetMousePosition = rl.GetMousePosition;
const Vector2 = rl.Vector2;
// const guiControlExclusiveMode = rl.guiControlExclusiveMode;
var guiControlExclusiveMode = false;
const IsMouseButtonDown = rl.IsMouseButtonDown;
const MOUSE_BUTTON_LEFT = rl.MOUSE_BUTTON_LEFT;
//const guiControlExclusiveRec = rl.guiControlExclusiveRec;
pub var guiControlExclusiveRec: Rectangle = Rectangle{
    .x = 0,
    .y = 0,
    .width = 0,
    .height = 0,
};
const STATE_PRESSED = rl.STATE_PRESSED;
const CheckCollisionPointRec = rl.CheckCollisionPointRec;
const STATE_FOCUSED = rl.STATE_FOCUSED;
const DrawRectangleGradientH = rl.DrawRectangleGradientH;
const DrawRectangle = rl.DrawRectangle;
const ceilf = std.math.ceil;
const Fade = rl.Fade;
const Color = rl.Color;
// const guiAlpha = rl.guiAlpha;
const guiAlpha = 1.0;
const GetColor = rl.GetColor;
// const GuiFade = rl.GuiFade;
const BASE_COLOR_DISABLED = rl.BASE_COLOR_DISABLED;
const BORDER_COLOR_DISABLED = rl.BORDER_COLOR_DISABLED;
const BORDER_WIDTH = rl.BORDER_WIDTH;
// const BORDER= rl.BORDER;
const BORDER: c_int = 0;

pub fn GuiColorBarHueH(bounds: Rectangle, text: [*c]const u8, hue: [*c]f32) c_int {
    _ = text; // autofix
    const result: c_int = 0;
    var state: c_uint = @intCast(GuiGetState());
    const selector: Rectangle = Rectangle{
        .x = (bounds.x + ((hue.* / 360.0) * bounds.width)) - @as(f32, @floatFromInt(@divTrunc(GuiGetStyle(COLORPICKER, HUEBAR_SELECTOR_HEIGHT), 2))),
        .y = bounds.y - @as(f32, @floatFromInt(GuiGetStyle(COLORPICKER, HUEBAR_SELECTOR_OVERFLOW))),
        .width = @as(f32, @floatFromInt(GuiGetStyle(COLORPICKER, HUEBAR_SELECTOR_HEIGHT))),
        .height = bounds.height + @as(f32, @floatFromInt(GuiGetStyle(COLORPICKER, HUEBAR_SELECTOR_OVERFLOW) * 2)),
    };
    if ((state != @as(c_uint, @bitCast(STATE_DISABLED))) and !GuiIsLocked()) {
        const mousePoint: Vector2 = GetMousePosition();
        if (guiControlExclusiveMode) {
            if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
                if ((((bounds.x == guiControlExclusiveRec.x) and (bounds.y == guiControlExclusiveRec.y)) and (bounds.width == guiControlExclusiveRec.width)) and (bounds.height == guiControlExclusiveRec.height)) {
                    state = @as(c_uint, @bitCast(STATE_PRESSED));
                    hue.* = ((mousePoint.x - bounds.x) * 360) / bounds.width;
                    hue.* = std.math.clamp(hue.*, 0, 359);
                }
            } else {
                guiControlExclusiveMode = false;
                guiControlExclusiveRec = Rectangle{
                    .x = 0,
                    .y = 0,
                    .width = 0,
                    .height = 0,
                };
            }
        } else if ((@as(c_int, @intFromBool(CheckCollisionPointRec(mousePoint, bounds))) != 0) or (@as(c_int, @intFromBool(CheckCollisionPointRec(mousePoint, selector))) != 0)) {
            if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
                state = @as(c_uint, @bitCast(STATE_PRESSED));
                guiControlExclusiveMode = 1 != 0;
                guiControlExclusiveRec = bounds;
                hue.* = ((mousePoint.x - bounds.x) * 360) / bounds.width;
                if (hue.* <= 0.0) {
                    hue.* = 0.0;
                }
                if (hue.* >= 359.0) {
                    hue.* = 359.0;
                }
            } else {
                state = @as(c_uint, @bitCast(STATE_FOCUSED));
            }
        }
    }
    if (state != @as(c_uint, @bitCast(STATE_DISABLED))) {
        DrawRectangleGradientH(
            iff(c_int, bounds.x),
            iff(c_int, bounds.y),
            iff(c_int, ceilf(bounds.width / 6)),
            iff(c_int, bounds.height),
            Fade(Color{ .r = 255, .g = 0, .b = 0, .a = 255 }, guiAlpha),
            Fade(Color{ .r = 255, .g = 255, .b = 0, .a = 255 }, guiAlpha),
        );
        DrawRectangleGradientH(
            iff(c_int, bounds.x + (bounds.width / 6)),
            iff(c_int, bounds.y),
            iff(c_int, ceilf(bounds.width / 6)),
            iff(c_int, (bounds.height)),
            Fade(Color{ .r = 255, .g = 255, .b = 0, .a = 255 }, guiAlpha),
            Fade(Color{ .r = 0, .g = 255, .b = 0, .a = 255 }, guiAlpha),
        );
        DrawRectangleGradientH(
            iff(c_int, bounds.x + (2 * (bounds.width / 6))),
            iff(c_int, bounds.y),
            iff(c_int, ceilf(bounds.width / 6)),
            iff(c_int, bounds.height),
            Fade(Color{ .r = 0, .g = 255, .b = 0, .a = 255 }, guiAlpha),
            Fade(Color{ .r = 0, .g = 255, .b = 255, .a = 255 }, guiAlpha),
        );
        DrawRectangleGradientH(
            iff(c_int, bounds.x + (3 * (bounds.width / 6))),
            iff(c_int, bounds.y),
            iff(c_int, ceilf(bounds.width / 6)),
            iff(c_int, bounds.height),
            Fade(Color{ .r = 0, .g = 255, .b = 255, .a = 255 }, guiAlpha),
            Fade(Color{ .r = 0, .g = 0, .b = 255, .a = 255 }, guiAlpha),
        );
        DrawRectangleGradientH(
            iff(c_int, bounds.x + (4 * (bounds.width / 6))),
            iff(c_int, bounds.y),
            iff(c_int, ceilf(bounds.width / 6)),
            iff(c_int, bounds.height),
            Fade(Color{ .r = 0, .g = 0, .b = 255, .a = 255 }, guiAlpha),
            Fade(Color{ .r = 255, .g = 0, .b = 255, .a = 255 }, guiAlpha),
        );
        DrawRectangleGradientH(
            iff(c_int, bounds.x + (5 * (bounds.width / 6))),
            iff(c_int, bounds.y),
            iff(c_int, bounds.width / 6),
            iff(c_int, bounds.height),
            Fade(Color{ .r = 255, .g = 0, .b = 255, .a = 255 }, guiAlpha),
            Fade(Color{ .r = 255, .g = 0, .b = 0, .a = 255 }, guiAlpha),
        );
    } else {
        DrawRectangleGradientH(
            iff(c_int, bounds.x),
            iff(c_int, bounds.y),
            iff(c_int, bounds.width),
            iff(c_int, bounds.height),
            Fade(Fade(GetColor(@intCast(GuiGetStyle(COLORPICKER, BASE_COLOR_DISABLED))), 0.1), guiAlpha),
            Fade(GetColor(@intCast(GuiGetStyle(COLORPICKER, BORDER_COLOR_DISABLED))), guiAlpha),
        );
    }
    GuiDrawRectangle(
        bounds,
        GuiGetStyle(COLORPICKER, BORDER_WIDTH),
        GetColor(@bitCast(GuiGetStyle(COLORPICKER, BORDER + @as(c_int, @intCast(state)) * 3))),
        Color{ .r = 0, .g = 0, .b = 0, .a = 0 },
    );
    GuiDrawRectangle(
        selector,
        0,
        Color{ .r = 0, .g = 0, .b = 0, .a = 0 },
        GetColor(@bitCast(GuiGetStyle(COLORPICKER, BORDER + @as(c_int, @bitCast(state)) * 3))),
    );
    return result;
}
pub fn GuiDrawRectangle(rec: Rectangle, borderWidth: c_int, borderColor: Color, color: Color) callconv(.c) void {
    if (color.a > 0) {
        DrawRectangle(
            iff(c_int, rec.x),
            iff(c_int, rec.y),
            iff(c_int, rec.width),
            iff(c_int, rec.height),
            GuiFade(color, guiAlpha),
        );
    }
    if (borderWidth > 0) {
        DrawRectangle(
            iff(c_int, rec.x),
            iff(c_int, rec.y),
            iff(c_int, rec.width),
            borderWidth,
            GuiFade(borderColor, guiAlpha),
        );
        DrawRectangle(
            iff(c_int, rec.x),
            iff(c_int, rec.y) + borderWidth,
            borderWidth,
            iff(c_int, rec.height) - (2 * borderWidth),
            GuiFade(borderColor, guiAlpha),
        );
        DrawRectangle(
            iff(c_int, rec.x + rec.width) - borderWidth,
            iff(c_int, rec.y) + borderWidth,
            borderWidth,
            iff(c_int, rec.height) - (2 * borderWidth),
            GuiFade(borderColor, guiAlpha),
        );
        DrawRectangle(
            iff(c_int, rec.x),
            iff(c_int, rec.y + rec.height) - borderWidth,
            iff(c_int, rec.width),
            borderWidth,
            GuiFade(borderColor, guiAlpha),
        );
    }
}
pub fn GuiFade(color: Color, alpha: f32) callconv(.c) Color {
    const a = std.math.clamp(alpha, 0, 1);
    return Color{ .r = color.r, .g = color.g, .b = color.b, .a = iff(u8, ffi(f32, color.a) * a) };
}