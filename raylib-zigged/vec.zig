pub const struct_Vector2 = extern struct {
    x: f32 = @import("std").mem.zeroes(f32),
    y: f32 = @import("std").mem.zeroes(f32),
};
pub const Vector2 = struct_Vector2;
pub const struct_Vector3 = extern struct {
    x: f32 = @import("std").mem.zeroes(f32),
    y: f32 = @import("std").mem.zeroes(f32),
    z: f32 = @import("std").mem.zeroes(f32),
};
pub const Vector3 = struct_Vector3;
pub const struct_Vector4 = extern struct {
    x: f32 = @import("std").mem.zeroes(f32),
    y: f32 = @import("std").mem.zeroes(f32),
    z: f32 = @import("std").mem.zeroes(f32),
    w: f32 = @import("std").mem.zeroes(f32),
};
pub const Vector4 = struct_Vector4;
pub const Quaternion = Vector4;
pub const struct_Matrix = extern struct {
    m0: f32 = @import("std").mem.zeroes(f32),
    m4: f32 = @import("std").mem.zeroes(f32),
    m8: f32 = @import("std").mem.zeroes(f32),
    m12: f32 = @import("std").mem.zeroes(f32),
    m1: f32 = @import("std").mem.zeroes(f32),
    m5: f32 = @import("std").mem.zeroes(f32),
    m9: f32 = @import("std").mem.zeroes(f32),
    m13: f32 = @import("std").mem.zeroes(f32),
    m2: f32 = @import("std").mem.zeroes(f32),
    m6: f32 = @import("std").mem.zeroes(f32),
    m10: f32 = @import("std").mem.zeroes(f32),
    m14: f32 = @import("std").mem.zeroes(f32),
    m3: f32 = @import("std").mem.zeroes(f32),
    m7: f32 = @import("std").mem.zeroes(f32),
    m11: f32 = @import("std").mem.zeroes(f32),
    m15: f32 = @import("std").mem.zeroes(f32),
};
pub const Matrix = struct_Matrix;

pub const struct_Color = extern struct {
    r: u8 = @import("std").mem.zeroes(u8),
    g: u8 = @import("std").mem.zeroes(u8),
    b: u8 = @import("std").mem.zeroes(u8),
    a: u8 = @import("std").mem.zeroes(u8),
};
pub const Color = struct_Color;
pub const struct_Rectangle = extern struct {
    x: f32 = @import("std").mem.zeroes(f32),
    y: f32 = @import("std").mem.zeroes(f32),
    width: f32 = @import("std").mem.zeroes(f32),
    height: f32 = @import("std").mem.zeroes(f32),
};
pub const Rectangle = struct_Rectangle;
