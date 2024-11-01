const std = @import("std");

pub const Config = struct {
    pub const Window = struct {
        width: c_int = 1024,
        height: c_int = 768,
        title: []const u8 = "zigscene",
        fps_target: c_int = 60,
    };

    pub const Audio = struct {
        buffer_size: usize = 256,
        sample_rate: u32 = 44100,
        channels: u8 = 2,
        volume: f32 = 0.40,

        // Analysis settings
        attack: f32 = 0.8,
        release: f32 = 0.90,
    };

    pub const Visualizer = struct {
        pub const WaveForm = struct {
            amplitude: f32 = 60,
            color1: @Vector(3, f32) = .{ 0, 0, 0.96 },
            color2: @Vector(3, f32) = .{ 100, 1, 0.90 },
        };

        pub const Bubble = struct {
            ring_radius: f32 = 3.25,
            sphere_radius: f32 = 3,
            height_ring: f32 = 0.1,
            effect: f32 = 0.5,
            color_scale: f32 = 45,
        };
    };

    // Camera Configuration
    pub const Camera = struct {
        fov: f32 = 65.0,
        near: f32 = 0.1,
        far: f32 = 1000.0,
        initial_position: @Vector(3, f32) = .{ 0.0, 0.0, 10.0 },
        initial_target: @Vector(3, f32) = .{ 0.0, 0.0, 0.0 },
    };

    window: Window = .{},
    audio: Audio = .{},
    visualizer: Visualizer = .{},
    camera: Camera = .{},

    pub fn load() !Config {
        return .{};
    }
};

pub var current: Config = undefined;

pub fn init() !void {
    current = try Config.load();
}
