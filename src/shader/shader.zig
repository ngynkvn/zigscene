const std = @import("std");
const rl = @import("../raylib.zig");
const Config = @import("../core/config.zig");

const fragment_source = @embedFile("chromatic.fs.glsl");
const vertex_source = @embedFile("chromatic.vs.glsl");

pub const Renderer = struct {
    scene_texture: rl.RenderTexture2D,
    program: rl.Shader,
    chroma_factor_location: c_int,
    noise_factor_location: c_int,

    pub fn init() Renderer {
        const program = rl.LoadShaderFromMemory(vertex_source, fragment_source);
        const chroma = rl.rlGetLocationUniform(program.id, "chromaFactor");
        const noise = rl.rlGetLocationUniform(program.id, "noiseFactor");
        std.debug.assert(chroma != -1);
        std.debug.assert(noise != -1);
        return .{
            .scene_texture = rl.LoadRenderTexture(Config.Window.width, Config.Window.height),
            .program = program,
            .chroma_factor_location = chroma,
            .noise_factor_location = noise,
        };
    }

    pub fn deinit(self: *Renderer) void {
        rl.UnloadRenderTexture(self.scene_texture);
        rl.UnloadShader(self.program);
        self.* = undefined;
    }

    pub fn resize(self: *Renderer, width: i32, height: i32) void {
        rl.UnloadRenderTexture(self.scene_texture);
        self.scene_texture = rl.LoadRenderTexture(width, height);
    }
};
