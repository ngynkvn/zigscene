pub const rl = @import("raylib");
const colorPicker = @import("gui/color_picker.zig");
pub const GuiColorBarHueH = colorPicker.GuiColorBarHueH;
pub const AttachAudioMixedProcessor = rl.AttachAudioMixedProcessor;
pub const BASE_COLOR_DISABLED = rl.BASE_COLOR_DISABLED;
pub const BeginDrawing = rl.BeginDrawing;
pub const BeginMode3D = rl.BeginMode3D;
pub const BeginShaderMode = rl.BeginShaderMode;
pub const BeginTextureMode = rl.BeginTextureMode;
pub const BLUE = rl.BLUE;
pub const BORDER = rl.BORDER;
pub const BORDER_COLOR_DISABLED = rl.BORDER_COLOR_DISABLED;
pub const BORDER_WIDTH = rl.BORDER_WIDTH;
pub const CAMERA_ORTHOGRAPHIC = rl.CAMERA_ORTHOGRAPHIC;
pub const CAMERA_PERSPECTIVE = rl.CAMERA_PERSPECTIVE;
pub const Camera3D = rl.Camera3D;
pub const CheckCollisionPointRec = rl.CheckCollisionPointRec;
pub const ClearBackground = rl.ClearBackground;
pub const CloseAudioDevice = rl.CloseAudioDevice;
pub const CloseWindow = rl.CloseWindow;
pub const Color = rl.Color;
pub const COLORPICKER = rl.COLORPICKER;
pub const DrawCubeWires = rl.DrawCubeWires;
pub const DrawRectangleGradientEx = rl.DrawRectangleGradientEx;
pub const DrawRectangleRec = rl.DrawRectangleRec;
pub const DrawSphereWires = rl.DrawSphereWires;
pub const DrawText = rl.DrawText;
pub const DrawTextureRec = rl.DrawTextureRec;
pub const EndDrawing = rl.EndDrawing;
pub const EndMode3D = rl.EndMode3D;
pub const EndShaderMode = rl.EndShaderMode;
pub const EndTextureMode = rl.EndTextureMode;
pub const Fade = rl.Fade;
pub const FLAG_BORDERLESS_WINDOWED_MODE = rl.FLAG_BORDERLESS_WINDOWED_MODE;
pub const FLAG_WINDOW_RESIZABLE = rl.FLAG_WINDOW_RESIZABLE;
pub const FLAG_WINDOW_TOPMOST = rl.FLAG_WINDOW_TOPMOST;
pub const FLAG_WINDOW_TRANSPARENT = rl.FLAG_WINDOW_TRANSPARENT;
pub const GetColor = rl.GetColor;
pub const GetFileName = rl.GetFileName;
pub const GetFPS = rl.GetFPS;
pub const GetFrameTime = rl.GetFrameTime;
pub const GetMouseDelta = rl.GetMouseDelta;
pub const GetMousePosition = rl.GetMousePosition;
pub const GetMouseWheelMoveV = rl.GetMouseWheelMoveV;
pub const GetMusicTimeLength = rl.GetMusicTimeLength;
pub const GetMusicTimePlayed = rl.GetMusicTimePlayed;
pub const GetScreenHeight = rl.GetScreenHeight;
pub const GetScreenWidth = rl.GetScreenWidth;
pub const GetWorldToScreen = rl.GetWorldToScreen;
pub const guiAlpha = rl.guiAlpha;
pub const GuiButton = rl.GuiButton;
pub const guiControlExclusiveMode = rl.guiControlExclusiveMode;
pub const guiControlExclusiveRec = rl.guiControlExclusiveRec;
pub const GuiFade = rl.GuiFade;
pub const GuiGetState = rl.GuiGetState;
pub const GuiGetStyle = rl.GuiGetStyle;
pub const GuiIsLocked = rl.GuiIsLocked;
pub const GuiLabel = rl.GuiLabel;
pub const GuiPanel = rl.GuiPanel;
pub const GuiSetAlpha = rl.GuiSetAlpha;
pub const GuiSlider = rl.GuiSlider;
pub const GuiSliderBar = rl.GuiSliderBar;
pub const GuiStatusBar = rl.GuiStatusBar;
pub const GuiToggleGroup = rl.GuiToggleGroup;
pub const GuiValueBoxFloat = rl.GuiValueBoxFloat;
pub const HUEBAR_SELECTOR_HEIGHT = rl.HUEBAR_SELECTOR_HEIGHT;
pub const HUEBAR_SELECTOR_OVERFLOW = rl.HUEBAR_SELECTOR_OVERFLOW;
pub const ICON_ARROW_LEFT = rl.ICON_ARROW_LEFT;
pub const ICON_COLOR_PICKER = rl.ICON_COLOR_PICKER;
pub const ICON_FX = rl.ICON_FX;
pub const ICON_PLAYER_PAUSE = rl.ICON_PLAYER_PAUSE;
pub const ICON_PLAYER_PLAY = rl.ICON_PLAYER_PLAY;
pub const InitAudioDevice = rl.InitAudioDevice;
pub const InitWindow = rl.InitWindow;
pub const IsFileDropped = rl.IsFileDropped;
pub const IsMouseButtonDown = rl.IsMouseButtonDown;
pub const IsMusicStreamPlaying = rl.IsMusicStreamPlaying;
pub const IsMusicValid = rl.IsMusicValid;
pub const IsWindowResized = rl.IsWindowResized;
pub const IsWindowState = rl.IsWindowState;
pub const LoadDroppedFiles = rl.LoadDroppedFiles;
pub const LoadMusicStream = rl.LoadMusicStream;
pub const LoadRenderTexture = rl.LoadRenderTexture;
pub const LoadShaderFromMemory = rl.LoadShaderFromMemory;
pub const MOUSE_BUTTON_LEFT = rl.MOUSE_BUTTON_LEFT;
pub const MOUSE_LEFT_BUTTON = rl.MOUSE_LEFT_BUTTON;
pub const Music = rl.Music;
pub const PauseMusicStream = rl.PauseMusicStream;
pub const PlayMusicStream = rl.PlayMusicStream;
pub const RayguiDark = rl.RayguiDark;
pub const RAYWHITE = rl.RAYWHITE;
pub const Rectangle = rl.Rectangle;
pub const RED = rl.RED;
pub const RenderTexture2D = rl.RenderTexture2D;
pub const ResumeMusicStream = rl.ResumeMusicStream;
pub const RL_SHADER_UNIFORM_FLOAT = rl.RL_SHADER_UNIFORM_FLOAT;
pub const rlGetLocationUniform = rl.rlGetLocationUniform;
pub const rlPopMatrix = rl.rlPopMatrix;
pub const rlPushMatrix = rl.rlPushMatrix;
pub const rlRotatef = rl.rlRotatef;
pub const rlTranslatef = rl.rlTranslatef;
pub const SeekMusicStream = rl.SeekMusicStream;
pub const SetConfigFlags = rl.SetConfigFlags;
pub const SetMasterVolume = rl.SetMasterVolume;
pub const SetShaderValue = rl.SetShaderValue;
pub const SetWindowPosition = rl.SetWindowPosition;
pub const Shader = rl.Shader;
pub const STATE_DISABLED = rl.STATE_DISABLED;
pub const STATE_FOCUSED = rl.STATE_FOCUSED;
pub const STATE_PRESSED = rl.STATE_PRESSED;
pub const ToggleBorderlessWindowed = rl.ToggleBorderlessWindowed;
pub const UnloadDroppedFiles = rl.UnloadDroppedFiles;
pub const UnloadRenderTexture = rl.UnloadRenderTexture;
pub const UpdateMusicStream = rl.UpdateMusicStream;
pub const Vector2 = rl.Vector2;
pub const Vector3 = rl.Vector3;
pub const WHITE = rl.WHITE;
pub const WindowShouldClose = rl.WindowShouldClose;

// zig fmt: off
pub const Key = enum(c_int) {
    NULL = 0,
    APOSTROPHE = 39, COMMA = 44, MINUS = 45, PERIOD = 46, SLASH = 47,
    ZERO       = 48, ONE   = 49, TWO   = 50, THREE  = 51, FOUR  = 52,
    FIVE       = 53, SIX   = 54, SEVEN = 55, EIGHT  = 56, NINE  = 57,
    SEMICOLON  = 59, EQUAL = 61,

    A = 65, B = 66, C = 67, D = 68, E = 69, F = 70, G = 71,
    H = 72, I = 73, J = 74, K = 75, L = 76, M = 77, N = 78,
    O = 79, P = 80, Q = 81, R = 82, S = 83, T = 84, U = 85,
    V = 86, W = 87, X = 88, Y = 89, Z = 90,

    LEFT_BRACKET = 91,  BACKSLASH     = 92,  RIGHT_BRACKET = 93,
    GRAVE        = 96,  SPACE         = 32,  ESCAPE        = 256, ENTER       = 257, TAB          = 258,
    BACKSPACE    = 259, INSERT        = 260, DELETE        = 261, RIGHT       = 262, LEFT         = 263,
    DOWN         = 264, UP            = 265, PAGE_UP       = 266, PAGE_DOWN   = 267, HOME         = 268,
    END          = 269, CAPS_LOCK     = 280, SCROLL_LOCK   = 281, NUM_LOCK    = 282, PRINT_SCREEN = 283, PAUSE = 284,
    F1           = 290, F2            = 291, F3            = 292, F4          = 293, F5           = 294, F6    = 295,
    F7           = 296, F8            = 297, F9            = 298, F10         = 299, F11          = 300, F12   = 301,
    LEFT_SHIFT   = 340, LEFT_CONTROL  = 341, LEFT_ALT      = 342, LEFT_SUPER  = 343,
    RIGHT_SHIFT  = 344, RIGHT_CONTROL = 345, RIGHT_ALT     = 346, RIGHT_SUPER = 347,
    KB_MENU      = 348,

    KP_0 = 320, KP_1 = 321, KP_2 = 322,
    KP_3 = 323, KP_4 = 324, KP_5 = 325,
    KP_6 = 326, KP_7 = 327, KP_8 = 328,
    KP_9 = 329,

    KP_DECIMAL  = 330, KP_DIVIDE   = 331,
    KP_MULTIPLY = 332, KP_SUBTRACT = 333,
    KP_ADD      = 334, KP_ENTER    = 335, KP_EQUAL = 336,
    BACK        = 4,   MENU        = 5,
    VOLUME_UP   = 24,  VOLUME_DOWN = 25,

    fn c(self: Key) c_int {
        return @intFromEnum(self);
    }
};

pub fn isKeyUp(k: Key) bool { return rl.IsKeyUp(k.c()); }
pub fn isKeyDown(k: Key) bool { return rl.IsKeyDown(k.c()); }
pub fn isKeyPressed(k: Key) bool { return rl.IsKeyPressed(k.c()); }
pub fn isKeyReleased(k: Key) bool { return rl.IsKeyReleased(k.c()); }
// zig fmt: on
