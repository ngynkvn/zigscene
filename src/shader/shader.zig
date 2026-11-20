const std = @import("std");
const builtin = @import("builtin");
const rl = @import("../raylib.zig");
const Config = @import("../core/config.zig");
const Motion = @import("../graphics/Motion.zig");
const Viewport = @import("../graphics/Viewport.zig");

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
const marbling_source = fragment_prelude ++ @embedFile("marbling.fs.glsl");
const vertex_source = vertex_prelude ++ @embedFile("chromatic.vs.glsl");

pub const Renderer = struct {
    scene_texture: rl.RenderTexture2D,
    program: rl.Shader,
    marbling: Marbling,
    chroma_factor_location: c_int,
    noise_factor_location: c_int,
    background_alpha_location: c_int,
    time_location: c_int,

    pub fn init() Renderer {
        const program = rl.LoadShaderFromMemory(vertex_source, fragment_source);
        const renderer: Renderer = .{
            .scene_texture = rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight()),
            .program = program,
            .marbling = .init(),
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
        rl.UnloadShader(self.marbling.program);
        self.* = undefined;
    }

    pub fn resize(self: *Renderer, width: i32, height: i32) void {
        rl.UnloadRenderTexture(self.scene_texture);
        self.scene_texture = rl.LoadRenderTexture(width, height);
    }

    pub fn drawMarbling(self: *Renderer, viewport: Viewport, motion: Motion, tint: rl.Color) void {
        self.marbling.draw(self.scene_texture.texture, viewport, motion, tint);
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

const Marbling = struct {
    program: rl.Shader,
    flow_location: c_int,
    finish_location: c_int,
    phase: f32 = 0,

    fn init() Marbling {
        const program = rl.LoadShaderFromMemory(vertex_source, marbling_source);
        const marbling: Marbling = .{
            .program = program,
            .flow_location = rl.rlGetLocationUniform(program.id, "flow"),
            .finish_location = rl.rlGetLocationUniform(program.id, "surfaceFinish"),
        };
        if (marbling.flow_location < 0 or marbling.finish_location < 0) {
            rl.rl.TraceLog(rl.rl.LOG_WARNING, "zigscene: marbling shader unavailable");
        }
        return marbling;
    }

    fn draw(self: *Marbling, texture: rl.rl.Texture2D, viewport: Viewport, motion: Motion, tint: rl.Color) void {
        const width = viewport.width();
        const height = viewport.height();
        if (self.flow_location < 0 or self.finish_location < 0 or tint.a == 0) return;

        const config = Config.Marbling;
        const dt = std.math.clamp(rl.GetFrameTime(), 0, 0.1);
        const audio_speed = config.response * (motion.energy + 0.35 * motion.pulse);
        self.phase = @mod(self.phase + dt * config.speed * (1 + audio_speed), 2 * std.math.pi);
        const distortion = config.distortion * (1 + 0.25 * config.response * motion.pulse);
        const flow = [4]f32{ width / height, config.scale, distortion, self.phase };
        const finish = [3]f32{ config.contours, config.dots, config.grain };

        rl.BeginShaderMode(self.program);
        rl.SetShaderValue(self.program, self.flow_location, &flow, rl.rl.RL_SHADER_UNIFORM_VEC4);
        rl.SetShaderValue(self.program, self.finish_location, &finish, rl.rl.RL_SHADER_UNIFORM_VEC3);
        // This pass replaces the viewport's clear color, including its alpha.
        // Begin/EndShaderMode flush the batch before each blend state change.
        rl.rl.rlDisableColorBlend();
        // Use the scene texture's quad for normalized UVs. The shader only uses its coordinates.
        rl.rl.DrawTexturePro(texture, .{ .width = viewport.target_width, .height = viewport.target_height }, .{
            .x = viewport.left,
            .y = viewport.top,
            .width = width,
            .height = height,
        }, .{}, 0, tint);
        rl.EndShaderMode();
        rl.rl.rlEnableColorBlend();
    }
};

test "both shader variants declare a GLSL version first" {
    inline for (.{ fragment_source, marbling_source, vertex_source }) |source| {
        try std.testing.expect(std.mem.startsWith(u8, source, "#version "));
        // Shared bodies must not carry their own version directive.
        try std.testing.expect(std.mem.indexOf(u8, source[1..], "#version") == null);
    }
}
