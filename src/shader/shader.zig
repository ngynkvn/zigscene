const std = @import("std");
pub const rl = @import("../raylib.zig");
pub const Config = @import("../core/config.zig");

pub var sceneTexture: rl.RenderTexture2D = undefined;
pub var program: rl.Shader = undefined;
pub var chromaFactorLoc: c_int = undefined;
pub var noiseFactorLoc: c_int = undefined;

pub var screenWidth: c_int = Config.Window.width;
pub var screenHeight: c_int = Config.Window.height;
pub fn onWindowResize(width: i32, height: i32) void {
    screenWidth = width;
    screenHeight = height;
    rl.UnloadRenderTexture(sceneTexture);
    sceneTexture = rl.LoadRenderTexture(screenWidth, screenHeight);
}

var fs = @embedFile("chromatic.fs.glsl");
var vs = @embedFile("chromatic.vs.glsl");

// TODO: make the shader program swappable and adjust options as needed
pub fn init() void {
    sceneTexture = rl.LoadRenderTexture(screenWidth, screenHeight);
    program = rl.LoadShaderFromMemory(vs, fs);
    chromaFactorLoc = rl.rlGetLocationUniform(program.id, "chromaFactor");
    noiseFactorLoc = rl.rlGetLocationUniform(program.id, "noiseFactor");
    std.debug.assert(chromaFactorLoc != -1);
    std.debug.assert(noiseFactorLoc != -1);
}
