const std = @import("std");
const builtin = @import("builtin");
const rl = @import("../raylib.zig");
const Config = @import("../core/config.zig");

/// Desktop uses OpenGL 3.3; the browser build runs raylib on OpenGL ES 2 /
/// WebGL, which only accepts GLSL ES 1.00. Both share one shader body.
const web = builtin.os.tag == .emscripten;
const vertex_prelude = if (web)
    \\#version 100
    \\attribute vec3 vertexPosition;
    \\attribute vec2 vertexTexCoord;
    \\attribute vec4 vertexColor;
    \\varying vec2 fragTexCoord;
    \\varying vec4 fragColor;
    \\
else
    \\#version 330
    \\in vec3 vertexPosition;
    \\in vec2 vertexTexCoord;
    \\in vec4 vertexColor;
    \\out vec2 fragTexCoord;
    \\out vec4 fragColor;
    \\
;
const fragment_prelude = if (web)
    \\#version 100
    \\#ifdef GL_FRAGMENT_PRECISION_HIGH
    \\precision highp float;
    \\#else
    \\precision mediump float;
    \\#endif
    \\varying vec2 fragTexCoord;
    \\varying vec4 fragColor;
    \\#define texture texture2D
    \\#define finalColor gl_FragColor
    \\
else
    \\#version 330
    \\in vec2 fragTexCoord;
    \\in vec4 fragColor;
    \\out vec4 finalColor;
    \\
;
const fragment_source = fragment_prelude ++ @embedFile("chromatic.fs.glsl");
const vertex_source = vertex_prelude ++ @embedFile("chromatic.vs.glsl");

pub const Renderer = struct {
    scene_texture: rl.RenderTexture2D,
    program: rl.Shader,
    chroma_factor_location: c_int,
    noise_factor_location: c_int,
    background_alpha_location: c_int,
    time_location: c_int,

    pub fn init() Renderer {
        const program = rl.LoadShaderFromMemory(vertex_source, fragment_source);
        const renderer: Renderer = .{
            .scene_texture = rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight()),
            .program = program,
            .chroma_factor_location = rl.rlGetLocationUniform(program.id, "chromaFactor"),
            .noise_factor_location = rl.rlGetLocationUniform(program.id, "noiseFactor"),
            .background_alpha_location = rl.rlGetLocationUniform(program.id, "backgroundAlpha"),
            .time_location = rl.rlGetLocationUniform(program.id, "time"),
        };
        // A driver that rejects the shader leaves raylib's default shader in
        // place. The scene still renders, only without the post effects, and
        // raylib ignores uniform writes to missing (-1) locations.
        if (renderer.chroma_factor_location == -1 or renderer.noise_factor_location == -1) {
            rl.rl.TraceLog(rl.rl.LOG_WARNING, "zigscene: post-processing shader unavailable; rendering without chroma and noise");
        }
        return renderer;
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

    /// Per-frame post-effect uniforms. Call inside `BeginShaderMode(program)`.
    pub fn setUniforms(self: *const Renderer, time: f32, noise_factor: f32) void {
        const background_alpha = std.math.clamp(Config.Shader.alpha_factor, 0, 1);
        const wrapped_time = @mod(time, 1000);
        rl.SetShaderValue(self.program, self.chroma_factor_location, &Config.Shader.chroma_factor, rl.RL_SHADER_UNIFORM_FLOAT);
        rl.SetShaderValue(self.program, self.noise_factor_location, &noise_factor, rl.RL_SHADER_UNIFORM_FLOAT);
        rl.SetShaderValue(self.program, self.background_alpha_location, &background_alpha, rl.RL_SHADER_UNIFORM_FLOAT);
        rl.SetShaderValue(self.program, self.time_location, &wrapped_time, rl.RL_SHADER_UNIFORM_FLOAT);
    }
};

test "both shader variants declare a GLSL version first" {
    try std.testing.expect(std.mem.startsWith(u8, fragment_source, "#version "));
    try std.testing.expect(std.mem.startsWith(u8, vertex_source, "#version "));
    // Shared bodies must not carry their own version directive.
    try std.testing.expect(std.mem.indexOf(u8, fragment_source[1..], "#version") == null);
    try std.testing.expect(std.mem.indexOf(u8, vertex_source[1..], "#version") == null);
}
