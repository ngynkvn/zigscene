const rl = @import("raylibz");
const std = @import("std");
const controls = @import("../core/controls.zig");
const graphics = @import("../graphics.zig");

const Vector3 = rl.Vector3;

pub const Window = struct {
    pub const width = 1024;
    pub const height = 768;
    pub const title = "zigscene";
    pub const fps_target: c_int = 60;
};

pub const Audio = struct {
    pub const buffer_size: usize = 1024;
    pub const sample_rate: u32 = 44100;
    pub const channels: u8 = 2;
    pub const volume: f32 = 0.40;

    pub var attack: f32 = 0.8;
    pub var release: f32 = 0.90;
    pub const Settings = std.StaticStringMap(controls.Setting).initComptime(.{
        .{ "Attack", controls.Setting{ .scalar = .{ .value = &attack, .range = .{ 0.0, 1 } } } },
        .{ "Release", controls.Setting{ .scalar = .{ .value = &release, .range = .{ 0.0, 1 } } } },
    });
};

pub const Shader = struct {
    pub var chroma_factor: f32 = 0.001;
    pub var noise_factor: f32 = 0.005;
    pub var alpha_factor: f32 = 1.0;

    pub const Settings = std.StaticStringMap(controls.Setting).initComptime(.{
        .{ "Chroma", controls.Setting{ .scalar = .{ .value = &chroma_factor, .range = .{ 0.0, 0.01 } } } },
        .{ "Noise", controls.Setting{ .scalar = .{ .value = &noise_factor, .range = .{ 0.0, 0.5 } } } },
        .{ "Alpha", controls.Setting{ .scalar = .{ .value = &alpha_factor, .range = .{ 0.0, 1.0 } } } },
    });
};

pub const Visualizer = struct {
    pub const WaveFormLine = graphics.WaveFormLine;
    pub const Bubble = graphics.Bubble;
    pub const WaveFormBar = graphics.WaveFormBar;
};

// Camera Configuration
pub const Camera = struct {
    pub const fov: f32 = 45.0;
    pub const initial_position: rl.Vector3 = .{ .x = 0.0, .y = 0.0, .z = 13.0 };
    pub const initial_target: rl.Vector3 = .{ .x = 0.0, .y = 0.0, .z = 0.0 };
};
