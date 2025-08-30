const rl = @import("raylibz");
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

    pub const Scalars = [_]controls.Scalar{
        .{ "Attack", &attack, .{ 0.0, 1 } },
        .{ "Release", &release, .{ 0.0, 1 } },
    };
    pub var attack: f32 = 0.8;
    pub var release: f32 = 0.90;
};

pub const Shader = struct {
    pub var chroma_factor: f32 = 0.001;
    pub var noise_factor: f32 = 0.005;
    pub var alpha_factor: f32 = 1.0;
    pub const Scalars = [_]controls.Scalar{
        .{ "Chroma", &chroma_factor, .{ 0.0, 0.01 } },
        .{ "Noise", &noise_factor, .{ 0.0, 0.5 } },
        .{ "Alpha", &alpha_factor, .{ 0.0, 1.0 } },
    };
};

pub const Visualizer = struct {
    pub const WaveFormLine = graphics.WaveFormLine;
    pub const Bubble = graphics.Bubble;

    pub const WaveFormBar = struct {
        pub var Scalars = [_]controls.Scalar{
            .{ "amplitude", &amplitude, .{ 0, 100 } },
            .{ "base height", &base_h, .{ 0, 100 } },
        };
        pub var Colors = [_]controls.Color{
            .{ "color1", &color1.x },
            .{ "color2", &color2.x },
            .{ "color3", &trail_color.x },
        };
        pub var amplitude: f32 = 50;
        pub var base_h: f32 = 20;
        pub var color1 = Vector3{ .x = 250, .y = 1, .z = 0.94 };
        pub var color2 = Vector3{ .x = 270, .y = 1, .z = 0.9 };
        pub var trail_color = Vector3{ .x = 210, .y = 1, .z = 0.473 };
    };
};

// Camera Configuration
pub const Camera = struct {
    pub const fov: f32 = 45.0;
    pub const initial_position: rl.Vector3 = .{ .x = 0.0, .y = 0.0, .z = 13.0 };
    pub const initial_target: rl.Vector3 = .{ .x = 0.0, .y = 0.0, .z = 0.0 };
};
