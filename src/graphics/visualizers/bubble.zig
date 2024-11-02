const std = @import("std");
const audio = @import("../../audio.zig");
const rl = @import("../../raylib.zig");
const controls = @import("../../gui/controls.zig");
const cnv = @import("../../ext/convert.zig");

const hsv = @import("../../ext/color.zig").Color.hsv.vec3;
const Vector3 = @import("../../ext/vector.zig").Vector3;
const ffi = cnv.ffi;
const iff = cnv.iff;

const Config = @import("zigscene").Config.Visualizer.Bubble;
pub const Bubble = struct {
    const color1 = &Config.color1;
    const color2 = &Config.color2;
    // Radii
    pub const r_ring: *f32 = &Config.ring_radius;
    pub const r_sphere: *f32 = &Config.sphere_radius;
    pub const height_ring: *f32 = &Config.height_ring;
    pub const effect: *f32 = &Config.effect;
    pub const color_scale: *f32 = &Config.color_scale;
    pub const bubble_color_scale: *f32 = &Config.bubble_color_scale;
    pub fn render(camera3d: rl.Camera3D, rot_offset: f32, t: f32) void {
        rl.BeginMode3D(camera3d);
        defer rl.EndMode3D();
        rl.rlRotatef(rot_offset, 0, 1, 0);
        {
            rl.rlPushMatrix();
            rl.rlRotatef(t * 32, 1, 1, 1);
            var col = color1.*;
            col.x += audio.rms_energy * bubble_color_scale.*;
            rl.DrawSphereWires(.{}, r_sphere.* + audio.rms_energy * effect.*, 10, 10, hsv(col).into());
            rl.rlPopMatrix();
        }
        rl.rlPushMatrix();
        rl.rlRotatef(t * 32, 0.1, 0.1, 1);
        const tsteps = 2 * std.math.pi / @as(f32, @floatFromInt(audio.curr_buffer.len));
        for (audio.curr_buffer, 0..) |v, i| {
            const r = r_ring.* +
                (effect.* * audio.rms_energy) +
                (@abs(v) * effect.*);

            const angle_rad = ffi(f32, i) * tsteps;
            const x = @cos(angle_rad) * r;
            const y = @sin(angle_rad) * r;

            rl.rlPushMatrix();
            rl.rlTranslatef(x, y, 0);
            rl.rlRotatef(90 + (angle_rad * 180 / std.math.pi), 0, 0, 1);

            var col = color2.*;
            col.x += audio.rms_energy * color_scale.* + @abs(v) * 30;
            rl.DrawCubeWires(.{}, 0.1, height_ring.* + @abs(v) * effect.* + audio.rms_energy * 0.2, 0.1, hsv(col).into());
            rl.rlPopMatrix();
        }
        rl.rlPopMatrix();
    }
};
