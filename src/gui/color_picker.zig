const rl = @import("../raylib.zig");
const Rectangle = rl.Rectangle;
const GuiState = rl.GuiState;
const GuiGetState = rl.GuiGetState;
const GuiGetStyle = rl.GuiGetStyle;
const GuiIsLocked = rl.GuiIsLocked;
const COLORPICKER: c_int = rl.COLORPICKER;
const HUEBAR_SELECTOR_HEIGHT: c_int = rl.HUEBAR_SELECTOR_HEIGHT;
const HUEBAR_SELECTOR_OVERFLOW: c_int = rl.HUEBAR_SELECTOR_OVERFLOW;
const STATE_DISABLED: c_int = rl.STATE_DISABLED;
const GetMousePosition = rl.GetMousePos;
const Vector2 = rl.Vector2;
const guiControlExclusiveMode = rl.guiControlExclusiveMode;
const IsMouseButtonDown = rl.IsMouseButtonDown;
const MOUSE_BUTTON_LEFT = rl.MOUSE_BUTTON_LEFT;
const guiControlExclusiveRec = rl.guiControlExclusiveRec;
const STATE_PRESSED = rl.STATE_PRESSED;
const CheckCollisionPointRec = rl.CheckCollisionPointRec;
const STATE_FOCUSED = rl.STATE_FOCUSED;
const DrawRectangleGradientH = rl.DrawRectangleGradientH;
const ceilf = rl.ceilf;
const Fade = rl.Fade;
const Color = rl.Color;
const guiAlpha = rl.guiAlpha;
const GetColor = rl.GetColor;
const BASE_COLOR_DISABLED = rl.BASE_COLOR_DISABLED;
const BORDER_COLOR_DISABLED = rl.BORDER_COLOR_DISABLED;
const GuiDrawRectangle = rl.GuiDrawRectangle;
const BORDER_WIDTH = rl.BORDER_WIDTH;
const BORDER = rl.BORDER;

pub fn GuiColorBarHueH(arg_bounds: Rectangle, arg_text: [*c]const u8, arg_hue: [*c]f32) c_int {
    var bounds = arg_bounds;
    _ = &bounds;
    var text = arg_text;
    _ = &text;
    var hue = arg_hue;
    _ = &hue;
    var result: c_int = 0;
    _ = &result;
    var state: GuiState = GuiGetState();
    _ = &state;
    var selector: Rectangle = Rectangle{
        .x = (bounds.x + ((hue.* / 360.0) * bounds.width)) - @as(f32, @floatFromInt(@divTrunc(GuiGetStyle(COLORPICKER, HUEBAR_SELECTOR_HEIGHT), @as(c_int, 2)))),
        .y = bounds.y - @as(f32, @floatFromInt(GuiGetStyle(COLORPICKER, HUEBAR_SELECTOR_OVERFLOW))),
        .width = @as(f32, @floatFromInt(GuiGetStyle(COLORPICKER, HUEBAR_SELECTOR_HEIGHT))),
        .height = bounds.height + @as(f32, @floatFromInt(GuiGetStyle(COLORPICKER, HUEBAR_SELECTOR_OVERFLOW) * @as(c_int, 2))),
    };
    _ = &selector;
    if ((state != @as(c_uint, @bitCast(STATE_DISABLED))) and !GuiIsLocked()) {
        var mousePoint: Vector2 = GetMousePosition();
        _ = &mousePoint;
        if (guiControlExclusiveMode) {
            if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
                if ((((bounds.x == guiControlExclusiveRec.x) and (bounds.y == guiControlExclusiveRec.y)) and (bounds.width == guiControlExclusiveRec.width)) and (bounds.height == guiControlExclusiveRec.height)) {
                    state = @as(c_uint, @bitCast(STATE_PRESSED));
                    hue.* = ((mousePoint.x - bounds.x) * @as(f32, @floatFromInt(@as(c_int, 360)))) / bounds.width;
                    if (hue.* <= 0.0) {
                        hue.* = 0.0;
                    }
                    if (hue.* >= 359.0) {
                        hue.* = 359.0;
                    }
                }
            } else {
                guiControlExclusiveMode = @as(c_int, 0) != 0;
                guiControlExclusiveRec = Rectangle{
                    .x = @as(f32, @floatFromInt(@as(c_int, 0))),
                    .y = @as(f32, @floatFromInt(@as(c_int, 0))),
                    .width = @as(f32, @floatFromInt(@as(c_int, 0))),
                    .height = @as(f32, @floatFromInt(@as(c_int, 0))),
                };
            }
        } else if ((@as(c_int, @intFromBool(CheckCollisionPointRec(mousePoint, bounds))) != 0) or (@as(c_int, @intFromBool(CheckCollisionPointRec(mousePoint, selector))) != 0)) {
            if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
                state = @as(c_uint, @bitCast(STATE_PRESSED));
                guiControlExclusiveMode = @as(c_int, 1) != 0;
                guiControlExclusiveRec = bounds;
                hue.* = ((mousePoint.x - bounds.x) * @as(f32, @floatFromInt(@as(c_int, 360)))) / bounds.width;
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
        DrawRectangleGradientH(@as(c_int, @intFromFloat(bounds.x)), @as(c_int, @intFromFloat(bounds.y)), @as(c_int, @intFromFloat(ceilf(bounds.width / @as(f32, @floatFromInt(@as(c_int, 6)))))), @as(c_int, @intFromFloat(bounds.height)), Fade(Color{
            .r = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .g = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .b = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .a = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
        }, guiAlpha), Fade(Color{
            .r = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .g = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .b = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .a = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
        }, guiAlpha));
        DrawRectangleGradientH(@as(c_int, @intFromFloat(bounds.x + (bounds.width / @as(f32, @floatFromInt(@as(c_int, 6)))))), @as(c_int, @intFromFloat(bounds.y)), @as(c_int, @intFromFloat(ceilf(bounds.width / @as(f32, @floatFromInt(@as(c_int, 6)))))), @as(c_int, @intFromFloat(bounds.height)), Fade(Color{
            .r = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .g = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .b = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .a = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
        }, guiAlpha), Fade(Color{
            .r = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .g = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .b = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .a = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
        }, guiAlpha));
        DrawRectangleGradientH(@as(c_int, @intFromFloat(bounds.x + (@as(f32, @floatFromInt(@as(c_int, 2))) * (bounds.width / @as(f32, @floatFromInt(@as(c_int, 6))))))), @as(c_int, @intFromFloat(bounds.y)), @as(c_int, @intFromFloat(ceilf(bounds.width / @as(f32, @floatFromInt(@as(c_int, 6)))))), @as(c_int, @intFromFloat(bounds.height)), Fade(Color{
            .r = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .g = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .b = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .a = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
        }, guiAlpha), Fade(Color{
            .r = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .g = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .b = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .a = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
        }, guiAlpha));
        DrawRectangleGradientH(@as(c_int, @intFromFloat(bounds.x + (@as(f32, @floatFromInt(@as(c_int, 3))) * (bounds.width / @as(f32, @floatFromInt(@as(c_int, 6))))))), @as(c_int, @intFromFloat(bounds.y)), @as(c_int, @intFromFloat(ceilf(bounds.width / @as(f32, @floatFromInt(@as(c_int, 6)))))), @as(c_int, @intFromFloat(bounds.height)), Fade(Color{
            .r = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .g = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .b = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .a = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
        }, guiAlpha), Fade(Color{
            .r = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .g = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .b = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .a = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
        }, guiAlpha));
        DrawRectangleGradientH(@as(c_int, @intFromFloat(bounds.x + (@as(f32, @floatFromInt(@as(c_int, 4))) * (bounds.width / @as(f32, @floatFromInt(@as(c_int, 6))))))), @as(c_int, @intFromFloat(bounds.y)), @as(c_int, @intFromFloat(ceilf(bounds.width / @as(f32, @floatFromInt(@as(c_int, 6)))))), @as(c_int, @intFromFloat(bounds.height)), Fade(Color{
            .r = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .g = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .b = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .a = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
        }, guiAlpha), Fade(Color{
            .r = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .g = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .b = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .a = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
        }, guiAlpha));
        DrawRectangleGradientH(@as(c_int, @intFromFloat(bounds.x + (@as(f32, @floatFromInt(@as(c_int, 5))) * (bounds.width / @as(f32, @floatFromInt(@as(c_int, 6))))))), @as(c_int, @intFromFloat(bounds.y)), @as(c_int, @intFromFloat(bounds.width / @as(f32, @floatFromInt(@as(c_int, 6))))), @as(c_int, @intFromFloat(bounds.height)), Fade(Color{
            .r = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .g = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .b = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .a = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
        }, guiAlpha), Fade(Color{
            .r = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
            .g = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .b = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
            .a = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 255))))),
        }, guiAlpha));
    } else {
        DrawRectangleGradientH(@as(c_int, @intFromFloat(bounds.x)), @as(c_int, @intFromFloat(bounds.y)), @as(c_int, @intFromFloat(bounds.width)), @as(c_int, @intFromFloat(bounds.height)), Fade(Fade(GetColor(@as(c_uint, @bitCast(GuiGetStyle(COLORPICKER, BASE_COLOR_DISABLED)))), 0.10000000149011612), guiAlpha), Fade(GetColor(@as(c_uint, @bitCast(GuiGetStyle(COLORPICKER, BORDER_COLOR_DISABLED)))), guiAlpha));
    }
    GuiDrawRectangle(bounds, GuiGetStyle(COLORPICKER, BORDER_WIDTH), GetColor(@as(c_uint, @bitCast(GuiGetStyle(COLORPICKER, @as(c_int, @bitCast(@as(c_uint, @bitCast(BORDER)) +% (state *% @as(c_uint, @bitCast(@as(c_int, 3)))))))))), Color{
        .r = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
        .g = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
        .b = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
        .a = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
    });
    GuiDrawRectangle(selector, @as(c_int, 0), Color{
        .r = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
        .g = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
        .b = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
        .a = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))),
    }, GetColor(@as(c_uint, @bitCast(GuiGetStyle(COLORPICKER, @as(c_int, @bitCast(@as(c_uint, @bitCast(BORDER)) +% (state *% @as(c_uint, @bitCast(@as(c_int, 3)))))))))));
    return result;
}
