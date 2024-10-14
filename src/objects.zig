const std = @import("std");
const r = @cImport({
    @cInclude("raylib.h");
});
pub fn cassette_tape() void {
    const cubePosition = r.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 };
    r.DrawCylinder(cubePosition, 2.0, 2.0, 2.0, 10, r.RED);
    r.DrawCubeWires(cubePosition, 2.0, 2.0, 2.0, r.MAROON);
}
