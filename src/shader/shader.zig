const std = @import("std");
pub const rl = @import("../raylib.zig");
pub const Config = @import("../core/config.zig");

pub var sceneTexture: rl.RenderTexture2D = undefined;
pub var program: rl.Shader = undefined;
pub var amountLoc: c_int = undefined;

pub var screenWidth: c_int = Config.Window.width;
pub var screenHeight: c_int = Config.Window.height;

var fs = @embedFile("chromatic.fs.glsl");
var vs = @embedFile("chromatic.vs.glsl");

pub fn init() void {
    sceneTexture = rl.LoadRenderTexture(screenWidth, screenHeight);
    program = rl.LoadShaderFromMemory(vs, fs);
    amountLoc = rl.rlGetLocationUniform(program.id, "amount");
    std.debug.assert(amountLoc != -1);
}

pub fn resized(sw: c_int, sh: c_int) void {
    screenWidth = sw;
    screenHeight = sh;
    rl.UnloadRenderTexture(sceneTexture);
    sceneTexture = rl.LoadRenderTexture(screenWidth, screenHeight);
}
