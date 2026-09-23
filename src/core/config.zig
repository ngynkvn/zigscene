const Vector3 = @import("../ext/vector.zig").Vector3;
const controls = @import("../gui/controls.zig");
const rl = @import("../raylib.zig");

pub const Window = struct {
    pub const width = 1024;
    pub const height = 768;
    pub const title = "zigscene";
    pub const fps_target: c_int = 60;
    pub var opacity: f32 = 1.0;
    pub const Scalars = [_]controls.Scalar{
        .{ "Window opacity", &opacity, .{ 0.15, 1.0 } },
    };
};

pub const Audio = struct {
    pub const buffer_size: usize = 1024;
    pub const sample_rate: u32 = 44100;
    pub const channels: u8 = 2;
    pub var volume: f32 = 0.40;

    pub const Scalars = [_]controls.Scalar{
        .{ "Master volume", &volume, .{ 0.0, 1.0 } },
        .{ "Wave blend", &wave_blend, .{ 0.0, 0.98 } },
        .{ "Wave gain", &wave_gain, .{ 0.1, 3.0 } },
    };
    pub var wave_blend: f32 = 0.55;
    pub var wave_gain: f32 = 1.0;
};

pub const Motion = struct {
    pub var energy_gain: f32 = 3.0;
    pub var compression: f32 = 1.2;
    pub var attack_seconds: f32 = 0.08;
    pub var release_seconds: f32 = 0.35;
    pub var beat_decay_seconds: f32 = 0.28;
    pub const Scalars = [_]controls.Scalar{
        .{ "Energy gain", &energy_gain, .{ 0.2, 6.0 } },
        .{ "Compression", &compression, .{ 0.0, 8.0 } },
        .{ "Rise time", &attack_seconds, .{ 0.01, 0.5 } },
        .{ "Fall time", &release_seconds, .{ 0.03, 1.5 } },
        .{ "Beat decay", &beat_decay_seconds, .{ 0.05, 1.0 } },
    };
};

pub const Scene = struct {
    pub var wave_lines = true;
    pub var wave_bars = true;
    pub var spectrum = true;
    pub var bubble = true;
    pub var halo = true;
};

pub const Shader = struct {
    pub var chroma_factor: f32 = 0.001;
    pub var noise_factor: f32 = 0.005;
    pub var alpha_factor: f32 = 0.0;
    pub const Scalars = [_]controls.Scalar{
        .{ "Chroma", &chroma_factor, .{ 0.0, 0.01 } },
        .{ "Noise", &noise_factor, .{ 0.0, 0.5 } },
        .{ "Background alpha", &alpha_factor, .{ 0.0, 1.0 } },
    };
};

pub const Visualizer = struct {
    pub const WaveFormLine = struct {
        pub const Scalars = [_]controls.Scalar{
            .{ "amplitude", &amplitude, .{ 0, 100 } },
        };
        pub const Colors = [_]controls.Color{
            .{ "color1", &color1.x },
            .{ "color2", &color2.x },
        };
        pub var amplitude: f32 = 60;
        pub var color1: Vector3 = .{ .x = 0, .y = 0, .z = 0.96 };
        pub var color2: Vector3 = .{ .x = 100, .y = 1, .z = 0.90 };
    };

    pub const WaveFormBar = struct {
        pub var Scalars = [_]controls.Scalar{
            .{ "amplitude", &amplitude, .{ 0, 100 } },
            .{ "base height", &base_h, .{ 0, 100 } },
            .{ "trail decay", &trail_decay, .{ 0.05, 2.0 } },
        };
        pub var Colors = [_]controls.Color{
            .{ "color1", &color1.x },
            .{ "color2", &color2.x },
            .{ "color3", &trail_color.x },
        };
        pub var amplitude: f32 = 50;
        pub var base_h: f32 = 20;
        pub var trail_decay: f32 = 0.6;
        pub var color1 = Vector3{ .x = 250, .y = 1, .z = 0.94 };
        pub var color2 = Vector3{ .x = 270, .y = 1, .z = 0.9 };
        pub var trail_color = Vector3{ .x = 210, .y = 1, .z = 0.473 };
    };

    pub const Spectrum = struct {
        pub var gain: f32 = 3.0;
        pub var height: f32 = 160;
        pub const Scalars = [_]controls.Scalar{
            .{ "Spectrum gain", &gain, .{ 0.2, 10.0 } },
            .{ "Spectrum height", &height, .{ 20, 300 } },
        };
    };

    pub const Halo = struct {
        pub var radius: f32 = 135;
        pub var depth: f32 = 100;
        pub var spin: f32 = 0.12;
        pub var hue: f32 = 195;
        pub const Scalars = [_]controls.Scalar{
            .{ "Halo radius", &radius, .{ 40, 260 } },
            .{ "Halo depth", &depth, .{ 0, 220 } },
            .{ "Halo spin", &spin, .{ -1, 1 } },
        };
        pub const Colors = [_]controls.Color{
            .{ "Halo hue", &hue },
        };
    };

    pub const Bubble = struct {
        pub var Scalars = [_]controls.Scalar{
            // zig fmt: off
            .{ "ring radius",     &ring_radius,             .{ 0.1, 8 } },
            .{ "sphere radius",   &sphere_radius,           .{ 0.1, 4 } },
            .{ "volume effect",   &effect,             .{ 0.1, 1 } },
            .{ "color scale",     &color_scale,        .{ 0.0, 100 } },
            .{ "bubble color fx", &bubble_color_scale, .{ 0.0, 100 } },
            .{ "ring height",     &height_ring,        .{ 0.0, 1 } },
            // zig fmt: on
        };
        pub var Colors = [_]controls.Color{
            .{ "color1", &color1.x },
            .{ "color2", &color2.x },
        };
        pub var ring_radius: f32 = 3.25;
        pub var sphere_radius: f32 = 3;
        pub var height_ring: f32 = 0.1;
        pub var effect: f32 = 0.5;
        pub var color_scale: f32 = 45;
        pub var bubble_color_scale: f32 = 40;

        pub var color1 = Vector3{ .x = 195, .y = 0.5, .z = 1 };
        pub var color2 = Vector3{ .x = 117, .y = 1, .z = 1 };
    };
};

// Camera Configuration
pub const Camera = struct {
    pub const fov: f32 = 45.0;
    pub const initial_position: rl.Vector3 = .{ .x = 0.0, .y = 0.0, .z = 13.0 };
    pub const initial_target: rl.Vector3 = .{ .x = 0.0, .y = 0.0, .z = 0.0 };
};
