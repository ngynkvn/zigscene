const std = @import("std");
const rl = @import("../raylib.zig");
const cnv = @import("../ext/convert.zig");

const BASE_COLOR_DISABLED = rl.BASE_COLOR_DISABLED;
//const BORDER = rl.BORDER;
const BORDER = 0;
const BORDER_COLOR_DISABLED = rl.BORDER_COLOR_DISABLED;
const BORDER_WIDTH = rl.BORDER_WIDTH;
const COLORPICKER = rl.COLORPICKER;
const HUEBAR_SELECTOR_HEIGHT = rl.HUEBAR_SELECTOR_HEIGHT;
const HUEBAR_SELECTOR_OVERFLOW = rl.HUEBAR_SELECTOR_OVERFLOW;
const MOUSE_BUTTON_LEFT = rl.MOUSE_BUTTON_LEFT;
const STATE_DISABLED = rl.STATE_DISABLED;
const STATE_FOCUSED = rl.STATE_FOCUSED;
const STATE_PRESSED = rl.STATE_PRESSED;
// const guiAlpha = rl.guiAlpha;
// TODO: rl.GuiSetAlpha
const guiAlpha = 0.8;
var guiControlExclusiveMode = false;
// const guiControlExclusiveMode = rl.guiControlExclusiveMode;
pub var guiControlExclusiveRec: Rectangle = Rectangle{ .x = 0, .y = 0, .width = 0, .height = 0 };
// const guiControlExclusiveRec = rl.guiControlExclusiveRec;

const ffi = cnv.ffi;
const iff = cnv.iff;
const rgb = cnv.rgb;

const CheckCollisionPointRec = rl.CheckCollisionPointRec;
const DrawRectangle = rl.DrawRectangle;
const DrawRectangleGradientH = rl.DrawRectangleGradientH;
const Fade = rl.Fade;
const GetColor = rl.GetColor;
const GetMousePosition = rl.GetMousePosition;
const GuiGetState = rl.GuiGetState;
const GuiGetStyle = rl.GuiGetStyle;
const GuiIsLocked = rl.GuiIsLocked;
const IsMouseButtonDown = rl.IsMouseButtonDown;

const Color = rl.Color;
const GuiState = rl.GuiState;
const Rectangle = rl.Rectangle;
const Vector2 = rl.Vector2;

pub fn GuiColorBarHueH(bounds: Rectangle, text: [*c]const u8, hue: [*c]f32) c_int {
    _ = text; // TODO: Draw text
    var state: c_int = GuiGetState();

    const selector_height = @as(f32, @floatFromInt(GuiGetStyle(COLORPICKER, HUEBAR_SELECTOR_HEIGHT)));
    const selector_overflow = @as(f32, @floatFromInt(GuiGetStyle(COLORPICKER, HUEBAR_SELECTOR_OVERFLOW)));

    const selector: Rectangle = Rectangle{
        .x = (bounds.x + ((hue.* / 360.0) * bounds.width)) - (selector_height / 2),
        .y = bounds.y - selector_overflow,
        .width = selector_height,
        .height = bounds.height + selector_overflow * 2,
    };
    if (state != STATE_DISABLED and !GuiIsLocked()) {
        const mousePoint: Vector2 = GetMousePosition();
        if (guiControlExclusiveMode) {
            if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
                if (bounds.x == guiControlExclusiveRec.x and
                    bounds.y == guiControlExclusiveRec.y and
                    bounds.width == guiControlExclusiveRec.width and
                    bounds.height == guiControlExclusiveRec.height)
                {
                    state = STATE_PRESSED;
                    hue.* = ((mousePoint.x - bounds.x) * 360) / bounds.width;
                    hue.* = std.math.clamp(hue.*, 0, 359);
                }
            } else {
                guiControlExclusiveMode = false;
                guiControlExclusiveRec = Rectangle{ .x = 0, .y = 0, .width = 0, .height = 0 };
            }
        } else if (CheckCollisionPointRec(mousePoint, bounds) or CheckCollisionPointRec(mousePoint, selector)) {
            if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
                state = STATE_PRESSED;
                guiControlExclusiveMode = true;
                guiControlExclusiveRec = bounds;
                hue.* = ((mousePoint.x - bounds.x) * 360) / bounds.width;
                hue.* = std.math.clamp(hue.*, 0, 359);
            } else {
                state = STATE_FOCUSED;
            }
        }
    }
    const HUE_GRADIENTS = [_]struct { Color, Color }{
        .{ rgb(255, 0, 0), rgb(255, 255, 0) },
        .{ rgb(255, 255, 0), rgb(0, 255, 0) },
        .{ rgb(0, 255, 0), rgb(0, 255, 255) },
        .{ rgb(0, 255, 255), rgb(0, 0, 255) },
        .{ rgb(0, 0, 255), rgb(255, 0, 255) },
        .{ rgb(255, 0, 255), rgb(255, 0, 0) },
    };
    if (state != STATE_DISABLED) {
        const seg_w = @ceil(bounds.width / 6);
        inline for (HUE_GRADIENTS, 0..) |hg, i| {
            const start, const end = hg;
            rl.DrawRectangleGradientEx(
                .{ .x = bounds.x + (i * bounds.width / HUE_GRADIENTS.len), .y = bounds.y, .width = seg_w, .height = bounds.height },
                Fade(start, guiAlpha),
                Fade(start, guiAlpha),
                Fade(end, guiAlpha),
                Fade(end, guiAlpha),
            );
        }
    } else {
        rl.DrawRectangleGradientEx(
            bounds,
            Fade(Fade(GetColor(@intCast(GuiGetStyle(COLORPICKER, BASE_COLOR_DISABLED))), 0.1), guiAlpha),
            Fade(Fade(GetColor(@intCast(GuiGetStyle(COLORPICKER, BASE_COLOR_DISABLED))), 0.1), guiAlpha),
            Fade(GetColor(@intCast(GuiGetStyle(COLORPICKER, BORDER_COLOR_DISABLED))), guiAlpha),
            Fade(GetColor(@intCast(GuiGetStyle(COLORPICKER, BORDER_COLOR_DISABLED))), guiAlpha),
        );
    }
    const borderColor = GetColor(@bitCast(GuiGetStyle(COLORPICKER, BORDER + state * 3)));
    const borderWidth = GuiGetStyle(COLORPICKER, BORDER_WIDTH);
    GuiDrawRectangle(bounds, borderWidth, borderColor, .{});
    GuiDrawRectangle(selector, 0, .{}, borderColor);
    return 0;
}

pub fn GuiDrawRectangle(rec: Rectangle, borderWidth: c_int, borderColor: Color, color: Color) void {
    if (color.a > 0) rl.DrawRectangleRec(rec, GuiFade(color, guiAlpha));

    if (borderWidth > 0) {
        const bw: f32 = @floatFromInt(borderWidth);
        const b_color = GuiFade(borderColor, guiAlpha);
        // zig fmt: off
        rl.DrawRectangleRec(.{ .x = rec.x,                  .y = rec.y,                   .width = rec.width, .height = bw },                    b_color);
        rl.DrawRectangleRec(.{ .x = rec.x,                  .y = rec.y + bw,              .width = bw,        .height = rec.height - (2 * bw) }, b_color);
        rl.DrawRectangleRec(.{ .x = rec.x + rec.width - bw, .y = rec.y + bw,              .width = bw,        .height = rec.height - (2 * bw) }, b_color);
        rl.DrawRectangleRec(.{ .x = rec.x,                  .y = rec.y + rec.height - bw, .width = rec.width, .height = bw },                    b_color);
        // zig fmt: on
    }
}

// const GuiFade = rl.GuiFade;
pub fn GuiFade(color: Color, alpha: f32) Color {
    const a = std.math.clamp(alpha, 0, 1);
    return .{ .r = color.r, .g = color.g, .b = color.b, .a = iff(u8, ffi(f32, color.a) * a) };
}
