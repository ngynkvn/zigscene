const std = @import("std");
const rl = @import("raylibz");

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
    rl.unloadRenderTexture(sceneTexture);
    sceneTexture = rl.loadRenderTexture(screenWidth, screenHeight);
}

var fs = @embedFile("chromatic.fs.glsl");
var vs = @embedFile("chromatic.vs.glsl");

// TODO: make the shader program swappable and adjust options as needed
pub fn init() void {
    sceneTexture = rl.loadRenderTexture(screenWidth, screenHeight);
    program = rl.loadShaderFromMemory(vs, fs);
    chromaFactorLoc = rl.getLocationUniform(program, "chromaFactor");
    noiseFactorLoc = rl.getLocationUniform(program, "noiseFactor");
    std.debug.assert(chromaFactorLoc != -1);
    std.debug.assert(noiseFactorLoc != -1);
}
