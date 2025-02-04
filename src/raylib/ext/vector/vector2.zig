const util = @import("util.zig");
const feql = util.feql;
const float3 = util.float3;
const std = @import("std");
const math = std.math;
const atan2 = math.atan2;
const vector4 = @import("vector4.zig");
const Matrix = vector4.Matrix;
const Quaternion = vector4.Quaternion;

pub const Vector2 = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    pub fn from(t: anytype) Vector2 {
        return .{ .x = t.x, .y = t.y };
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
        return @sqrt((v.x * v.x) + (v.y * v.y));
    }
    pub fn dotProduct(v1: Vector2, v2: Vector2) f32 {
        return (v1.x * v2.x) + (v1.y * v2.y);
    }
    pub fn distanceSqr(v1: Vector2, v2: Vector2) f32 {
        return ((v1.x - v2.x) * (v1.x - v2.x)) + ((v1.y - v2.y) * (v1.y - v2.y));
    }
    pub fn lineAngle(start: Vector2, end: Vector2) f32 {
        return -atan2(end.y - start.y, end.x - start.x);
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
            .x = @max(v1.x, v2.x),
            .y = @max(v1.y, v2.y),
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
        const dist: f32 = @sqrt(value);
        result.x = v.x + ((dx / dist) * maxDistance);
        result.y = v.y + ((dy / dist) * maxDistance);
        return result;
    }
    pub fn clamp(v: Vector2, min_v: Vector2, max_v: Vector2) Vector2 {
        return .{
            .x = @min(max_v.x, @max(min_v.x, v.x)),
            .y = @min(max_v.y, @max(min_v.y, v.y)),
        };
    }
    pub fn equals(p: Vector2, q: Vector2) bool {
        return feql(p.x, q.x) and
            feql(p.y, q.y);
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
        return @sqrt(((v1.x - v2.x) * (v1.x - v2.x)) + ((v1.y - v2.y) * (v1.y - v2.y)));
    }
    pub fn angle(v1: Vector2, v2: Vector2) f32 {
        const dot: f32 = (v1.x * v2.x) + (v1.y * v2.y);
        const det: f32 = (v1.x * v2.y) - (v1.y * v2.x);
        return atan2(det, dot);
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
        const length_v: f32 = @sqrt((v.x * v.x) + (v.y * v.y));
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
            .x = @min(v1.x, v2.x),
            .y = @min(v1.y, v2.y),
        };
    }
    pub fn rotate(v: Vector2, angle_v: f32) Vector2 {
        const cosres: f32 = @cos(angle_v);
        const sinres: f32 = @sin(angle_v);
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
            length_v = @sqrt(length_v);
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
            d = @sqrt(d);
            v.x = (r * v.x) - (((r * dot) + d) * n.x);
            v.y = (r * v.y) - (((r * dot) + d) * n.y);
            result = v;
        }
        return result;
    }
};
