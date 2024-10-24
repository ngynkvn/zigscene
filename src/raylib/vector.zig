const std = @import("std");
const math = std.math;

// TODO: replace aliases
const atan2f = math.atan2;
const sqrtf = math.sqrt;
pub extern fn fmaxf(f32, f32) f32;
pub extern fn fminf(f32, f32) f32;
pub const fabsf = @import("std").zig.c_builtins.__builtin_fabsf;
pub const sinf = math.sin;
pub const cosf = math.cos;

pub const Vector2 = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    pub fn fromC(c: anytype) Vector2 {
        return .{ .x = c.x, .y = c.y };
    }
    pub fn zero() Vector2 {
        return .{ .x = 0.0, .y = 0.0 };
    }
    pub fn add(v1: Vector2, v2: Vector2) Vector2 {
        return .{ .x = v1.x + v2.x, .y = v1.y + v2.y };
    }
    pub fn subtract(v1: Vector2, v2: Vector2) Vector2 {
        return .{ .x = v1.x - v2.x, .y = v1.y - v2.y };
    }
    pub fn length(v: Vector2) f32 {
        return sqrtf((v.x * v.x) + (v.y * v.y));
    }
    pub fn dotProduct(v1: Vector2, v2: Vector2) f32 {
        return (v1.x * v2.x) + (v1.y * v2.y);
    }
    pub fn distanceSqr(v1: Vector2, v2: Vector2) f32 {
        return ((v1.x - v2.x) * (v1.x - v2.x)) + ((v1.y - v2.y) * (v1.y - v2.y));
    }
    pub fn lineAngle(start: Vector2, end: Vector2) f32 {
        return -atan2f(end.y - start.y, end.x - start.x);
    }
    pub fn multiply(v1: Vector2, v2: Vector2) Vector2 {
        return .{ .x = v1.x * v2.x, .y = v1.y * v2.y };
    }
    pub fn divide(v1: Vector2, v2: Vector2) Vector2 {
        return .{ .x = v1.x / v2.x, .y = v1.y / v2.y };
    }
    pub fn transform(v: Vector2, mat: Matrix) Vector2 {
        const x: f32 = v.x;
        const y: f32 = v.y;
        const z: f32 = 0;
        return .{
            .x = (((mat.m0 * x) + (mat.m4 * y)) + (mat.m8 * z)) + mat.m12,
            .y = (((mat.m1 * x) + (mat.m5 * y)) + (mat.m9 * z)) + mat.m13,
        };
    }
    pub fn reflect(v: Vector2, normal: Vector2) Vector2 {
        const dot_product: f32 = (v.x * normal.x) + (v.y * normal.y);
        return .{
            .x = v.x - ((2.0 * normal.x) * dot_product),
            .y = v.y - ((2.0 * normal.y) * dot_product),
        };
    }
    pub fn max(v1: Vector2, v2: Vector2) Vector2 {
        return .{
            .x = fmaxf(v1.x, v2.x),
            .y = fmaxf(v1.y, v2.y),
        };
    }
    pub fn moveTowards(v: Vector2, target: Vector2, maxDistance: f32) Vector2 {
        var result: Vector2 = Vector2{ .x = 0, .y = 0 };
        const dx: f32 = target.x - v.x;
        const dy: f32 = target.y - v.y;
        const value: f32 = (dx * dx) + (dy * dy);
        if ((value == 0) or
            ((maxDistance >= 0) and (value <= (maxDistance * maxDistance))))
            return target;
        const dist: f32 = sqrtf(value);
        result.x = v.x + ((dx / dist) * maxDistance);
        result.y = v.y + ((dy / dist) * maxDistance);
        return result;
    }
    pub fn clamp(v: Vector2, min_v: Vector2, max_v: Vector2) Vector2 {
        return .{
            .x = fminf(max_v.x, fmaxf(min_v.x, v.x)),
            .y = fminf(max_v.y, fmaxf(min_v.y, v.y)),
        };
    }
    pub fn equals(p: Vector2, q: Vector2) c_int {
        const result: c_int = @intFromBool((fabsf(p.x - q.x) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.x), fabsf(q.x))))) and (fabsf(p.y - q.y) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.y), fabsf(q.y))))));
        return result;
    }
    pub fn one() Vector2 {
        return .{ .x = 1.0, .y = 1.0 };
    }
    pub fn addValue(v: Vector2, add_v: f32) Vector2 {
        return .{ .x = v.x + add_v, .y = v.y + add_v };
    }
    pub fn subtractValue(v: Vector2, sub: f32) Vector2 {
        return .{ .x = v.x - sub, .y = v.y - sub };
    }
    pub fn lengthSqr(v: Vector2) f32 {
        return (v.x * v.x) + (v.y * v.y);
    }
    pub fn distance(v1: Vector2, v2: Vector2) f32 {
        return sqrtf(((v1.x - v2.x) * (v1.x - v2.x)) + ((v1.y - v2.y) * (v1.y - v2.y)));
    }
    pub fn angle(v1: Vector2, v2: Vector2) f32 {
        const dot: f32 = (v1.x * v2.x) + (v1.y * v2.y);
        const det: f32 = (v1.x * v2.y) - (v1.y * v2.x);
        return atan2f(det, dot);
    }
    pub fn scale(v: Vector2, scale_v: f32) Vector2 {
        return .{ .x = v.x * scale_v, .y = v.y * scale_v };
    }
    pub fn negate(v: Vector2) Vector2 {
        return .{ .x = -v.x, .y = -v.y };
    }
    pub fn normalize(v: Vector2) Vector2 {
        var result: Vector2 = Vector2{
            .x = 0,
            .y = 0,
        };
        const length_v: f32 = sqrtf((v.x * v.x) + (v.y * v.y));
        if (length_v > 0) {
            const ilength: f32 = 1.0 / length_v;
            result.x = v.x * ilength;
            result.y = v.y * ilength;
        }
        return result;
    }
    pub fn lerp(v1: Vector2, v2: Vector2, amount: f32) Vector2 {
        return .{
            .x = v1.x + (amount * (v2.x - v1.x)),
            .y = v1.y + (amount * (v2.y - v1.y)),
        };
    }
    pub fn min(v1: Vector2, v2: Vector2) Vector2 {
        return .{
            .x = fminf(v1.x, v2.x),
            .y = fminf(v1.y, v2.y),
        };
    }
    pub fn rotate(v: Vector2, angle_v: f32) Vector2 {
        const cosres: f32 = cosf(angle_v);
        const sinres: f32 = sinf(angle_v);
        return .{
            .x = (v.x * cosres) - (v.y * sinres),
            .y = (v.x * sinres) + (v.y * cosres),
        };
    }
    pub fn invert(v: Vector2) Vector2 {
        return .{ .x = 1.0 / v.x, .y = 1.0 / v.y };
    }
    pub fn clampValue(v: Vector2, min_v: f32, max_v: f32) Vector2 {
        var result: Vector2 = v;
        var length_v: f32 = (v.x * v.x) + (v.y * v.y);
        if (length_v > 0.0) {
            length_v = sqrtf(length_v);
            var scale_v: f32 = 1;
            if (length_v < min_v) {
                scale_v = min_v / length_v;
            } else if (length_v > max_v) {
                scale_v = max_v / length_v;
            }
            result.x = v.x * scale_v;
            result.y = v.y * scale_v;
        }
        return result;
    }
    pub fn refract(v: Vector2, n: Vector2, r: f32) Vector2 {
        var result: Vector2 = Vector2{ .x = 0, .y = 0 };
        const dot: f32 = (v.x * n.x) + (v.y * n.y);
        var d: f32 = 1.0 - ((r * r) * (1.0 - (dot * dot)));
        if (d >= 0.0) {
            d = sqrtf(d);
            v.x = (r * v.x) - (((r * dot) + d) * n.x);
            v.y = (r * v.y) - (((r * dot) + d) * n.y);
            result = v;
        }
        return result;
    }
};

// TODO: missing a Quaternion fn here (QuaternionFromVector3ToVector3)
pub const Vector3 = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,

    pub fn zero() Vector3 {
        return .{ .x = 0.0, .y = 0.0, .z = 0.0 };
    }
    pub fn add(v1: Vector3, v2: Vector3) Vector3 {
        return .{ .x = v1.x + v2.x, .y = v1.y + v2.y, .z = v1.z + v2.z };
    }
    pub fn subtract(v1: Vector3, v2: Vector3) Vector3 {
        return .{ .x = v1.x - v2.x, .y = v1.y - v2.y, .z = v1.z - v2.z };
    }
    pub fn scale(v: Vector3, scalar: f32) Vector3 {
        return .{ .x = v.x * scalar, .y = v.y * scalar, .z = v.z * scalar };
    }
    pub fn crossProduct(v1: Vector3, v2: Vector3) Vector3 {
        return .{ .x = (v1.y * v2.z) - (v1.z * v2.y), .y = (v1.z * v2.x) - (v1.x * v2.z), .z = (v1.x * v2.y) - (v1.y * v2.x) };
    }
    pub fn length(v: Vector3) f32 {
        const result: f32 = sqrtf(((v.x * v.x) + (v.y * v.y)) + (v.z * v.z));
        return result;
    }
    pub fn dotProduct(v1: Vector3, v2: Vector3) f32 {
        const result: f32 = ((v1.x * v2.x) + (v1.y * v2.y)) + (v1.z * v2.z);
        return result;
    }
    pub fn distanceSqr(v1: Vector3, v2: Vector3) f32 {
        var result: f32 = 0.0;
        const dx: f32 = v2.x - v1.x;
        const dy: f32 = v2.y - v1.y;
        const dz: f32 = v2.z - v1.z;
        result = ((dx * dx) + (dy * dy)) + (dz * dz);
        return result;
    }
    pub fn negate(v: Vector3) Vector3 {
        return .{ .x = -v.x, .y = -v.y, .z = -v.z };
    }
    pub fn normalize(v: Vector3) Vector3 {
        var result: Vector3 = v;
        const length_v: f32 = sqrtf(((v.x * v.x) + (v.y * v.y)) + (v.z * v.z));
        if (length_v != 0.0) {
            const ilength: f32 = 1.0 / length_v;
            result.x *= ilength;
            result.y *= ilength;
            result.z *= ilength;
        }
        return result;
    }
    pub fn reject(v1: Vector3, v2: Vector3) Vector3 {
        var result: Vector3 = Vector3{ .x = 0, .y = 0, .z = 0 };
        const v1dv2: f32 = ((v1.x * v2.x) + (v1.y * v2.y)) + (v1.z * v2.z);
        const v2dv2: f32 = ((v2.x * v2.x) + (v2.y * v2.y)) + (v2.z * v2.z);
        const mag: f32 = v1dv2 / v2dv2;
        result.x = v1.x - (v2.x * mag);
        result.y = v1.y - (v2.y * mag);
        result.z = v1.z - (v2.z * mag);
        return result;
    }
    pub fn transform(v: Vector3, mat: Matrix) Vector3 {
        var result: Vector3 = Vector3{ .x = 0, .y = 0, .z = 0 };
        const x: f32 = v.x;
        const y: f32 = v.y;
        const z: f32 = v.z;
        result.x = (((mat.m0 * x) + (mat.m4 * y)) + (mat.m8 * z)) + mat.m12;
        result.y = (((mat.m1 * x) + (mat.m5 * y)) + (mat.m9 * z)) + mat.m13;
        result.z = (((mat.m2 * x) + (mat.m6 * y)) + (mat.m10 * z)) + mat.m14;
        return result;
    }
    pub fn rotateByAxisAngle(v: Vector3, axis: Vector3, angle_v: f32) Vector3 {
        var result: Vector3 = v;
        var length_v: f32 = sqrtf(((axis.x * axis.x) + (axis.y * axis.y)) + (axis.z * axis.z));
        if (length_v == 0.0) {
            length_v = 1.0;
        }
        const ilength: f32 = 1.0 / length_v;
        axis.x *= ilength;
        axis.y *= ilength;
        axis.z *= ilength;
        angle_v /= 2.0;
        var a: f32 = sinf(angle_v);
        const b: f32 = axis.x * a;
        const c: f32 = axis.y * a;
        const d: f32 = axis.z * a;
        a = cosf(angle_v);
        const w: Vector3 = Vector3{
            .x = b,
            .y = c,
            .z = d,
        };
        var wv: Vector3 = Vector3{
            .x = (w.y * v.z) - (w.z * v.y),
            .y = (w.z * v.x) - (w.x * v.z),
            .z = (w.x * v.y) - (w.y * v.x),
        };
        var wwv: Vector3 = Vector3{
            .x = (w.y * wv.z) - (w.z * wv.y),
            .y = (w.z * wv.x) - (w.x * wv.z),
            .z = (w.x * wv.y) - (w.y * wv.x),
        };
        a *= 2;
        wv.x *= a;
        wv.y *= a;
        wv.z *= a;
        wwv.x *= 2;
        wwv.y *= 2;
        wwv.z *= 2;
        result.x += wv.x;
        result.y += wv.y;
        result.z += wv.z;
        result.x += wwv.x;
        result.y += wwv.y;
        result.z += wwv.z;
        return result;
    }
    pub fn lerp(v1: Vector3, v2: Vector3, amount: f32) Vector3 {
        var result: Vector3 = Vector3{ .x = 0, .y = 0, .z = 0 };
        result.x = v1.x + (amount * (v2.x - v1.x));
        result.y = v1.y + (amount * (v2.y - v1.y));
        result.z = v1.z + (amount * (v2.z - v1.z));
        return result;
    }
    pub fn reflect(v: Vector3, normal: Vector3) Vector3 {
        var result: Vector3 = Vector3{ .x = 0, .y = 0, .z = 0 };
        const dot_product: f32 = ((v.x * normal.x) + (v.y * normal.y)) + (v.z * normal.z);
        result.x = v.x - ((2.0 * normal.x) * dot_product);
        result.y = v.y - ((2.0 * normal.y) * dot_product);
        result.z = v.z - ((2.0 * normal.z) * dot_product);
        return result;
    }
    pub fn max(v1: Vector3, v2: Vector3) Vector3 {
        var result: Vector3 = Vector3{ .x = 0, .y = 0, .z = 0 };
        result.x = fmaxf(v1.x, v2.x);
        result.y = fmaxf(v1.y, v2.y);
        result.z = fmaxf(v1.z, v2.z);
        return result;
    }
    pub fn unproject(source: Vector3, projection: Matrix, view: Matrix) Vector3 {
        var result: Vector3 = Vector3{ .x = 0, .y = 0, .z = 0 };
        const matViewProj: Matrix = Matrix{
            .m0 = (((view.m0 * projection.m0) + (view.m1 * projection.m4)) + (view.m2 * projection.m8)) + (view.m3 * projection.m12),
            .m4 = (((view.m0 * projection.m1) + (view.m1 * projection.m5)) + (view.m2 * projection.m9)) + (view.m3 * projection.m13),
            .m8 = (((view.m0 * projection.m2) + (view.m1 * projection.m6)) + (view.m2 * projection.m10)) + (view.m3 * projection.m14),
            .m12 = (((view.m0 * projection.m3) + (view.m1 * projection.m7)) + (view.m2 * projection.m11)) + (view.m3 * projection.m15),
            .m1 = (((view.m4 * projection.m0) + (view.m5 * projection.m4)) + (view.m6 * projection.m8)) + (view.m7 * projection.m12),
            .m5 = (((view.m4 * projection.m1) + (view.m5 * projection.m5)) + (view.m6 * projection.m9)) + (view.m7 * projection.m13),
            .m9 = (((view.m4 * projection.m2) + (view.m5 * projection.m6)) + (view.m6 * projection.m10)) + (view.m7 * projection.m14),
            .m13 = (((view.m4 * projection.m3) + (view.m5 * projection.m7)) + (view.m6 * projection.m11)) + (view.m7 * projection.m15),
            .m2 = (((view.m8 * projection.m0) + (view.m9 * projection.m4)) + (view.m10 * projection.m8)) + (view.m11 * projection.m12),
            .m6 = (((view.m8 * projection.m1) + (view.m9 * projection.m5)) + (view.m10 * projection.m9)) + (view.m11 * projection.m13),
            .m10 = (((view.m8 * projection.m2) + (view.m9 * projection.m6)) + (view.m10 * projection.m10)) + (view.m11 * projection.m14),
            .m14 = (((view.m8 * projection.m3) + (view.m9 * projection.m7)) + (view.m10 * projection.m11)) + (view.m11 * projection.m15),
            .m3 = (((view.m12 * projection.m0) + (view.m13 * projection.m4)) + (view.m14 * projection.m8)) + (view.m15 * projection.m12),
            .m7 = (((view.m12 * projection.m1) + (view.m13 * projection.m5)) + (view.m14 * projection.m9)) + (view.m15 * projection.m13),
            .m11 = (((view.m12 * projection.m2) + (view.m13 * projection.m6)) + (view.m14 * projection.m10)) + (view.m15 * projection.m14),
            .m15 = (((view.m12 * projection.m3) + (view.m13 * projection.m7)) + (view.m14 * projection.m11)) + (view.m15 * projection.m15),
        };
        const a00: f32 = matViewProj.m0;
        const a01: f32 = matViewProj.m1;
        const a02: f32 = matViewProj.m2;
        const a03: f32 = matViewProj.m3;
        const a10: f32 = matViewProj.m4;
        const a11: f32 = matViewProj.m5;
        const a12: f32 = matViewProj.m6;
        const a13: f32 = matViewProj.m7;
        const a20: f32 = matViewProj.m8;
        const a21: f32 = matViewProj.m9;
        const a22: f32 = matViewProj.m10;
        const a23: f32 = matViewProj.m11;
        const a30: f32 = matViewProj.m12;
        const a31: f32 = matViewProj.m13;
        const a32: f32 = matViewProj.m14;
        const a33: f32 = matViewProj.m15;
        const b00: f32 = (a00 * a11) - (a01 * a10);
        const b01: f32 = (a00 * a12) - (a02 * a10);
        const b02: f32 = (a00 * a13) - (a03 * a10);
        const b03: f32 = (a01 * a12) - (a02 * a11);
        const b04: f32 = (a01 * a13) - (a03 * a11);
        const b05: f32 = (a02 * a13) - (a03 * a12);
        const b06: f32 = (a20 * a31) - (a21 * a30);
        const b07: f32 = (a20 * a32) - (a22 * a30);
        const b08: f32 = (a20 * a33) - (a23 * a30);
        const b09: f32 = (a21 * a32) - (a22 * a31);
        const b10: f32 = (a21 * a33) - (a23 * a31);
        const b11: f32 = (a22 * a33) - (a23 * a32);
        const invDet: f32 = 1.0 / ((((((b00 * b11) - (b01 * b10)) + (b02 * b09)) + (b03 * b08)) - (b04 * b07)) + (b05 * b06));
        const matViewProjInv: Matrix = Matrix{
            .m0 = (((a11 * b11) - (a12 * b10)) + (a13 * b09)) * invDet,
            .m4 = (((-a01 * b11) + (a02 * b10)) - (a03 * b09)) * invDet,
            .m8 = (((a31 * b05) - (a32 * b04)) + (a33 * b03)) * invDet,
            .m12 = (((-a21 * b05) + (a22 * b04)) - (a23 * b03)) * invDet,
            .m1 = (((-a10 * b11) + (a12 * b08)) - (a13 * b07)) * invDet,
            .m5 = (((a00 * b11) - (a02 * b08)) + (a03 * b07)) * invDet,
            .m9 = (((-a30 * b05) + (a32 * b02)) - (a33 * b01)) * invDet,
            .m13 = (((a20 * b05) - (a22 * b02)) + (a23 * b01)) * invDet,
            .m2 = (((a10 * b10) - (a11 * b08)) + (a13 * b06)) * invDet,
            .m6 = (((-a00 * b10) + (a01 * b08)) - (a03 * b06)) * invDet,
            .m10 = (((a30 * b04) - (a31 * b02)) + (a33 * b00)) * invDet,
            .m14 = (((-a20 * b04) + (a21 * b02)) - (a23 * b00)) * invDet,
            .m3 = (((-a10 * b09) + (a11 * b07)) - (a12 * b06)) * invDet,
            .m7 = (((a00 * b09) - (a01 * b07)) + (a02 * b06)) * invDet,
            .m11 = (((-a30 * b03) + (a31 * b01)) - (a32 * b00)) * invDet,
            .m15 = (((a20 * b03) - (a21 * b01)) + (a22 * b00)) * invDet,
        };
        const quat: Quaternion = Quaternion{
            .x = source.x,
            .y = source.y,
            .z = source.z,
            .w = 1.0,
        };
        const qtransformed: Quaternion = Quaternion{
            .x = (((matViewProjInv.m0 * quat.x) + (matViewProjInv.m4 * quat.y)) + (matViewProjInv.m8 * quat.z)) + (matViewProjInv.m12 * quat.w),
            .y = (((matViewProjInv.m1 * quat.x) + (matViewProjInv.m5 * quat.y)) + (matViewProjInv.m9 * quat.z)) + (matViewProjInv.m13 * quat.w),
            .z = (((matViewProjInv.m2 * quat.x) + (matViewProjInv.m6 * quat.y)) + (matViewProjInv.m10 * quat.z)) + (matViewProjInv.m14 * quat.w),
            .w = (((matViewProjInv.m3 * quat.x) + (matViewProjInv.m7 * quat.y)) + (matViewProjInv.m11 * quat.z)) + (matViewProjInv.m15 * quat.w),
        };
        result.x = qtransformed.x / qtransformed.w;
        result.y = qtransformed.y / qtransformed.w;
        result.z = qtransformed.z / qtransformed.w;
        return result;
    }
    pub fn invert(v: Vector3) Vector3 {
        return .{ .x = 1.0 / v.x, .y = 1.0 / v.y, .z = 1.0 / v.z };
    }
    pub fn clampValue(v: Vector3, min_v: f32, max_v: f32) Vector3 {
        var result: Vector3 = v;
        var length_v: f32 = ((v.x * v.x) + (v.y * v.y)) + (v.z * v.z);
        if (length_v > 0.0) {
            length_v = sqrtf(length_v);
            var scale_v: f32 = 1;
            if (length_v < min_v) {
                scale_v = min_v / length_v;
            } else if (length_v > max_v) {
                scale_v = max_v / length_v;
            }
            result.x = v.x * scale_v;
            result.y = v.y * scale_v;
            result.z = v.z * scale_v;
        }
        return result;
    }
    pub fn refract(v: Vector3, n: Vector3, r: f32) Vector3 {
        var result: Vector3 = Vector3{ .x = 0, .y = 0, .z = 0 };
        const dot: f32 = ((v.x * n.x) + (v.y * n.y)) + (v.z * n.z);
        var d: f32 = 1.0 - ((r * r) * (1.0 - (dot * dot)));
        if (d >= 0.0) {
            d = sqrtf(d);
            v.x = (r * v.x) - (((r * dot) + d) * n.x);
            v.y = (r * v.y) - (((r * dot) + d) * n.y);
            v.z = (r * v.z) - (((r * dot) + d) * n.z);
            result = v;
        }
        return result;
    }
    pub fn one() Vector3 {
        return .{ .x = 1.0, .y = 1.0, .z = 1.0 };
    }
    pub fn addValue(v: Vector3, add_v: f32) Vector3 {
        return .{ .x = v.x + add_v, .y = v.y + add_v, .z = v.z + add_v };
    }
    pub fn subtractValue(v: Vector3, sub_v: f32) Vector3 {
        return .{ .x = v.x - sub_v, .y = v.y - sub_v, .z = v.z - sub_v };
    }
    pub fn multiply(v1: Vector3, v2: Vector3) Vector3 {
        return .{ .x = v1.x * v2.x, .y = v1.y * v2.y, .z = v1.z * v2.z };
    }
    pub fn perpendicular(v: Vector3) Vector3 {
        var result: Vector3 = Vector3{ .x = 0, .y = 0, .z = 0 };
        var min_v: f32 = fabsf(v.x);
        var cardinalAxis: Vector3 = Vector3{
            .x = 1.0,
            .y = 0.0,
            .z = 0.0,
        };
        if (fabsf(v.y) < min_v) {
            min_v = fabsf(v.y);
            const tmp: Vector3 = Vector3{
                .x = 0.0,
                .y = 1.0,
                .z = 0.0,
            };
            cardinalAxis = tmp;
        }
        if (fabsf(v.z) < min_v) {
            const tmp: Vector3 = Vector3{
                .x = 0.0,
                .y = 0.0,
                .z = 1.0,
            };
            cardinalAxis = tmp;
        }
        result.x = (v.y * cardinalAxis.z) - (v.z * cardinalAxis.y);
        result.y = (v.z * cardinalAxis.x) - (v.x * cardinalAxis.z);
        result.z = (v.x * cardinalAxis.y) - (v.y * cardinalAxis.x);
        return result;
    }
    pub fn lengthSqr(v: Vector3) f32 {
        const result: f32 = ((v.x * v.x) + (v.y * v.y)) + (v.z * v.z);
        return result;
    }
    pub fn distance(v1: Vector3, v2: Vector3) f32 {
        var result: f32 = 0.0;
        const dx: f32 = v2.x - v1.x;
        const dy: f32 = v2.y - v1.y;
        const dz: f32 = v2.z - v1.z;
        result = sqrtf(((dx * dx) + (dy * dy)) + (dz * dz));
        return result;
    }
    pub fn angle(v1: Vector3, v2: Vector3) f32 {
        var result: f32 = 0.0;
        const cross: Vector3 = Vector3{
            .x = (v1.y * v2.z) - (v1.z * v2.y),
            .y = (v1.z * v2.x) - (v1.x * v2.z),
            .z = (v1.x * v2.y) - (v1.y * v2.x),
        };
        const len: f32 = sqrtf(((cross.x * cross.x) + (cross.y * cross.y)) + (cross.z * cross.z));
        const dot: f32 = ((v1.x * v2.x) + (v1.y * v2.y)) + (v1.z * v2.z);
        result = atan2f(len, dot);
        return result;
    }
    pub fn divide(v1: Vector3, v2: Vector3) Vector3 {
        return .{ .x = v1.x / v2.x, .y = v1.y / v2.y, .z = v1.z / v2.z };
    }
    pub fn project(v1: Vector3, v2: Vector3) Vector3 {
        var result: Vector3 = Vector3{ .x = 0, .y = 0, .z = 0 };
        const v1dv2: f32 = ((v1.x * v2.x) + (v1.y * v2.y)) + (v1.z * v2.z);
        const v2dv2: f32 = ((v2.x * v2.x) + (v2.y * v2.y)) + (v2.z * v2.z);
        const mag: f32 = v1dv2 / v2dv2;
        result.x = v2.x * mag;
        result.y = v2.y * mag;
        result.z = v2.z * mag;
        return result;
    }
    pub fn orthoNormalize(v1: [*c]Vector3, v2: [*c]Vector3) void {
        var length_v: f32 = 0.0;
        var ilength: f32 = 0.0;
        var v: Vector3 = v1.*;
        length_v = sqrtf(((v.x * v.x) + (v.y * v.y)) + (v.z * v.z));
        if (length_v == 0.0) {
            length_v = 1.0;
        }
        ilength = 1.0 / length_v;
        v1.*.x *= ilength;
        v1.*.y *= ilength;
        v1.*.z *= ilength;
        var vn1: Vector3 = Vector3{
            .x = (v1.*.y * v2.*.z) - (v1.*.z * v2.*.y),
            .y = (v1.*.z * v2.*.x) - (v1.*.x * v2.*.z),
            .z = (v1.*.x * v2.*.y) - (v1.*.y * v2.*.x),
        };
        v = vn1;
        length_v = sqrtf(((v.x * v.x) + (v.y * v.y)) + (v.z * v.z));
        if (length_v == 0.0) {
            length_v = 1.0;
        }
        ilength = 1.0 / length_v;
        vn1.x *= ilength;
        vn1.y *= ilength;
        vn1.z *= ilength;
        const vn2: Vector3 = Vector3{
            .x = (vn1.y * v1.*.z) - (vn1.z * v1.*.y),
            .y = (vn1.z * v1.*.x) - (vn1.x * v1.*.z),
            .z = (vn1.x * v1.*.y) - (vn1.y * v1.*.x),
        };
        v2.* = vn2;
    }
    pub fn rotateByQuaternion(v: Vector3, q: Quaternion) Vector3 {
        var result: Vector3 = Vector3{ .x = 0, .y = 0, .z = 0 };
        result.x = ((v.x * ((((q.x * q.x) + (q.w * q.w)) - (q.y * q.y)) - (q.z * q.z))) + (v.y * (((2 * q.x) * q.y) - ((2 * q.w) * q.z)))) + (v.z * (((2 * q.x) * q.z) + ((2 * q.w) * q.y)));
        result.y = ((v.x * (((2 * q.w) * q.z) + ((2 * q.x) * q.y))) + (v.y * ((((q.w * q.w) - (q.x * q.x)) + (q.y * q.y)) - (q.z * q.z)))) + (v.z * (((@as(f32, @floatFromInt(-@as(c_int, 2))) * q.w) * q.x) + ((2 * q.y) * q.z)));
        result.z = ((v.x * (((@as(f32, @floatFromInt(-@as(c_int, 2))) * q.w) * q.y) + ((2 * q.x) * q.z))) + (v.y * (((2 * q.w) * q.x) + ((2 * q.y) * q.z)))) + (v.z * ((((q.w * q.w) - (q.x * q.x)) - (q.y * q.y)) + (q.z * q.z)));
        return result;
    }
    pub fn moveTowards(v: Vector3, target: Vector3, maxDistance: f32) Vector3 {
        var result: Vector3 = Vector3{ .x = 0, .y = 0, .z = 0 };
        const dx: f32 = target.x - v.x;
        const dy: f32 = target.y - v.y;
        const dz: f32 = target.z - v.z;
        const value: f32 = ((dx * dx) + (dy * dy)) + (dz * dz);
        if ((value == 0) or ((maxDistance >= 0) and (value <= (maxDistance * maxDistance)))) return target;
        const dist: f32 = sqrtf(value);
        result.x = v.x + ((dx / dist) * maxDistance);
        result.y = v.y + ((dy / dist) * maxDistance);
        result.z = v.z + ((dz / dist) * maxDistance);
        return result;
    }
    pub fn cubicHermite(v1: Vector3, tangent1: Vector3, v2: Vector3, tangent2: Vector3, amount: f32) Vector3 {
        var result: Vector3 = Vector3{ .x = 0, .y = 0, .z = 0 };
        const amountPow2: f32 = amount * amount;
        const amountPow3: f32 = (amount * amount) * amount;
        result.x = ((((((2 * amountPow3) - (3 * amountPow2)) + 1) * v1.x) + (((amountPow3 - (2 * amountPow2)) + amount) * tangent1.x)) + (((@as(f32, @floatFromInt(-@as(c_int, 2))) * amountPow3) + (3 * amountPow2)) * v2.x)) + ((amountPow3 - amountPow2) * tangent2.x);
        result.y = ((((((2 * amountPow3) - (3 * amountPow2)) + 1) * v1.y) + (((amountPow3 - (2 * amountPow2)) + amount) * tangent1.y)) + (((@as(f32, @floatFromInt(-@as(c_int, 2))) * amountPow3) + (3 * amountPow2)) * v2.y)) + ((amountPow3 - amountPow2) * tangent2.y);
        result.z = ((((((2 * amountPow3) - (3 * amountPow2)) + 1) * v1.z) + (((amountPow3 - (2 * amountPow2)) + amount) * tangent1.z)) + (((@as(f32, @floatFromInt(-@as(c_int, 2))) * amountPow3) + (3 * amountPow2)) * v2.z)) + ((amountPow3 - amountPow2) * tangent2.z);
        return result;
    }
    pub fn min(v1: Vector3, v2: Vector3) Vector3 {
        var result: Vector3 = Vector3{ .x = 0, .y = 0, .z = 0 };
        result.x = fminf(v1.x, v2.x);
        result.y = fminf(v1.y, v2.y);
        result.z = fminf(v1.z, v2.z);
        return result;
    }
    pub fn barycenter(p: Vector3, a: Vector3, b: Vector3, c: Vector3) Vector3 {
        var result: Vector3 = Vector3{ .x = 0, .y = 0, .z = 0 };
        const v0: Vector3 = Vector3{ .x = b.x - a.x, .y = b.y - a.y, .z = b.z - a.z };
        const v1: Vector3 = Vector3{ .x = c.x - a.x, .y = c.y - a.y, .z = c.z - a.z };
        const v2: Vector3 = Vector3{ .x = p.x - a.x, .y = p.y - a.y, .z = p.z - a.z };
        const d00: f32 = ((v0.x * v0.x) + (v0.y * v0.y)) + (v0.z * v0.z);
        const d01: f32 = ((v0.x * v1.x) + (v0.y * v1.y)) + (v0.z * v1.z);
        const d11: f32 = ((v1.x * v1.x) + (v1.y * v1.y)) + (v1.z * v1.z);
        const d20: f32 = ((v2.x * v0.x) + (v2.y * v0.y)) + (v2.z * v0.z);
        const d21: f32 = ((v2.x * v1.x) + (v2.y * v1.y)) + (v2.z * v1.z);
        const denom: f32 = (d00 * d11) - (d01 * d01);
        result.y = ((d11 * d20) - (d01 * d21)) / denom;
        result.z = ((d00 * d21) - (d01 * d20)) / denom;
        result.x = 1.0 - (result.z + result.y);
        return result;
    }
    pub fn toFloatV(v: Vector3) float3 {
        var buffer: float3 = float3{
            .v = [1]f32{
                0,
            } ++ [1]f32{0} ** 2,
        };
        buffer.v[@as(c_uint, @intCast(@as(c_int, 0)))] = v.x;
        buffer.v[@as(c_uint, @intCast(@as(c_int, 1)))] = v.y;
        buffer.v[@as(c_uint, @intCast(@as(c_int, 2)))] = v.z;
        return buffer;
    }
    pub fn clamp(v: Vector3, min_v: Vector3, max_v: Vector3) Vector3 {
        var result: Vector3 = Vector3{ .x = 0, .y = 0, .z = 0 };
        result.x = fminf(max_v.x, fmaxf(min_v.x, v.x));
        result.y = fminf(max_v.y, fmaxf(min_v.y, v.y));
        result.z = fminf(max_v.z, fmaxf(min_v.z, v.z));
        return result;
    }
    pub fn equals(p: Vector3, q: Vector3) c_int {
        const result: c_int = @intFromBool(((fabsf(p.x - q.x) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.x), fabsf(q.x))))) and (fabsf(p.y - q.y) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.y), fabsf(q.y)))))) and (fabsf(p.z - q.z) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.z), fabsf(q.z))))));
        return result;
    }
};

pub const Vector4 = extern struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,
    pub fn zero() Vector4 {
        return .{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 0.0 };
    }
    pub fn one() Vector4 {
        return .{ .x = 1.0, .y = 1.0, .z = 1.0, .w = 1.0 };
    }
    pub fn addValue(v: Vector4, add_v: f32) Vector4 {
        return .{ .x = v.x + add_v, .y = v.y + add_v, .z = v.z + add_v, .w = v.w + add_v };
    }
    pub fn subtractValue(v: Vector4, add_v: f32) Vector4 {
        return .{ .x = v.x - add_v, .y = v.y - add_v, .z = v.z - add_v, .w = v.w - add_v };
    }
    pub fn lengthSqr(v: Vector4) f32 {
        const result: f32 = (((v.x * v.x) + (v.y * v.y)) + (v.z * v.z)) + (v.w * v.w);
        return result;
    }
    pub fn distance(v1: Vector4, v2: Vector4) f32 {
        const result: f32 = sqrtf(((((v1.x - v2.x) * (v1.x - v2.x)) + ((v1.y - v2.y) * (v1.y - v2.y))) + ((v1.z - v2.z) * (v1.z - v2.z))) + ((v1.w - v2.w) * (v1.w - v2.w)));
        return result;
    }
    pub fn scale(v: Vector4, scale_v: f32) Vector4 {
        return .{ .x = v.x * scale_v, .y = v.y * scale_v, .z = v.z * scale_v, .w = v.w * scale_v };
    }
    pub fn negate(v: Vector4) Vector4 {
        return .{ .x = -v.x, .y = -v.y, .z = -v.z, .w = -v.w };
    }
    pub fn normalize(v: Vector4) Vector4 {
        var result: Vector4 = Vector4{ .x = 0, .y = 0, .z = 0, .w = 0 };
        const length_v: f32 = sqrtf((((v.x * v.x) + (v.y * v.y)) + (v.z * v.z)) + (v.w * v.w));
        if (length_v > 0) {
            const ilength: f32 = 1.0 / length_v;
            result.x = v.x * ilength;
            result.y = v.y * ilength;
            result.z = v.z * ilength;
            result.w = v.w * ilength;
        }
        return result;
    }
    pub fn max(v1: Vector4, v2: Vector4) Vector4 {
        var result: Vector4 = Vector4{ .x = 0, .y = 0, .z = 0, .w = 0 };
        result.x = fmaxf(v1.x, v2.x);
        result.y = fmaxf(v1.y, v2.y);
        result.z = fmaxf(v1.z, v2.z);
        result.w = fmaxf(v1.w, v2.w);
        return result;
    }
    pub fn add(v1: Vector4, v2: Vector4) Vector4 {
        return .{ .x = v1.x + v2.x, .y = v1.y + v2.y, .z = v1.z + v2.z, .w = v1.w + v2.w };
    }
    pub fn subtract(v1: Vector4, v2: Vector4) Vector4 {
        return .{ .x = v1.x - v2.x, .y = v1.y - v2.y, .z = v1.z - v2.z, .w = v1.w - v2.w };
    }
    pub fn length(v: Vector4) f32 {
        const result: f32 = sqrtf((((v.x * v.x) + (v.y * v.y)) + (v.z * v.z)) + (v.w * v.w));
        return result;
    }
    pub fn dotProduct(v1: Vector4, v2: Vector4) f32 {
        const result: f32 = (((v1.x * v2.x) + (v1.y * v2.y)) + (v1.z * v2.z)) + (v1.w * v2.w);
        return result;
    }
    pub fn distanceSqr(v1: Vector4, v2: Vector4) f32 {
        const result: f32 = ((((v1.x - v2.x) * (v1.x - v2.x)) + ((v1.y - v2.y) * (v1.y - v2.y))) + ((v1.z - v2.z) * (v1.z - v2.z))) + ((v1.w - v2.w) * (v1.w - v2.w));
        return result;
    }
    pub fn multiply(v1: Vector4, v2: Vector4) Vector4 {
        return .{ .x = v1.x * v2.x, .y = v1.y * v2.y, .z = v1.z * v2.z, .w = v1.w * v2.w };
    }
    pub fn divide(v1: Vector4, v2: Vector4) Vector4 {
        return .{ .x = v1.x / v2.x, .y = v1.y / v2.y, .z = v1.z / v2.z, .w = v1.w / v2.w };
    }
    pub fn min(v1: Vector4, v2: Vector4) Vector4 {
        var result: Vector4 = Vector4{ .x = 0, .y = 0, .z = 0, .w = 0 };
        result.x = fminf(v1.x, v2.x);
        result.y = fminf(v1.y, v2.y);
        result.z = fminf(v1.z, v2.z);
        result.w = fminf(v1.w, v2.w);
        return result;
    }
    pub fn lerp(v1: Vector4, v2: Vector4, amount: f32) Vector4 {
        var result: Vector4 = Vector4{ .x = 0, .y = 0, .z = 0, .w = 0 };
        result.x = v1.x + (amount * (v2.x - v1.x));
        result.y = v1.y + (amount * (v2.y - v1.y));
        result.z = v1.z + (amount * (v2.z - v1.z));
        result.w = v1.w + (amount * (v2.w - v1.w));
        return result;
    }
    pub fn invert(v: Vector4) Vector4 {
        return .{ .x = 1.0 / v.x, .y = 1.0 / v.y, .z = 1.0 / v.z, .w = 1.0 / v.w };
    }
    pub fn equals(p: Vector4, q: Vector4) c_int {
        const result: c_int = @intFromBool((((fabsf(p.x - q.x) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.x), fabsf(q.x))))) and (fabsf(p.y - q.y) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.y), fabsf(q.y)))))) and (fabsf(p.z - q.z) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.z), fabsf(q.z)))))) and (fabsf(p.w - q.w) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.w), fabsf(q.w))))));
        return result;
    }
    pub fn moveTowards(v: Vector4, target: Vector4, maxDistance: f32) Vector4 {
        var result: Vector4 = Vector4{ .x = 0, .y = 0, .z = 0, .w = 0 };
        const dx: f32 = target.x - v.x;
        const dy: f32 = target.y - v.y;
        const dz: f32 = target.z - v.z;
        const dw: f32 = target.w - v.w;
        const value: f32 = (((dx * dx) + (dy * dy)) + (dz * dz)) + (dw * dw);
        if ((value == 0) or ((maxDistance >= 0) and (value <= (maxDistance * maxDistance)))) return target;
        const dist: f32 = sqrtf(value);
        result.x = v.x + ((dx / dist) * maxDistance);
        result.y = v.y + ((dy / dist) * maxDistance);
        result.z = v.z + ((dz / dist) * maxDistance);
        result.w = v.w + ((dw / dist) * maxDistance);
        return result;
    }
};
pub const Quaternion = Vector4;

pub const float3 = extern struct {
    v: [3]f32,
};

// zig fmt: off
pub const Matrix = extern struct {
    m0: f32, m4: f32, m8:  f32, m12: f32,
    m1: f32, m5: f32, m9:  f32, m13: f32,
    m2: f32, m6: f32, m10: f32, m14: f32,
    m3: f32, m7: f32, m11: f32, m15: f32,
};
// zig fmt: on
