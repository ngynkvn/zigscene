const std = @import("std");
const rl = @import("../raylib.zig");
const Vector3 = @import("../ext/vector.zig").Vector3;

pub const Window = struct {
    pub const width = 1024;
    pub const height = 768;
    pub const title = "zigscene";
    pub const fps_target: c_int = 60;
};

pub const Audio = struct {
    pub const buffer_size: usize = 256;
    pub const sample_rate: u32 = 44100;
    pub const channels: u8 = 2;
    pub const volume: f32 = 0.40;

    // Analysis settings
    pub const attack: f32 = 0.8;
    pub const release: f32 = 0.90;
};

pub const Visualizer = struct {
    pub const WaveFormLine = struct {
        pub var amplitude: f32 = 60;
        pub var color1: Vector3 = .{ .x = 0, .y = 0, .z = 0.96 };
        pub var color2: Vector3 = .{ .x = 100, .y = 1, .z = 0.90 };
    };
    pub const WaveFormBar = struct {
        pub var amplitude: f32 = 50;
        pub var base_h: f32 = 20;
        pub var color1 = Vector3{ .x = 250, .y = 1, .z = 0.94 };
        pub var color2 = Vector3{ .x = 270, .y = 1, .z = 0.9 };
    };

    pub const Bubble = struct {
        pub var color1 = Vector3{ .x = 195, .y = 0.5, .z = 1 };
        pub var color2 = Vector3{ .x = 117, .y = 1, .z = 1 };
        pub var ring_radius: f32 = 3.25;
        pub var sphere_radius: f32 = 3;
        pub var height_ring: f32 = 0.1;
        pub var effect: f32 = 0.5;
        pub var color_scale: f32 = 45;
        pub var bubble_color_scale: f32 = 45;
    };
};

// Camera Configuration
pub const Camera = struct {
    pub const fov: f32 = 65.0;
    pub const initial_position: rl.Vector3 = .{ .x = 0.0, .y = 0.0, .z = 10.0 };
    pub const initial_target: rl.Vector3 = .{ .x = 0.0, .y = 0.0, .z = 0.0 };
};
