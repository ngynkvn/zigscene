const feql = @import("util.zig").feql;

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
        const result: f32 = @sqrt(((((v1.x - v2.x) * (v1.x - v2.x)) + ((v1.y - v2.y) * (v1.y - v2.y))) + ((v1.z - v2.z) * (v1.z - v2.z))) + ((v1.w - v2.w) * (v1.w - v2.w)));
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
        const length_v: f32 = @sqrt((((v.x * v.x) + (v.y * v.y)) + (v.z * v.z)) + (v.w * v.w));
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
        result.x = @max(v1.x, v2.x);
        result.y = @max(v1.y, v2.y);
        result.z = @max(v1.z, v2.z);
        result.w = @max(v1.w, v2.w);
        return result;
    }
    pub fn add(v1: Vector4, v2: Vector4) Vector4 {
        return .{ .x = v1.x + v2.x, .y = v1.y + v2.y, .z = v1.z + v2.z, .w = v1.w + v2.w };
    }
    pub fn subtract(v1: Vector4, v2: Vector4) Vector4 {
        return .{ .x = v1.x - v2.x, .y = v1.y - v2.y, .z = v1.z - v2.z, .w = v1.w - v2.w };
    }
    pub fn length(v: Vector4) f32 {
        const result: f32 = @sqrt((((v.x * v.x) + (v.y * v.y)) + (v.z * v.z)) + (v.w * v.w));
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
        result.x = @min(v1.x, v2.x);
        result.y = @min(v1.y, v2.y);
        result.z = @min(v1.z, v2.z);
        result.w = @min(v1.w, v2.w);
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
        return feql(p.x, q.x) and
            feql(p.y, q.y) and
            feql(p.z, q.z) and
            feql(p.w, q.w);
    }
    pub fn moveTowards(v: Vector4, target: Vector4, maxDistance: f32) Vector4 {
        var result: Vector4 = Vector4{ .x = 0, .y = 0, .z = 0, .w = 0 };
        const dx: f32 = target.x - v.x;
        const dy: f32 = target.y - v.y;
        const dz: f32 = target.z - v.z;
        const dw: f32 = target.w - v.w;
        const value: f32 = (((dx * dx) + (dy * dy)) + (dz * dz)) + (dw * dw);
        if ((value == 0) or ((maxDistance >= 0) and (value <= (maxDistance * maxDistance)))) return target;
        const dist: f32 = @sqrt(value);
        result.x = v.x + ((dx / dist) * maxDistance);
        result.y = v.y + ((dy / dist) * maxDistance);
        result.z = v.z + ((dz / dist) * maxDistance);
        result.w = v.w + ((dw / dist) * maxDistance);
        return result;
    }
};
pub const Quaternion = Vector4;

// zig fmt: off
pub const Matrix = extern struct {
    m0: f32, m4: f32, m8:  f32, m12: f32,
    m1: f32, m5: f32, m9:  f32, m13: f32,
    m2: f32, m6: f32, m10: f32, m14: f32,
    m3: f32, m7: f32, m11: f32, m15: f32,
};
// zig fmt: on
