const V = @import("V.zig");
const Vector2 = V.Vector2;
const Vector3 = V.Vector3;
const Vector4 = V.Vector4;
const Matrix = V.Matrix;
const Quaternion = V.Quaternion;
pub extern fn atan2f(f32, f32) f32;
pub extern fn cosf(f32) f32;
pub extern fn fabsf(f32) f32;
pub extern fn floorf(f32) f32;
pub extern fn fmaxf(f32, f32) f32;
pub extern fn fminf(f32, f32) f32;
pub extern fn sqrtf(f32) f32;
pub extern fn tan(f64) f64;
pub extern fn sinf(f32) f32;
pub extern fn acosf(f32) f32;
pub extern fn asinf(f32) f32;
pub const struct_float3 = extern struct {
    v: [3]f32 = @import("std").mem.zeroes([3]f32),
};
pub const float3 = struct_float3;
pub const struct_float16 = extern struct {
    v: [16]f32 = @import("std").mem.zeroes([16]f32),
};
pub const float16 = struct_float16;
pub const float_t = f32;
pub const double_t = f64;
pub fn Clamp(arg_value: f32, arg_min: f32, arg_max: f32) callconv(.C) f32 {
    const value = arg_value;
    const min = arg_min;
    const max = arg_max;
    var result: f32 = if (value < min) min else value;
    if (result > max) {
        result = max;
    }
    return result;
}
pub fn Lerp(arg_start: f32, arg_end: f32, arg_amount: f32) callconv(.C) f32 {
    const start = arg_start;
    const end = arg_end;
    const amount = arg_amount;
    const result: f32 = start + (amount * (end - start));
    return result;
}
pub fn Normalize(arg_value: f32, arg_start: f32, arg_end: f32) callconv(.C) f32 {
    const value = arg_value;
    const start = arg_start;
    const end = arg_end;
    const result: f32 = (value - start) / (end - start);
    return result;
}
pub fn Remap(arg_value: f32, arg_inputStart: f32, arg_inputEnd: f32, arg_outputStart: f32, arg_outputEnd: f32) callconv(.C) f32 {
    const value = arg_value;
    const inputStart = arg_inputStart;
    const inputEnd = arg_inputEnd;
    const outputStart = arg_outputStart;
    const outputEnd = arg_outputEnd;
    const result: f32 = (((value - inputStart) / (inputEnd - inputStart)) * (outputEnd - outputStart)) + outputStart;
    return result;
}
pub fn Wrap(arg_value: f32, arg_min: f32, arg_max: f32) callconv(.C) f32 {
    const value = arg_value;
    const min = arg_min;
    const max = arg_max;
    const result: f32 = value - ((max - min) * floorf((value - min) / (max - min)));
    return result;
}
pub fn FloatEquals(arg_x: f32, arg_y: f32) callconv(.C) c_int {
    const x = arg_x;
    const y = arg_y;
    const result: c_int = @intFromBool(fabsf(x - y) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(x), fabsf(y)))));
    return result;
}
pub fn Vector2Zero() callconv(.C) Vector2 {
    const result: Vector2 = Vector2{
        .x = 0.0,
        .y = 0.0,
    };
    return result;
}
pub fn Vector2One() callconv(.C) Vector2 {
    const result: Vector2 = Vector2{
        .x = 1.0,
        .y = 1.0,
    };
    return result;
}
pub fn Vector2Add(arg_v1: Vector2, arg_v2: Vector2) callconv(.C) Vector2 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: Vector2 = Vector2{
        .x = v1.x + v2.x,
        .y = v1.y + v2.y,
    };
    return result;
}
pub fn Vector2AddValue(arg_v: Vector2, arg_add: f32) callconv(.C) Vector2 {
    const v = arg_v;
    const add = arg_add;
    const result: Vector2 = Vector2{
        .x = v.x + add,
        .y = v.y + add,
    };
    return result;
}
pub fn Vector2Subtract(arg_v1: Vector2, arg_v2: Vector2) callconv(.C) Vector2 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: Vector2 = Vector2{
        .x = v1.x - v2.x,
        .y = v1.y - v2.y,
    };
    return result;
}
pub fn Vector2SubtractValue(arg_v: Vector2, arg_sub: f32) callconv(.C) Vector2 {
    const v = arg_v;
    const sub = arg_sub;
    const result: Vector2 = Vector2{
        .x = v.x - sub,
        .y = v.y - sub,
    };
    return result;
}
pub fn Vector2Length(arg_v: Vector2) callconv(.C) f32 {
    const v = arg_v;
    const result: f32 = sqrtf((v.x * v.x) + (v.y * v.y));
    return result;
}
pub fn Vector2LengthSqr(arg_v: Vector2) callconv(.C) f32 {
    const v = arg_v;
    const result: f32 = (v.x * v.x) + (v.y * v.y);
    return result;
}
pub fn Vector2DotProduct(arg_v1: Vector2, arg_v2: Vector2) callconv(.C) f32 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: f32 = (v1.x * v2.x) + (v1.y * v2.y);
    return result;
}
pub fn Vector2Distance(arg_v1: Vector2, arg_v2: Vector2) callconv(.C) f32 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: f32 = sqrtf(((v1.x - v2.x) * (v1.x - v2.x)) + ((v1.y - v2.y) * (v1.y - v2.y)));
    return result;
}
pub fn Vector2DistanceSqr(arg_v1: Vector2, arg_v2: Vector2) callconv(.C) f32 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: f32 = ((v1.x - v2.x) * (v1.x - v2.x)) + ((v1.y - v2.y) * (v1.y - v2.y));
    return result;
}
pub fn Vector2Angle(arg_v1: Vector2, arg_v2: Vector2) callconv(.C) f32 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    var result: f32 = 0.0;
    const dot: f32 = (v1.x * v2.x) + (v1.y * v2.y);
    const det: f32 = (v1.x * v2.y) - (v1.y * v2.x);
    result = atan2f(det, dot);
    return result;
}
pub fn Vector2LineAngle(arg_start: Vector2, arg_end: Vector2) callconv(.C) f32 {
    const start = arg_start;
    const end = arg_end;
    var result: f32 = 0.0;
    result = -atan2f(end.y - start.y, end.x - start.x);
    return result;
}
pub fn Vector2Scale(arg_v: Vector2, arg_scale: f32) callconv(.C) Vector2 {
    const v = arg_v;
    const scale = arg_scale;
    const result: Vector2 = Vector2{
        .x = v.x * scale,
        .y = v.y * scale,
    };
    return result;
}
pub fn Vector2Multiply(arg_v1: Vector2, arg_v2: Vector2) callconv(.C) Vector2 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: Vector2 = Vector2{
        .x = v1.x * v2.x,
        .y = v1.y * v2.y,
    };
    return result;
}
pub fn Vector2Negate(arg_v: Vector2) callconv(.C) Vector2 {
    const v = arg_v;
    const result: Vector2 = Vector2{
        .x = -v.x,
        .y = -v.y,
    };
    return result;
}
pub fn Vector2Divide(arg_v1: Vector2, arg_v2: Vector2) callconv(.C) Vector2 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: Vector2 = Vector2{
        .x = v1.x / v2.x,
        .y = v1.y / v2.y,
    };
    return result;
}
pub fn Vector2Normalize(arg_v: Vector2) callconv(.C) Vector2 {
    const v = arg_v;
    var result: Vector2 = Vector2{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
    };
    const length: f32 = sqrtf((v.x * v.x) + (v.y * v.y));
    if (length > @as(f32, @floatFromInt(@as(c_int, 0)))) {
        const ilength: f32 = 1.0 / length;
        result.x = v.x * ilength;
        result.y = v.y * ilength;
    }
    return result;
}
pub fn Vector2Transform(arg_v: Vector2, arg_mat: Matrix) callconv(.C) Vector2 {
    const v = arg_v;
    const mat = arg_mat;
    var result: Vector2 = Vector2{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
    };
    const x: f32 = v.x;
    const y: f32 = v.y;
    const z: f32 = 0;
    result.x = (((mat.m0 * x) + (mat.m4 * y)) + (mat.m8 * z)) + mat.m12;
    result.y = (((mat.m1 * x) + (mat.m5 * y)) + (mat.m9 * z)) + mat.m13;
    return result;
}
pub fn Vector2Lerp(arg_v1: Vector2, arg_v2: Vector2, arg_amount: f32) callconv(.C) Vector2 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const amount = arg_amount;
    var result: Vector2 = Vector2{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
    };
    result.x = v1.x + (amount * (v2.x - v1.x));
    result.y = v1.y + (amount * (v2.y - v1.y));
    return result;
}
pub fn Vector2Reflect(arg_v: Vector2, arg_normal: Vector2) callconv(.C) Vector2 {
    const v = arg_v;
    const normal = arg_normal;
    var result: Vector2 = Vector2{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
    };
    const dotProduct: f32 = (v.x * normal.x) + (v.y * normal.y);
    result.x = v.x - ((2.0 * normal.x) * dotProduct);
    result.y = v.y - ((2.0 * normal.y) * dotProduct);
    return result;
}
pub fn Vector2Min(arg_v1: Vector2, arg_v2: Vector2) callconv(.C) Vector2 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    var result: Vector2 = Vector2{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
    };
    result.x = fminf(v1.x, v2.x);
    result.y = fminf(v1.y, v2.y);
    return result;
}
pub fn Vector2Max(arg_v1: Vector2, arg_v2: Vector2) callconv(.C) Vector2 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    var result: Vector2 = Vector2{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
    };
    result.x = fmaxf(v1.x, v2.x);
    result.y = fmaxf(v1.y, v2.y);
    return result;
}
pub fn Vector2Rotate(arg_v: Vector2, arg_angle: f32) callconv(.C) Vector2 {
    const v = arg_v;
    const angle = arg_angle;
    var result: Vector2 = Vector2{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
    };
    const cosres: f32 = cosf(angle);
    const sinres: f32 = sinf(angle);
    result.x = (v.x * cosres) - (v.y * sinres);
    result.y = (v.x * sinres) + (v.y * cosres);
    return result;
}
pub fn Vector2MoveTowards(arg_v: Vector2, arg_target: Vector2, arg_maxDistance: f32) callconv(.C) Vector2 {
    const v = arg_v;
    const target = arg_target;
    const maxDistance = arg_maxDistance;
    var result: Vector2 = Vector2{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
    };
    const dx: f32 = target.x - v.x;
    const dy: f32 = target.y - v.y;
    const value: f32 = (dx * dx) + (dy * dy);
    if ((value == @as(f32, @floatFromInt(@as(c_int, 0)))) or ((maxDistance >= @as(f32, @floatFromInt(@as(c_int, 0)))) and (value <= (maxDistance * maxDistance)))) return target;
    const dist: f32 = sqrtf(value);
    result.x = v.x + ((dx / dist) * maxDistance);
    result.y = v.y + ((dy / dist) * maxDistance);
    return result;
}
pub fn Vector2Invert(arg_v: Vector2) callconv(.C) Vector2 {
    const v = arg_v;
    const result: Vector2 = Vector2{
        .x = 1.0 / v.x,
        .y = 1.0 / v.y,
    };
    return result;
}
pub fn Vector2Clamp(arg_v: Vector2, arg_min: Vector2, arg_max: Vector2) callconv(.C) Vector2 {
    const v = arg_v;
    const min = arg_min;
    const max = arg_max;
    var result: Vector2 = Vector2{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
    };
    result.x = fminf(max.x, fmaxf(min.x, v.x));
    result.y = fminf(max.y, fmaxf(min.y, v.y));
    return result;
}
pub fn Vector2ClampValue(arg_v: Vector2, arg_min: f32, arg_max: f32) callconv(.C) Vector2 {
    const v = arg_v;
    const min = arg_min;
    const max = arg_max;
    var result: Vector2 = v;
    var length: f32 = (v.x * v.x) + (v.y * v.y);
    if (length > 0.0) {
        length = sqrtf(length);
        var scale: f32 = 1;
        if (length < min) {
            scale = min / length;
        } else if (length > max) {
            scale = max / length;
        }
        result.x = v.x * scale;
        result.y = v.y * scale;
    }
    return result;
}
pub fn Vector2Equals(arg_p: Vector2, arg_q: Vector2) callconv(.C) c_int {
    const p = arg_p;
    const q = arg_q;
    const result: c_int = @intFromBool((fabsf(p.x - q.x) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.x), fabsf(q.x))))) and (fabsf(p.y - q.y) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.y), fabsf(q.y))))));
    return result;
}
pub fn Vector2Refract(arg_v: Vector2, arg_n: Vector2, arg_r: f32) callconv(.C) Vector2 {
    var v = arg_v;
    const n = arg_n;
    const r = arg_r;
    var result: Vector2 = Vector2{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
    };
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
pub fn Vector3Zero() callconv(.C) Vector3 {
    const result: Vector3 = Vector3{
        .x = 0.0,
        .y = 0.0,
        .z = 0.0,
    };
    return result;
}
pub fn Vector3One() callconv(.C) Vector3 {
    const result: Vector3 = Vector3{
        .x = 1.0,
        .y = 1.0,
        .z = 1.0,
    };
    return result;
}
pub fn Vector3Add(arg_v1: Vector3, arg_v2: Vector3) callconv(.C) Vector3 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: Vector3 = Vector3{
        .x = v1.x + v2.x,
        .y = v1.y + v2.y,
        .z = v1.z + v2.z,
    };
    return result;
}
pub fn Vector3AddValue(arg_v: Vector3, arg_add: f32) callconv(.C) Vector3 {
    const v = arg_v;
    const add = arg_add;
    const result: Vector3 = Vector3{
        .x = v.x + add,
        .y = v.y + add,
        .z = v.z + add,
    };
    return result;
}
pub fn Vector3Subtract(arg_v1: Vector3, arg_v2: Vector3) callconv(.C) Vector3 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: Vector3 = Vector3{
        .x = v1.x - v2.x,
        .y = v1.y - v2.y,
        .z = v1.z - v2.z,
    };
    return result;
}
pub fn Vector3SubtractValue(arg_v: Vector3, arg_sub: f32) callconv(.C) Vector3 {
    const v = arg_v;
    const sub = arg_sub;
    const result: Vector3 = Vector3{
        .x = v.x - sub,
        .y = v.y - sub,
        .z = v.z - sub,
    };
    return result;
}
pub fn Vector3Scale(arg_v: Vector3, arg_scalar: f32) callconv(.C) Vector3 {
    const v = arg_v;
    const scalar = arg_scalar;
    const result: Vector3 = Vector3{
        .x = v.x * scalar,
        .y = v.y * scalar,
        .z = v.z * scalar,
    };
    return result;
}
pub fn Vector3Multiply(arg_v1: Vector3, arg_v2: Vector3) callconv(.C) Vector3 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: Vector3 = Vector3{
        .x = v1.x * v2.x,
        .y = v1.y * v2.y,
        .z = v1.z * v2.z,
    };
    return result;
}
pub fn Vector3CrossProduct(arg_v1: Vector3, arg_v2: Vector3) callconv(.C) Vector3 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: Vector3 = Vector3{
        .x = (v1.y * v2.z) - (v1.z * v2.y),
        .y = (v1.z * v2.x) - (v1.x * v2.z),
        .z = (v1.x * v2.y) - (v1.y * v2.x),
    };
    return result;
}
pub fn Vector3Perpendicular(arg_v: Vector3) callconv(.C) Vector3 {
    const v = arg_v;
    var result: Vector3 = Vector3{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
    };
    var min: f32 = fabsf(v.x);
    var cardinalAxis: Vector3 = Vector3{
        .x = 1.0,
        .y = 0.0,
        .z = 0.0,
    };
    if (fabsf(v.y) < min) {
        min = fabsf(v.y);
        const tmp: Vector3 = Vector3{
            .x = 0.0,
            .y = 1.0,
            .z = 0.0,
        };
        cardinalAxis = tmp;
    }
    if (fabsf(v.z) < min) {
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
pub fn Vector3Length(v: Vector3) callconv(.C) f32 {
    const result: f32 = sqrtf(((v.x * v.x) + (v.y * v.y)) + (v.z * v.z));
    return result;
}
pub fn Vector3LengthSqr(v: Vector3) callconv(.C) f32 {
    const result: f32 = ((v.x * v.x) + (v.y * v.y)) + (v.z * v.z);
    return result;
}
pub fn Vector3DotProduct(arg_v1: Vector3, arg_v2: Vector3) callconv(.C) f32 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: f32 = ((v1.x * v2.x) + (v1.y * v2.y)) + (v1.z * v2.z);
    return result;
}
pub fn Vector3Distance(arg_v1: Vector3, arg_v2: Vector3) callconv(.C) f32 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    var result: f32 = 0.0;
    const dx: f32 = v2.x - v1.x;
    const dy: f32 = v2.y - v1.y;
    const dz: f32 = v2.z - v1.z;
    result = sqrtf(((dx * dx) + (dy * dy)) + (dz * dz));
    return result;
}
pub fn Vector3DistanceSqr(arg_v1: Vector3, arg_v2: Vector3) callconv(.C) f32 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    var result: f32 = 0.0;
    const dx: f32 = v2.x - v1.x;
    const dy: f32 = v2.y - v1.y;
    const dz: f32 = v2.z - v1.z;
    result = ((dx * dx) + (dy * dy)) + (dz * dz);
    return result;
}
pub fn Vector3Angle(arg_v1: Vector3, arg_v2: Vector3) callconv(.C) f32 {
    const v1 = arg_v1;
    const v2 = arg_v2;
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
pub fn Vector3Negate(arg_v: Vector3) callconv(.C) Vector3 {
    const v = arg_v;
    const result: Vector3 = Vector3{
        .x = -v.x,
        .y = -v.y,
        .z = -v.z,
    };
    return result;
}
pub fn Vector3Divide(arg_v1: Vector3, arg_v2: Vector3) callconv(.C) Vector3 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: Vector3 = Vector3{
        .x = v1.x / v2.x,
        .y = v1.y / v2.y,
        .z = v1.z / v2.z,
    };
    return result;
}
pub fn Vector3Normalize(arg_v: Vector3) callconv(.C) Vector3 {
    const v = arg_v;
    var result: Vector3 = v;
    const length: f32 = sqrtf(((v.x * v.x) + (v.y * v.y)) + (v.z * v.z));
    if (length != 0.0) {
        const ilength: f32 = 1.0 / length;
        result.x *= ilength;
        result.y *= ilength;
        result.z *= ilength;
    }
    return result;
}
pub fn Vector3Project(arg_v1: Vector3, arg_v2: Vector3) callconv(.C) Vector3 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    var result: Vector3 = Vector3{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
    };
    const v1dv2: f32 = ((v1.x * v2.x) + (v1.y * v2.y)) + (v1.z * v2.z);
    const v2dv2: f32 = ((v2.x * v2.x) + (v2.y * v2.y)) + (v2.z * v2.z);
    const mag: f32 = v1dv2 / v2dv2;
    result.x = v2.x * mag;
    result.y = v2.y * mag;
    result.z = v2.z * mag;
    return result;
}
pub fn Vector3Reject(arg_v1: Vector3, arg_v2: Vector3) callconv(.C) Vector3 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    var result: Vector3 = Vector3{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
    };
    const v1dv2: f32 = ((v1.x * v2.x) + (v1.y * v2.y)) + (v1.z * v2.z);
    const v2dv2: f32 = ((v2.x * v2.x) + (v2.y * v2.y)) + (v2.z * v2.z);
    const mag: f32 = v1dv2 / v2dv2;
    result.x = v1.x - (v2.x * mag);
    result.y = v1.y - (v2.y * mag);
    result.z = v1.z - (v2.z * mag);
    return result;
}
pub fn Vector3OrthoNormalize(arg_v1: [*c]Vector3, arg_v2: [*c]Vector3) callconv(.C) void {
    const v1 = arg_v1;
    const v2 = arg_v2;
    var length: f32 = 0.0;
    var ilength: f32 = 0.0;
    var v: Vector3 = v1.*;
    length = sqrtf(((v.x * v.x) + (v.y * v.y)) + (v.z * v.z));
    if (length == 0.0) {
        length = 1.0;
    }
    ilength = 1.0 / length;
    v1.*.x *= ilength;
    v1.*.y *= ilength;
    v1.*.z *= ilength;
    var vn1: Vector3 = Vector3{
        .x = (v1.*.y * v2.*.z) - (v1.*.z * v2.*.y),
        .y = (v1.*.z * v2.*.x) - (v1.*.x * v2.*.z),
        .z = (v1.*.x * v2.*.y) - (v1.*.y * v2.*.x),
    };
    v = vn1;
    length = sqrtf(((v.x * v.x) + (v.y * v.y)) + (v.z * v.z));
    if (length == 0.0) {
        length = 1.0;
    }
    ilength = 1.0 / length;
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
pub fn Vector3Transform(arg_v: Vector3, arg_mat: Matrix) callconv(.C) Vector3 {
    const v = arg_v;
    const mat = arg_mat;
    var result: Vector3 = Vector3{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
    };
    const x: f32 = v.x;
    const y: f32 = v.y;
    const z: f32 = v.z;
    result.x = (((mat.m0 * x) + (mat.m4 * y)) + (mat.m8 * z)) + mat.m12;
    result.y = (((mat.m1 * x) + (mat.m5 * y)) + (mat.m9 * z)) + mat.m13;
    result.z = (((mat.m2 * x) + (mat.m6 * y)) + (mat.m10 * z)) + mat.m14;
    return result;
}
pub fn Vector3RotateByQuaternion(arg_v: Vector3, arg_q: Quaternion) callconv(.C) Vector3 {
    const v = arg_v;
    const q = arg_q;
    var result: Vector3 = Vector3{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
    };
    result.x = ((v.x * ((((q.x * q.x) + (q.w * q.w)) - (q.y * q.y)) - (q.z * q.z))) + (v.y * (((@as(f32, @floatFromInt(@as(c_int, 2))) * q.x) * q.y) - ((@as(f32, @floatFromInt(@as(c_int, 2))) * q.w) * q.z)))) + (v.z * (((@as(f32, @floatFromInt(@as(c_int, 2))) * q.x) * q.z) + ((@as(f32, @floatFromInt(@as(c_int, 2))) * q.w) * q.y)));
    result.y = ((v.x * (((@as(f32, @floatFromInt(@as(c_int, 2))) * q.w) * q.z) + ((@as(f32, @floatFromInt(@as(c_int, 2))) * q.x) * q.y))) + (v.y * ((((q.w * q.w) - (q.x * q.x)) + (q.y * q.y)) - (q.z * q.z)))) + (v.z * (((@as(f32, @floatFromInt(-@as(c_int, 2))) * q.w) * q.x) + ((@as(f32, @floatFromInt(@as(c_int, 2))) * q.y) * q.z)));
    result.z = ((v.x * (((@as(f32, @floatFromInt(-@as(c_int, 2))) * q.w) * q.y) + ((@as(f32, @floatFromInt(@as(c_int, 2))) * q.x) * q.z))) + (v.y * (((@as(f32, @floatFromInt(@as(c_int, 2))) * q.w) * q.x) + ((@as(f32, @floatFromInt(@as(c_int, 2))) * q.y) * q.z)))) + (v.z * ((((q.w * q.w) - (q.x * q.x)) - (q.y * q.y)) + (q.z * q.z)));
    return result;
}
pub fn Vector3RotateByAxisAngle(arg_v: Vector3, arg_axis: Vector3, arg_angle: f32) callconv(.C) Vector3 {
    const v = arg_v;
    var axis = arg_axis;
    var angle = arg_angle;
    var result: Vector3 = v;
    var length: f32 = sqrtf(((axis.x * axis.x) + (axis.y * axis.y)) + (axis.z * axis.z));
    if (length == 0.0) {
        length = 1.0;
    }
    const ilength: f32 = 1.0 / length;
    axis.x *= ilength;
    axis.y *= ilength;
    axis.z *= ilength;
    angle /= 2.0;
    var a: f32 = sinf(angle);
    const b: f32 = axis.x * a;
    const c: f32 = axis.y * a;
    const d: f32 = axis.z * a;
    a = cosf(angle);
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
    a *= @as(f32, @floatFromInt(@as(c_int, 2)));
    wv.x *= a;
    wv.y *= a;
    wv.z *= a;
    wwv.x *= @as(f32, @floatFromInt(@as(c_int, 2)));
    wwv.y *= @as(f32, @floatFromInt(@as(c_int, 2)));
    wwv.z *= @as(f32, @floatFromInt(@as(c_int, 2)));
    result.x += wv.x;
    result.y += wv.y;
    result.z += wv.z;
    result.x += wwv.x;
    result.y += wwv.y;
    result.z += wwv.z;
    return result;
}
pub fn Vector3MoveTowards(arg_v: Vector3, arg_target: Vector3, arg_maxDistance: f32) callconv(.C) Vector3 {
    const v = arg_v;
    const target = arg_target;
    const maxDistance = arg_maxDistance;
    var result: Vector3 = Vector3{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
    };
    const dx: f32 = target.x - v.x;
    const dy: f32 = target.y - v.y;
    const dz: f32 = target.z - v.z;
    const value: f32 = ((dx * dx) + (dy * dy)) + (dz * dz);
    if ((value == @as(f32, @floatFromInt(@as(c_int, 0)))) or ((maxDistance >= @as(f32, @floatFromInt(@as(c_int, 0)))) and (value <= (maxDistance * maxDistance)))) return target;
    const dist: f32 = sqrtf(value);
    result.x = v.x + ((dx / dist) * maxDistance);
    result.y = v.y + ((dy / dist) * maxDistance);
    result.z = v.z + ((dz / dist) * maxDistance);
    return result;
}
pub fn Vector3Lerp(arg_v1: Vector3, arg_v2: Vector3, arg_amount: f32) callconv(.C) Vector3 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const amount = arg_amount;
    var result: Vector3 = Vector3{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
    };
    result.x = v1.x + (amount * (v2.x - v1.x));
    result.y = v1.y + (amount * (v2.y - v1.y));
    result.z = v1.z + (amount * (v2.z - v1.z));
    return result;
}
pub fn Vector3CubicHermite(arg_v1: Vector3, arg_tangent1: Vector3, arg_v2: Vector3, arg_tangent2: Vector3, arg_amount: f32) callconv(.C) Vector3 {
    const v1 = arg_v1;
    const tangent1 = arg_tangent1;
    const v2 = arg_v2;
    const tangent2 = arg_tangent2;
    const amount = arg_amount;
    var result: Vector3 = Vector3{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
    };
    const amountPow2: f32 = amount * amount;
    const amountPow3: f32 = (amount * amount) * amount;
    result.x = ((((((@as(f32, @floatFromInt(@as(c_int, 2))) * amountPow3) - (@as(f32, @floatFromInt(@as(c_int, 3))) * amountPow2)) + @as(f32, @floatFromInt(@as(c_int, 1)))) * v1.x) + (((amountPow3 - (@as(f32, @floatFromInt(@as(c_int, 2))) * amountPow2)) + amount) * tangent1.x)) + (((@as(f32, @floatFromInt(-@as(c_int, 2))) * amountPow3) + (@as(f32, @floatFromInt(@as(c_int, 3))) * amountPow2)) * v2.x)) + ((amountPow3 - amountPow2) * tangent2.x);
    result.y = ((((((@as(f32, @floatFromInt(@as(c_int, 2))) * amountPow3) - (@as(f32, @floatFromInt(@as(c_int, 3))) * amountPow2)) + @as(f32, @floatFromInt(@as(c_int, 1)))) * v1.y) + (((amountPow3 - (@as(f32, @floatFromInt(@as(c_int, 2))) * amountPow2)) + amount) * tangent1.y)) + (((@as(f32, @floatFromInt(-@as(c_int, 2))) * amountPow3) + (@as(f32, @floatFromInt(@as(c_int, 3))) * amountPow2)) * v2.y)) + ((amountPow3 - amountPow2) * tangent2.y);
    result.z = ((((((@as(f32, @floatFromInt(@as(c_int, 2))) * amountPow3) - (@as(f32, @floatFromInt(@as(c_int, 3))) * amountPow2)) + @as(f32, @floatFromInt(@as(c_int, 1)))) * v1.z) + (((amountPow3 - (@as(f32, @floatFromInt(@as(c_int, 2))) * amountPow2)) + amount) * tangent1.z)) + (((@as(f32, @floatFromInt(-@as(c_int, 2))) * amountPow3) + (@as(f32, @floatFromInt(@as(c_int, 3))) * amountPow2)) * v2.z)) + ((amountPow3 - amountPow2) * tangent2.z);
    return result;
}
pub fn Vector3Reflect(arg_v: Vector3, arg_normal: Vector3) callconv(.C) Vector3 {
    const v = arg_v;
    const normal = arg_normal;
    var result: Vector3 = Vector3{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
    };
    const dotProduct: f32 = ((v.x * normal.x) + (v.y * normal.y)) + (v.z * normal.z);
    result.x = v.x - ((2.0 * normal.x) * dotProduct);
    result.y = v.y - ((2.0 * normal.y) * dotProduct);
    result.z = v.z - ((2.0 * normal.z) * dotProduct);
    return result;
}
pub fn Vector3Min(arg_v1: Vector3, arg_v2: Vector3) callconv(.C) Vector3 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    var result: Vector3 = Vector3{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
    };
    result.x = fminf(v1.x, v2.x);
    result.y = fminf(v1.y, v2.y);
    result.z = fminf(v1.z, v2.z);
    return result;
}
pub fn Vector3Max(arg_v1: Vector3, arg_v2: Vector3) callconv(.C) Vector3 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    var result: Vector3 = Vector3{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
    };
    result.x = fmaxf(v1.x, v2.x);
    result.y = fmaxf(v1.y, v2.y);
    result.z = fmaxf(v1.z, v2.z);
    return result;
}
pub fn Vector3Barycenter(arg_p: Vector3, arg_a: Vector3, arg_b: Vector3, arg_c: Vector3) callconv(.C) Vector3 {
    const p = arg_p;
    const a = arg_a;
    const b = arg_b;
    const c = arg_c;
    var result: Vector3 = Vector3{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
    };
    const v0: Vector3 = Vector3{
        .x = b.x - a.x,
        .y = b.y - a.y,
        .z = b.z - a.z,
    };
    const v1: Vector3 = Vector3{
        .x = c.x - a.x,
        .y = c.y - a.y,
        .z = c.z - a.z,
    };
    const v2: Vector3 = Vector3{
        .x = p.x - a.x,
        .y = p.y - a.y,
        .z = p.z - a.z,
    };
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
pub fn Vector3Unproject(arg_source: Vector3, arg_projection: Matrix, arg_view: Matrix) callconv(.C) Vector3 {
    const source = arg_source;
    const projection = arg_projection;
    const view = arg_view;
    var result: Vector3 = Vector3{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
    };
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
pub fn Vector3ToFloatV(arg_v: Vector3) callconv(.C) float3 {
    const v = arg_v;
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
pub fn Vector3Invert(arg_v: Vector3) callconv(.C) Vector3 {
    const v = arg_v;
    const result: Vector3 = Vector3{
        .x = 1.0 / v.x,
        .y = 1.0 / v.y,
        .z = 1.0 / v.z,
    };
    return result;
}
pub fn Vector3Clamp(arg_v: Vector3, arg_min: Vector3, arg_max: Vector3) callconv(.C) Vector3 {
    const v = arg_v;
    const min = arg_min;
    const max = arg_max;
    var result: Vector3 = Vector3{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
    };
    result.x = fminf(max.x, fmaxf(min.x, v.x));
    result.y = fminf(max.y, fmaxf(min.y, v.y));
    result.z = fminf(max.z, fmaxf(min.z, v.z));
    return result;
}
pub fn Vector3ClampValue(arg_v: Vector3, arg_min: f32, arg_max: f32) callconv(.C) Vector3 {
    const v = arg_v;
    const min = arg_min;
    const max = arg_max;
    var result: Vector3 = v;
    var length: f32 = ((v.x * v.x) + (v.y * v.y)) + (v.z * v.z);
    if (length > 0.0) {
        length = sqrtf(length);
        var scale: f32 = 1;
        if (length < min) {
            scale = min / length;
        } else if (length > max) {
            scale = max / length;
        }
        result.x = v.x * scale;
        result.y = v.y * scale;
        result.z = v.z * scale;
    }
    return result;
}
pub fn Vector3Equals(arg_p: Vector3, arg_q: Vector3) callconv(.C) c_int {
    const p = arg_p;
    const q = arg_q;
    const result: c_int = @intFromBool(((fabsf(p.x - q.x) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.x), fabsf(q.x))))) and (fabsf(p.y - q.y) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.y), fabsf(q.y)))))) and (fabsf(p.z - q.z) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.z), fabsf(q.z))))));
    return result;
}
pub fn Vector3Refract(arg_v: Vector3, arg_n: Vector3, arg_r: f32) callconv(.C) Vector3 {
    var v = arg_v;
    const n = arg_n;
    const r = arg_r;
    var result: Vector3 = Vector3{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
    };
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
pub fn Vector4Zero() callconv(.C) Vector4 {
    const result: Vector4 = Vector4{
        .x = 0.0,
        .y = 0.0,
        .z = 0.0,
        .w = 0.0,
    };
    return result;
}
pub fn Vector4One() callconv(.C) Vector4 {
    const result: Vector4 = Vector4{
        .x = 1.0,
        .y = 1.0,
        .z = 1.0,
        .w = 1.0,
    };
    return result;
}
pub fn Vector4Add(arg_v1: Vector4, arg_v2: Vector4) callconv(.C) Vector4 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: Vector4 = Vector4{
        .x = v1.x + v2.x,
        .y = v1.y + v2.y,
        .z = v1.z + v2.z,
        .w = v1.w + v2.w,
    };
    return result;
}
pub fn Vector4AddValue(arg_v: Vector4, arg_add: f32) callconv(.C) Vector4 {
    const v = arg_v;
    const add = arg_add;
    const result: Vector4 = Vector4{
        .x = v.x + add,
        .y = v.y + add,
        .z = v.z + add,
        .w = v.w + add,
    };
    return result;
}
pub fn Vector4Subtract(arg_v1: Vector4, arg_v2: Vector4) callconv(.C) Vector4 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: Vector4 = Vector4{
        .x = v1.x - v2.x,
        .y = v1.y - v2.y,
        .z = v1.z - v2.z,
        .w = v1.w - v2.w,
    };
    return result;
}
pub fn Vector4SubtractValue(arg_v: Vector4, arg_add: f32) callconv(.C) Vector4 {
    const v = arg_v;
    const add = arg_add;
    const result: Vector4 = Vector4{
        .x = v.x - add,
        .y = v.y - add,
        .z = v.z - add,
        .w = v.w - add,
    };
    return result;
}
pub fn Vector4Length(arg_v: Vector4) callconv(.C) f32 {
    const v = arg_v;
    const result: f32 = sqrtf((((v.x * v.x) + (v.y * v.y)) + (v.z * v.z)) + (v.w * v.w));
    return result;
}
pub fn Vector4LengthSqr(arg_v: Vector4) callconv(.C) f32 {
    const v = arg_v;
    const result: f32 = (((v.x * v.x) + (v.y * v.y)) + (v.z * v.z)) + (v.w * v.w);
    return result;
}
pub fn Vector4DotProduct(arg_v1: Vector4, arg_v2: Vector4) callconv(.C) f32 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: f32 = (((v1.x * v2.x) + (v1.y * v2.y)) + (v1.z * v2.z)) + (v1.w * v2.w);
    return result;
}
pub fn Vector4Distance(arg_v1: Vector4, arg_v2: Vector4) callconv(.C) f32 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: f32 = sqrtf(((((v1.x - v2.x) * (v1.x - v2.x)) + ((v1.y - v2.y) * (v1.y - v2.y))) + ((v1.z - v2.z) * (v1.z - v2.z))) + ((v1.w - v2.w) * (v1.w - v2.w)));
    return result;
}
pub fn Vector4DistanceSqr(arg_v1: Vector4, arg_v2: Vector4) callconv(.C) f32 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: f32 = ((((v1.x - v2.x) * (v1.x - v2.x)) + ((v1.y - v2.y) * (v1.y - v2.y))) + ((v1.z - v2.z) * (v1.z - v2.z))) + ((v1.w - v2.w) * (v1.w - v2.w));
    return result;
}
pub fn Vector4Scale(arg_v: Vector4, arg_scale: f32) callconv(.C) Vector4 {
    const v = arg_v;
    const scale = arg_scale;
    const result: Vector4 = Vector4{
        .x = v.x * scale,
        .y = v.y * scale,
        .z = v.z * scale,
        .w = v.w * scale,
    };
    return result;
}
pub fn Vector4Multiply(arg_v1: Vector4, arg_v2: Vector4) callconv(.C) Vector4 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: Vector4 = Vector4{
        .x = v1.x * v2.x,
        .y = v1.y * v2.y,
        .z = v1.z * v2.z,
        .w = v1.w * v2.w,
    };
    return result;
}
pub fn Vector4Negate(arg_v: Vector4) callconv(.C) Vector4 {
    const v = arg_v;
    const result: Vector4 = Vector4{
        .x = -v.x,
        .y = -v.y,
        .z = -v.z,
        .w = -v.w,
    };
    return result;
}
pub fn Vector4Divide(arg_v1: Vector4, arg_v2: Vector4) callconv(.C) Vector4 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const result: Vector4 = Vector4{
        .x = v1.x / v2.x,
        .y = v1.y / v2.y,
        .z = v1.z / v2.z,
        .w = v1.w / v2.w,
    };
    return result;
}
pub fn Vector4Normalize(arg_v: Vector4) callconv(.C) Vector4 {
    const v = arg_v;
    var result: Vector4 = Vector4{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
        .w = 0,
    };
    const length: f32 = sqrtf((((v.x * v.x) + (v.y * v.y)) + (v.z * v.z)) + (v.w * v.w));
    if (length > @as(f32, @floatFromInt(@as(c_int, 0)))) {
        const ilength: f32 = 1.0 / length;
        result.x = v.x * ilength;
        result.y = v.y * ilength;
        result.z = v.z * ilength;
        result.w = v.w * ilength;
    }
    return result;
}
pub fn Vector4Min(arg_v1: Vector4, arg_v2: Vector4) callconv(.C) Vector4 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    var result: Vector4 = Vector4{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
        .w = 0,
    };
    result.x = fminf(v1.x, v2.x);
    result.y = fminf(v1.y, v2.y);
    result.z = fminf(v1.z, v2.z);
    result.w = fminf(v1.w, v2.w);
    return result;
}
pub fn Vector4Max(arg_v1: Vector4, arg_v2: Vector4) callconv(.C) Vector4 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    var result: Vector4 = Vector4{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
        .w = 0,
    };
    result.x = fmaxf(v1.x, v2.x);
    result.y = fmaxf(v1.y, v2.y);
    result.z = fmaxf(v1.z, v2.z);
    result.w = fmaxf(v1.w, v2.w);
    return result;
}
pub fn Vector4Lerp(arg_v1: Vector4, arg_v2: Vector4, arg_amount: f32) callconv(.C) Vector4 {
    const v1 = arg_v1;
    const v2 = arg_v2;
    const amount = arg_amount;
    var result: Vector4 = Vector4{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
        .w = 0,
    };
    result.x = v1.x + (amount * (v2.x - v1.x));
    result.y = v1.y + (amount * (v2.y - v1.y));
    result.z = v1.z + (amount * (v2.z - v1.z));
    result.w = v1.w + (amount * (v2.w - v1.w));
    return result;
}
pub fn Vector4MoveTowards(arg_v: Vector4, arg_target: Vector4, arg_maxDistance: f32) callconv(.C) Vector4 {
    const v = arg_v;
    const target = arg_target;
    const maxDistance = arg_maxDistance;
    var result: Vector4 = Vector4{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
        .w = 0,
    };
    const dx: f32 = target.x - v.x;
    const dy: f32 = target.y - v.y;
    const dz: f32 = target.z - v.z;
    const dw: f32 = target.w - v.w;
    const value: f32 = (((dx * dx) + (dy * dy)) + (dz * dz)) + (dw * dw);
    if ((value == @as(f32, @floatFromInt(@as(c_int, 0)))) or ((maxDistance >= @as(f32, @floatFromInt(@as(c_int, 0)))) and (value <= (maxDistance * maxDistance)))) return target;
    const dist: f32 = sqrtf(value);
    result.x = v.x + ((dx / dist) * maxDistance);
    result.y = v.y + ((dy / dist) * maxDistance);
    result.z = v.z + ((dz / dist) * maxDistance);
    result.w = v.w + ((dw / dist) * maxDistance);
    return result;
}
pub fn Vector4Invert(arg_v: Vector4) callconv(.C) Vector4 {
    const v = arg_v;
    const result: Vector4 = Vector4{
        .x = 1.0 / v.x,
        .y = 1.0 / v.y,
        .z = 1.0 / v.z,
        .w = 1.0 / v.w,
    };
    return result;
}
pub fn Vector4Equals(arg_p: Vector4, arg_q: Vector4) callconv(.C) c_int {
    const p = arg_p;
    const q = arg_q;
    const result: c_int = @intFromBool((((fabsf(p.x - q.x) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.x), fabsf(q.x))))) and (fabsf(p.y - q.y) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.y), fabsf(q.y)))))) and (fabsf(p.z - q.z) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.z), fabsf(q.z)))))) and (fabsf(p.w - q.w) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.w), fabsf(q.w))))));
    return result;
}
pub fn MatrixDeterminant(arg_mat: Matrix) callconv(.C) f32 {
    const mat = arg_mat;
    var result: f32 = 0.0;
    const a00: f32 = mat.m0;
    const a01: f32 = mat.m1;
    const a02: f32 = mat.m2;
    const a03: f32 = mat.m3;
    const a10: f32 = mat.m4;
    const a11: f32 = mat.m5;
    const a12: f32 = mat.m6;
    const a13: f32 = mat.m7;
    const a20: f32 = mat.m8;
    const a21: f32 = mat.m9;
    const a22: f32 = mat.m10;
    const a23: f32 = mat.m11;
    const a30: f32 = mat.m12;
    const a31: f32 = mat.m13;
    const a32: f32 = mat.m14;
    const a33: f32 = mat.m15;
    result = (((((((((((((((((((((((((a30 * a21) * a12) * a03) - (((a20 * a31) * a12) * a03)) - (((a30 * a11) * a22) * a03)) + (((a10 * a31) * a22) * a03)) + (((a20 * a11) * a32) * a03)) - (((a10 * a21) * a32) * a03)) - (((a30 * a21) * a02) * a13)) + (((a20 * a31) * a02) * a13)) + (((a30 * a01) * a22) * a13)) - (((a00 * a31) * a22) * a13)) - (((a20 * a01) * a32) * a13)) + (((a00 * a21) * a32) * a13)) + (((a30 * a11) * a02) * a23)) - (((a10 * a31) * a02) * a23)) - (((a30 * a01) * a12) * a23)) + (((a00 * a31) * a12) * a23)) + (((a10 * a01) * a32) * a23)) - (((a00 * a11) * a32) * a23)) - (((a20 * a11) * a02) * a33)) + (((a10 * a21) * a02) * a33)) + (((a20 * a01) * a12) * a33)) - (((a00 * a21) * a12) * a33)) - (((a10 * a01) * a22) * a33)) + (((a00 * a11) * a22) * a33);
    return result;
}
pub fn MatrixTrace(arg_mat: Matrix) callconv(.C) f32 {
    const mat = arg_mat;
    const result: f32 = ((mat.m0 + mat.m5) + mat.m10) + mat.m15;
    return result;
}
pub fn MatrixTranspose(arg_mat: Matrix) callconv(.C) Matrix {
    const mat = arg_mat;
    var result: Matrix = Matrix{
        .m0 = @as(f32, @floatFromInt(@as(c_int, 0))),
        .m4 = 0,
        .m8 = 0,
        .m12 = 0,
        .m1 = 0,
        .m5 = 0,
        .m9 = 0,
        .m13 = 0,
        .m2 = 0,
        .m6 = 0,
        .m10 = 0,
        .m14 = 0,
        .m3 = 0,
        .m7 = 0,
        .m11 = 0,
        .m15 = 0,
    };
    result.m0 = mat.m0;
    result.m1 = mat.m4;
    result.m2 = mat.m8;
    result.m3 = mat.m12;
    result.m4 = mat.m1;
    result.m5 = mat.m5;
    result.m6 = mat.m9;
    result.m7 = mat.m13;
    result.m8 = mat.m2;
    result.m9 = mat.m6;
    result.m10 = mat.m10;
    result.m11 = mat.m14;
    result.m12 = mat.m3;
    result.m13 = mat.m7;
    result.m14 = mat.m11;
    result.m15 = mat.m15;
    return result;
}
pub fn MatrixInvert(arg_mat: Matrix) callconv(.C) Matrix {
    const mat = arg_mat;
    var result: Matrix = Matrix{
        .m0 = @as(f32, @floatFromInt(@as(c_int, 0))),
        .m4 = 0,
        .m8 = 0,
        .m12 = 0,
        .m1 = 0,
        .m5 = 0,
        .m9 = 0,
        .m13 = 0,
        .m2 = 0,
        .m6 = 0,
        .m10 = 0,
        .m14 = 0,
        .m3 = 0,
        .m7 = 0,
        .m11 = 0,
        .m15 = 0,
    };
    const a00: f32 = mat.m0;
    const a01: f32 = mat.m1;
    const a02: f32 = mat.m2;
    const a03: f32 = mat.m3;
    const a10: f32 = mat.m4;
    const a11: f32 = mat.m5;
    const a12: f32 = mat.m6;
    const a13: f32 = mat.m7;
    const a20: f32 = mat.m8;
    const a21: f32 = mat.m9;
    const a22: f32 = mat.m10;
    const a23: f32 = mat.m11;
    const a30: f32 = mat.m12;
    const a31: f32 = mat.m13;
    const a32: f32 = mat.m14;
    const a33: f32 = mat.m15;
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
    result.m0 = (((a11 * b11) - (a12 * b10)) + (a13 * b09)) * invDet;
    result.m1 = (((-a01 * b11) + (a02 * b10)) - (a03 * b09)) * invDet;
    result.m2 = (((a31 * b05) - (a32 * b04)) + (a33 * b03)) * invDet;
    result.m3 = (((-a21 * b05) + (a22 * b04)) - (a23 * b03)) * invDet;
    result.m4 = (((-a10 * b11) + (a12 * b08)) - (a13 * b07)) * invDet;
    result.m5 = (((a00 * b11) - (a02 * b08)) + (a03 * b07)) * invDet;
    result.m6 = (((-a30 * b05) + (a32 * b02)) - (a33 * b01)) * invDet;
    result.m7 = (((a20 * b05) - (a22 * b02)) + (a23 * b01)) * invDet;
    result.m8 = (((a10 * b10) - (a11 * b08)) + (a13 * b06)) * invDet;
    result.m9 = (((-a00 * b10) + (a01 * b08)) - (a03 * b06)) * invDet;
    result.m10 = (((a30 * b04) - (a31 * b02)) + (a33 * b00)) * invDet;
    result.m11 = (((-a20 * b04) + (a21 * b02)) - (a23 * b00)) * invDet;
    result.m12 = (((-a10 * b09) + (a11 * b07)) - (a12 * b06)) * invDet;
    result.m13 = (((a00 * b09) - (a01 * b07)) + (a02 * b06)) * invDet;
    result.m14 = (((-a30 * b03) + (a31 * b01)) - (a32 * b00)) * invDet;
    result.m15 = (((a20 * b03) - (a21 * b01)) + (a22 * b00)) * invDet;
    return result;
}
pub fn MatrixIdentity() callconv(.C) Matrix {
    const result: Matrix = Matrix{
        .m0 = 1.0,
        .m4 = 0.0,
        .m8 = 0.0,
        .m12 = 0.0,
        .m1 = 0.0,
        .m5 = 1.0,
        .m9 = 0.0,
        .m13 = 0.0,
        .m2 = 0.0,
        .m6 = 0.0,
        .m10 = 1.0,
        .m14 = 0.0,
        .m3 = 0.0,
        .m7 = 0.0,
        .m11 = 0.0,
        .m15 = 1.0,
    };
    return result;
}
pub fn MatrixAdd(arg_left: Matrix, arg_right: Matrix) callconv(.C) Matrix {
    const left = arg_left;
    const right = arg_right;
    var result: Matrix = Matrix{
        .m0 = @as(f32, @floatFromInt(@as(c_int, 0))),
        .m4 = 0,
        .m8 = 0,
        .m12 = 0,
        .m1 = 0,
        .m5 = 0,
        .m9 = 0,
        .m13 = 0,
        .m2 = 0,
        .m6 = 0,
        .m10 = 0,
        .m14 = 0,
        .m3 = 0,
        .m7 = 0,
        .m11 = 0,
        .m15 = 0,
    };
    result.m0 = left.m0 + right.m0;
    result.m1 = left.m1 + right.m1;
    result.m2 = left.m2 + right.m2;
    result.m3 = left.m3 + right.m3;
    result.m4 = left.m4 + right.m4;
    result.m5 = left.m5 + right.m5;
    result.m6 = left.m6 + right.m6;
    result.m7 = left.m7 + right.m7;
    result.m8 = left.m8 + right.m8;
    result.m9 = left.m9 + right.m9;
    result.m10 = left.m10 + right.m10;
    result.m11 = left.m11 + right.m11;
    result.m12 = left.m12 + right.m12;
    result.m13 = left.m13 + right.m13;
    result.m14 = left.m14 + right.m14;
    result.m15 = left.m15 + right.m15;
    return result;
}
pub fn MatrixSubtract(arg_left: Matrix, arg_right: Matrix) callconv(.C) Matrix {
    const left = arg_left;
    const right = arg_right;
    var result: Matrix = Matrix{
        .m0 = @as(f32, @floatFromInt(@as(c_int, 0))),
        .m4 = 0,
        .m8 = 0,
        .m12 = 0,
        .m1 = 0,
        .m5 = 0,
        .m9 = 0,
        .m13 = 0,
        .m2 = 0,
        .m6 = 0,
        .m10 = 0,
        .m14 = 0,
        .m3 = 0,
        .m7 = 0,
        .m11 = 0,
        .m15 = 0,
    };
    result.m0 = left.m0 - right.m0;
    result.m1 = left.m1 - right.m1;
    result.m2 = left.m2 - right.m2;
    result.m3 = left.m3 - right.m3;
    result.m4 = left.m4 - right.m4;
    result.m5 = left.m5 - right.m5;
    result.m6 = left.m6 - right.m6;
    result.m7 = left.m7 - right.m7;
    result.m8 = left.m8 - right.m8;
    result.m9 = left.m9 - right.m9;
    result.m10 = left.m10 - right.m10;
    result.m11 = left.m11 - right.m11;
    result.m12 = left.m12 - right.m12;
    result.m13 = left.m13 - right.m13;
    result.m14 = left.m14 - right.m14;
    result.m15 = left.m15 - right.m15;
    return result;
}
pub fn MatrixMultiply(arg_left: Matrix, arg_right: Matrix) callconv(.C) Matrix {
    const left = arg_left;
    const right = arg_right;
    var result: Matrix = Matrix{
        .m0 = @as(f32, @floatFromInt(@as(c_int, 0))),
        .m4 = 0,
        .m8 = 0,
        .m12 = 0,
        .m1 = 0,
        .m5 = 0,
        .m9 = 0,
        .m13 = 0,
        .m2 = 0,
        .m6 = 0,
        .m10 = 0,
        .m14 = 0,
        .m3 = 0,
        .m7 = 0,
        .m11 = 0,
        .m15 = 0,
    };
    result.m0 = (((left.m0 * right.m0) + (left.m1 * right.m4)) + (left.m2 * right.m8)) + (left.m3 * right.m12);
    result.m1 = (((left.m0 * right.m1) + (left.m1 * right.m5)) + (left.m2 * right.m9)) + (left.m3 * right.m13);
    result.m2 = (((left.m0 * right.m2) + (left.m1 * right.m6)) + (left.m2 * right.m10)) + (left.m3 * right.m14);
    result.m3 = (((left.m0 * right.m3) + (left.m1 * right.m7)) + (left.m2 * right.m11)) + (left.m3 * right.m15);
    result.m4 = (((left.m4 * right.m0) + (left.m5 * right.m4)) + (left.m6 * right.m8)) + (left.m7 * right.m12);
    result.m5 = (((left.m4 * right.m1) + (left.m5 * right.m5)) + (left.m6 * right.m9)) + (left.m7 * right.m13);
    result.m6 = (((left.m4 * right.m2) + (left.m5 * right.m6)) + (left.m6 * right.m10)) + (left.m7 * right.m14);
    result.m7 = (((left.m4 * right.m3) + (left.m5 * right.m7)) + (left.m6 * right.m11)) + (left.m7 * right.m15);
    result.m8 = (((left.m8 * right.m0) + (left.m9 * right.m4)) + (left.m10 * right.m8)) + (left.m11 * right.m12);
    result.m9 = (((left.m8 * right.m1) + (left.m9 * right.m5)) + (left.m10 * right.m9)) + (left.m11 * right.m13);
    result.m10 = (((left.m8 * right.m2) + (left.m9 * right.m6)) + (left.m10 * right.m10)) + (left.m11 * right.m14);
    result.m11 = (((left.m8 * right.m3) + (left.m9 * right.m7)) + (left.m10 * right.m11)) + (left.m11 * right.m15);
    result.m12 = (((left.m12 * right.m0) + (left.m13 * right.m4)) + (left.m14 * right.m8)) + (left.m15 * right.m12);
    result.m13 = (((left.m12 * right.m1) + (left.m13 * right.m5)) + (left.m14 * right.m9)) + (left.m15 * right.m13);
    result.m14 = (((left.m12 * right.m2) + (left.m13 * right.m6)) + (left.m14 * right.m10)) + (left.m15 * right.m14);
    result.m15 = (((left.m12 * right.m3) + (left.m13 * right.m7)) + (left.m14 * right.m11)) + (left.m15 * right.m15);
    return result;
}
pub fn MatrixTranslate(arg_x: f32, arg_y: f32, arg_z: f32) callconv(.C) Matrix {
    const x = arg_x;
    const y = arg_y;
    const z = arg_z;
    const result: Matrix = Matrix{
        .m0 = 1.0,
        .m4 = 0.0,
        .m8 = 0.0,
        .m12 = x,
        .m1 = 0.0,
        .m5 = 1.0,
        .m9 = 0.0,
        .m13 = y,
        .m2 = 0.0,
        .m6 = 0.0,
        .m10 = 1.0,
        .m14 = z,
        .m3 = 0.0,
        .m7 = 0.0,
        .m11 = 0.0,
        .m15 = 1.0,
    };
    return result;
}
pub fn MatrixRotate(arg_axis: Vector3, arg_angle: f32) callconv(.C) Matrix {
    const axis = arg_axis;
    const angle = arg_angle;
    var result: Matrix = Matrix{
        .m0 = @as(f32, @floatFromInt(@as(c_int, 0))),
        .m4 = 0,
        .m8 = 0,
        .m12 = 0,
        .m1 = 0,
        .m5 = 0,
        .m9 = 0,
        .m13 = 0,
        .m2 = 0,
        .m6 = 0,
        .m10 = 0,
        .m14 = 0,
        .m3 = 0,
        .m7 = 0,
        .m11 = 0,
        .m15 = 0,
    };
    var x: f32 = axis.x;
    var y: f32 = axis.y;
    var z: f32 = axis.z;
    const lengthSquared: f32 = ((x * x) + (y * y)) + (z * z);
    if ((lengthSquared != 1.0) and (lengthSquared != 0.0)) {
        const ilength: f32 = 1.0 / sqrtf(lengthSquared);
        x *= ilength;
        y *= ilength;
        z *= ilength;
    }
    const sinres: f32 = sinf(angle);
    const cosres: f32 = cosf(angle);
    const t: f32 = 1.0 - cosres;
    result.m0 = ((x * x) * t) + cosres;
    result.m1 = ((y * x) * t) + (z * sinres);
    result.m2 = ((z * x) * t) - (y * sinres);
    result.m3 = 0.0;
    result.m4 = ((x * y) * t) - (z * sinres);
    result.m5 = ((y * y) * t) + cosres;
    result.m6 = ((z * y) * t) + (x * sinres);
    result.m7 = 0.0;
    result.m8 = ((x * z) * t) + (y * sinres);
    result.m9 = ((y * z) * t) - (x * sinres);
    result.m10 = ((z * z) * t) + cosres;
    result.m11 = 0.0;
    result.m12 = 0.0;
    result.m13 = 0.0;
    result.m14 = 0.0;
    result.m15 = 1.0;
    return result;
}
pub fn MatrixRotateX(arg_angle: f32) callconv(.C) Matrix {
    const angle = arg_angle;
    var result: Matrix = Matrix{
        .m0 = 1.0,
        .m4 = 0.0,
        .m8 = 0.0,
        .m12 = 0.0,
        .m1 = 0.0,
        .m5 = 1.0,
        .m9 = 0.0,
        .m13 = 0.0,
        .m2 = 0.0,
        .m6 = 0.0,
        .m10 = 1.0,
        .m14 = 0.0,
        .m3 = 0.0,
        .m7 = 0.0,
        .m11 = 0.0,
        .m15 = 1.0,
    };
    const cosres: f32 = cosf(angle);
    const sinres: f32 = sinf(angle);
    result.m5 = cosres;
    result.m6 = sinres;
    result.m9 = -sinres;
    result.m10 = cosres;
    return result;
}
pub fn MatrixRotateY(arg_angle: f32) callconv(.C) Matrix {
    const angle = arg_angle;
    var result: Matrix = Matrix{
        .m0 = 1.0,
        .m4 = 0.0,
        .m8 = 0.0,
        .m12 = 0.0,
        .m1 = 0.0,
        .m5 = 1.0,
        .m9 = 0.0,
        .m13 = 0.0,
        .m2 = 0.0,
        .m6 = 0.0,
        .m10 = 1.0,
        .m14 = 0.0,
        .m3 = 0.0,
        .m7 = 0.0,
        .m11 = 0.0,
        .m15 = 1.0,
    };
    const cosres: f32 = cosf(angle);
    const sinres: f32 = sinf(angle);
    result.m0 = cosres;
    result.m2 = -sinres;
    result.m8 = sinres;
    result.m10 = cosres;
    return result;
}
pub fn MatrixRotateZ(arg_angle: f32) callconv(.C) Matrix {
    const angle = arg_angle;
    var result: Matrix = Matrix{
        .m0 = 1.0,
        .m4 = 0.0,
        .m8 = 0.0,
        .m12 = 0.0,
        .m1 = 0.0,
        .m5 = 1.0,
        .m9 = 0.0,
        .m13 = 0.0,
        .m2 = 0.0,
        .m6 = 0.0,
        .m10 = 1.0,
        .m14 = 0.0,
        .m3 = 0.0,
        .m7 = 0.0,
        .m11 = 0.0,
        .m15 = 1.0,
    };
    const cosres: f32 = cosf(angle);
    const sinres: f32 = sinf(angle);
    result.m0 = cosres;
    result.m1 = sinres;
    result.m4 = -sinres;
    result.m5 = cosres;
    return result;
}
pub fn MatrixRotateXYZ(arg_angle: Vector3) callconv(.C) Matrix {
    const angle = arg_angle;
    var result: Matrix = Matrix{
        .m0 = 1.0,
        .m4 = 0.0,
        .m8 = 0.0,
        .m12 = 0.0,
        .m1 = 0.0,
        .m5 = 1.0,
        .m9 = 0.0,
        .m13 = 0.0,
        .m2 = 0.0,
        .m6 = 0.0,
        .m10 = 1.0,
        .m14 = 0.0,
        .m3 = 0.0,
        .m7 = 0.0,
        .m11 = 0.0,
        .m15 = 1.0,
    };
    const cosz: f32 = cosf(-angle.z);
    const sinz: f32 = sinf(-angle.z);
    const cosy: f32 = cosf(-angle.y);
    const siny: f32 = sinf(-angle.y);
    const cosx: f32 = cosf(-angle.x);
    const sinx: f32 = sinf(-angle.x);
    result.m0 = cosz * cosy;
    result.m1 = ((cosz * siny) * sinx) - (sinz * cosx);
    result.m2 = ((cosz * siny) * cosx) + (sinz * sinx);
    result.m4 = sinz * cosy;
    result.m5 = ((sinz * siny) * sinx) + (cosz * cosx);
    result.m6 = ((sinz * siny) * cosx) - (cosz * sinx);
    result.m8 = -siny;
    result.m9 = cosy * sinx;
    result.m10 = cosy * cosx;
    return result;
}
pub fn MatrixRotateZYX(arg_angle: Vector3) callconv(.C) Matrix {
    const angle = arg_angle;
    var result: Matrix = Matrix{
        .m0 = @as(f32, @floatFromInt(@as(c_int, 0))),
        .m4 = 0,
        .m8 = 0,
        .m12 = 0,
        .m1 = 0,
        .m5 = 0,
        .m9 = 0,
        .m13 = 0,
        .m2 = 0,
        .m6 = 0,
        .m10 = 0,
        .m14 = 0,
        .m3 = 0,
        .m7 = 0,
        .m11 = 0,
        .m15 = 0,
    };
    const cz: f32 = cosf(angle.z);
    const sz: f32 = sinf(angle.z);
    const cy: f32 = cosf(angle.y);
    const sy: f32 = sinf(angle.y);
    const cx: f32 = cosf(angle.x);
    const sx: f32 = sinf(angle.x);
    result.m0 = cz * cy;
    result.m4 = ((cz * sy) * sx) - (cx * sz);
    result.m8 = (sz * sx) + ((cz * cx) * sy);
    result.m12 = 0;
    result.m1 = cy * sz;
    result.m5 = (cz * cx) + ((sz * sy) * sx);
    result.m9 = ((cx * sz) * sy) - (cz * sx);
    result.m13 = 0;
    result.m2 = -sy;
    result.m6 = cy * sx;
    result.m10 = cy * cx;
    result.m14 = 0;
    result.m3 = 0;
    result.m7 = 0;
    result.m11 = 0;
    result.m15 = 1;
    return result;
}
pub fn MatrixScale(arg_x: f32, arg_y: f32, arg_z: f32) callconv(.C) Matrix {
    const x = arg_x;
    const y = arg_y;
    const z = arg_z;
    const result: Matrix = Matrix{
        .m0 = x,
        .m4 = 0.0,
        .m8 = 0.0,
        .m12 = 0.0,
        .m1 = 0.0,
        .m5 = y,
        .m9 = 0.0,
        .m13 = 0.0,
        .m2 = 0.0,
        .m6 = 0.0,
        .m10 = z,
        .m14 = 0.0,
        .m3 = 0.0,
        .m7 = 0.0,
        .m11 = 0.0,
        .m15 = 1.0,
    };
    return result;
}
pub fn MatrixFrustum(arg_left: f64, arg_right: f64, arg_bottom: f64, arg_top: f64, arg_nearPlane: f64, arg_farPlane: f64) callconv(.C) Matrix {
    const left = arg_left;
    const right = arg_right;
    const bottom = arg_bottom;
    const top = arg_top;
    const nearPlane = arg_nearPlane;
    const farPlane = arg_farPlane;
    var result: Matrix = Matrix{
        .m0 = @as(f32, @floatFromInt(@as(c_int, 0))),
        .m4 = 0,
        .m8 = 0,
        .m12 = 0,
        .m1 = 0,
        .m5 = 0,
        .m9 = 0,
        .m13 = 0,
        .m2 = 0,
        .m6 = 0,
        .m10 = 0,
        .m14 = 0,
        .m3 = 0,
        .m7 = 0,
        .m11 = 0,
        .m15 = 0,
    };
    const rl: f32 = @as(f32, @floatCast(right - left));
    const tb: f32 = @as(f32, @floatCast(top - bottom));
    const @"fn": f32 = @as(f32, @floatCast(farPlane - nearPlane));
    result.m0 = (@as(f32, @floatCast(nearPlane)) * 2.0) / rl;
    result.m1 = 0.0;
    result.m2 = 0.0;
    result.m3 = 0.0;
    result.m4 = 0.0;
    result.m5 = (@as(f32, @floatCast(nearPlane)) * 2.0) / tb;
    result.m6 = 0.0;
    result.m7 = 0.0;
    result.m8 = (@as(f32, @floatCast(right)) + @as(f32, @floatCast(left))) / rl;
    result.m9 = (@as(f32, @floatCast(top)) + @as(f32, @floatCast(bottom))) / tb;
    result.m10 = -(@as(f32, @floatCast(farPlane)) + @as(f32, @floatCast(nearPlane))) / @"fn";
    result.m11 = -1.0;
    result.m12 = 0.0;
    result.m13 = 0.0;
    result.m14 = -((@as(f32, @floatCast(farPlane)) * @as(f32, @floatCast(nearPlane))) * 2.0) / @"fn";
    result.m15 = 0.0;
    return result;
}
pub fn MatrixPerspective(arg_fovY: f64, arg_aspect: f64, arg_nearPlane: f64, arg_farPlane: f64) callconv(.C) Matrix {
    const fovY = arg_fovY;
    const aspect = arg_aspect;
    const nearPlane = arg_nearPlane;
    const farPlane = arg_farPlane;
    var result: Matrix = Matrix{
        .m0 = @as(f32, @floatFromInt(@as(c_int, 0))),
        .m4 = 0,
        .m8 = 0,
        .m12 = 0,
        .m1 = 0,
        .m5 = 0,
        .m9 = 0,
        .m13 = 0,
        .m2 = 0,
        .m6 = 0,
        .m10 = 0,
        .m14 = 0,
        .m3 = 0,
        .m7 = 0,
        .m11 = 0,
        .m15 = 0,
    };
    const top: f64 = nearPlane * tan(fovY * 0.5);
    const bottom: f64 = -top;
    const right: f64 = top * aspect;
    const left: f64 = -right;
    const rl: f32 = @as(f32, @floatCast(right - left));
    const tb: f32 = @as(f32, @floatCast(top - bottom));
    const @"fn": f32 = @as(f32, @floatCast(farPlane - nearPlane));
    result.m0 = (@as(f32, @floatCast(nearPlane)) * 2.0) / rl;
    result.m5 = (@as(f32, @floatCast(nearPlane)) * 2.0) / tb;
    result.m8 = (@as(f32, @floatCast(right)) + @as(f32, @floatCast(left))) / rl;
    result.m9 = (@as(f32, @floatCast(top)) + @as(f32, @floatCast(bottom))) / tb;
    result.m10 = -(@as(f32, @floatCast(farPlane)) + @as(f32, @floatCast(nearPlane))) / @"fn";
    result.m11 = -1.0;
    result.m14 = -((@as(f32, @floatCast(farPlane)) * @as(f32, @floatCast(nearPlane))) * 2.0) / @"fn";
    return result;
}
pub fn MatrixOrtho(arg_left: f64, arg_right: f64, arg_bottom: f64, arg_top: f64, arg_nearPlane: f64, arg_farPlane: f64) callconv(.C) Matrix {
    const left = arg_left;
    const right = arg_right;
    const bottom = arg_bottom;
    const top = arg_top;
    const nearPlane = arg_nearPlane;
    const farPlane = arg_farPlane;
    var result: Matrix = Matrix{
        .m0 = @as(f32, @floatFromInt(@as(c_int, 0))),
        .m4 = 0,
        .m8 = 0,
        .m12 = 0,
        .m1 = 0,
        .m5 = 0,
        .m9 = 0,
        .m13 = 0,
        .m2 = 0,
        .m6 = 0,
        .m10 = 0,
        .m14 = 0,
        .m3 = 0,
        .m7 = 0,
        .m11 = 0,
        .m15 = 0,
    };
    const rl: f32 = @as(f32, @floatCast(right - left));
    const tb: f32 = @as(f32, @floatCast(top - bottom));
    const @"fn": f32 = @as(f32, @floatCast(farPlane - nearPlane));
    result.m0 = 2.0 / rl;
    result.m1 = 0.0;
    result.m2 = 0.0;
    result.m3 = 0.0;
    result.m4 = 0.0;
    result.m5 = 2.0 / tb;
    result.m6 = 0.0;
    result.m7 = 0.0;
    result.m8 = 0.0;
    result.m9 = 0.0;
    result.m10 = -2.0 / @"fn";
    result.m11 = 0.0;
    result.m12 = -(@as(f32, @floatCast(left)) + @as(f32, @floatCast(right))) / rl;
    result.m13 = -(@as(f32, @floatCast(top)) + @as(f32, @floatCast(bottom))) / tb;
    result.m14 = -(@as(f32, @floatCast(farPlane)) + @as(f32, @floatCast(nearPlane))) / @"fn";
    result.m15 = 1.0;
    return result;
}
pub fn MatrixLookAt(arg_eye: Vector3, arg_target: Vector3, arg_up: Vector3) callconv(.C) Matrix {
    const eye = arg_eye;
    const target = arg_target;
    const up = arg_up;
    var result: Matrix = Matrix{
        .m0 = @as(f32, @floatFromInt(@as(c_int, 0))),
        .m4 = 0,
        .m8 = 0,
        .m12 = 0,
        .m1 = 0,
        .m5 = 0,
        .m9 = 0,
        .m13 = 0,
        .m2 = 0,
        .m6 = 0,
        .m10 = 0,
        .m14 = 0,
        .m3 = 0,
        .m7 = 0,
        .m11 = 0,
        .m15 = 0,
    };
    var length: f32 = 0.0;
    var ilength: f32 = 0.0;
    var vz: Vector3 = Vector3{
        .x = eye.x - target.x,
        .y = eye.y - target.y,
        .z = eye.z - target.z,
    };
    var v: Vector3 = vz;
    length = sqrtf(((v.x * v.x) + (v.y * v.y)) + (v.z * v.z));
    if (length == 0.0) {
        length = 1.0;
    }
    ilength = 1.0 / length;
    vz.x *= ilength;
    vz.y *= ilength;
    vz.z *= ilength;
    var vx: Vector3 = Vector3{
        .x = (up.y * vz.z) - (up.z * vz.y),
        .y = (up.z * vz.x) - (up.x * vz.z),
        .z = (up.x * vz.y) - (up.y * vz.x),
    };
    v = vx;
    length = sqrtf(((v.x * v.x) + (v.y * v.y)) + (v.z * v.z));
    if (length == 0.0) {
        length = 1.0;
    }
    ilength = 1.0 / length;
    vx.x *= ilength;
    vx.y *= ilength;
    vx.z *= ilength;
    const vy: Vector3 = Vector3{
        .x = (vz.y * vx.z) - (vz.z * vx.y),
        .y = (vz.z * vx.x) - (vz.x * vx.z),
        .z = (vz.x * vx.y) - (vz.y * vx.x),
    };
    result.m0 = vx.x;
    result.m1 = vy.x;
    result.m2 = vz.x;
    result.m3 = 0.0;
    result.m4 = vx.y;
    result.m5 = vy.y;
    result.m6 = vz.y;
    result.m7 = 0.0;
    result.m8 = vx.z;
    result.m9 = vy.z;
    result.m10 = vz.z;
    result.m11 = 0.0;
    result.m12 = -(((vx.x * eye.x) + (vx.y * eye.y)) + (vx.z * eye.z));
    result.m13 = -(((vy.x * eye.x) + (vy.y * eye.y)) + (vy.z * eye.z));
    result.m14 = -(((vz.x * eye.x) + (vz.y * eye.y)) + (vz.z * eye.z));
    result.m15 = 1.0;
    return result;
}
pub fn MatrixToFloatV(arg_mat: Matrix) callconv(.C) float16 {
    const mat = arg_mat;
    var result: float16 = float16{
        .v = [1]f32{
            0,
        } ++ [1]f32{0} ** 15,
    };
    result.v[@as(c_uint, @intCast(@as(c_int, 0)))] = mat.m0;
    result.v[@as(c_uint, @intCast(@as(c_int, 1)))] = mat.m1;
    result.v[@as(c_uint, @intCast(@as(c_int, 2)))] = mat.m2;
    result.v[@as(c_uint, @intCast(@as(c_int, 3)))] = mat.m3;
    result.v[@as(c_uint, @intCast(@as(c_int, 4)))] = mat.m4;
    result.v[@as(c_uint, @intCast(@as(c_int, 5)))] = mat.m5;
    result.v[@as(c_uint, @intCast(@as(c_int, 6)))] = mat.m6;
    result.v[@as(c_uint, @intCast(@as(c_int, 7)))] = mat.m7;
    result.v[@as(c_uint, @intCast(@as(c_int, 8)))] = mat.m8;
    result.v[@as(c_uint, @intCast(@as(c_int, 9)))] = mat.m9;
    result.v[@as(c_uint, @intCast(@as(c_int, 10)))] = mat.m10;
    result.v[@as(c_uint, @intCast(@as(c_int, 11)))] = mat.m11;
    result.v[@as(c_uint, @intCast(@as(c_int, 12)))] = mat.m12;
    result.v[@as(c_uint, @intCast(@as(c_int, 13)))] = mat.m13;
    result.v[@as(c_uint, @intCast(@as(c_int, 14)))] = mat.m14;
    result.v[@as(c_uint, @intCast(@as(c_int, 15)))] = mat.m15;
    return result;
}
pub fn QuaternionAdd(arg_q1: Quaternion, arg_q2: Quaternion) callconv(.C) Quaternion {
    const q1 = arg_q1;
    const q2 = arg_q2;
    const result: Quaternion = Quaternion{
        .x = q1.x + q2.x,
        .y = q1.y + q2.y,
        .z = q1.z + q2.z,
        .w = q1.w + q2.w,
    };
    return result;
}
pub fn QuaternionAddValue(arg_q: Quaternion, arg_add: f32) callconv(.C) Quaternion {
    const q = arg_q;
    const add = arg_add;
    const result: Quaternion = Quaternion{
        .x = q.x + add,
        .y = q.y + add,
        .z = q.z + add,
        .w = q.w + add,
    };
    return result;
}
pub fn QuaternionSubtract(arg_q1: Quaternion, arg_q2: Quaternion) callconv(.C) Quaternion {
    const q1 = arg_q1;
    const q2 = arg_q2;
    const result: Quaternion = Quaternion{
        .x = q1.x - q2.x,
        .y = q1.y - q2.y,
        .z = q1.z - q2.z,
        .w = q1.w - q2.w,
    };
    return result;
}
pub fn QuaternionSubtractValue(arg_q: Quaternion, arg_sub: f32) callconv(.C) Quaternion {
    const q = arg_q;
    const sub = arg_sub;
    const result: Quaternion = Quaternion{
        .x = q.x - sub,
        .y = q.y - sub,
        .z = q.z - sub,
        .w = q.w - sub,
    };
    return result;
}
pub fn QuaternionIdentity() callconv(.C) Quaternion {
    const result: Quaternion = Quaternion{
        .x = 0.0,
        .y = 0.0,
        .z = 0.0,
        .w = 1.0,
    };
    return result;
}
pub fn QuaternionLength(arg_q: Quaternion) callconv(.C) f32 {
    const q = arg_q;
    const result: f32 = sqrtf((((q.x * q.x) + (q.y * q.y)) + (q.z * q.z)) + (q.w * q.w));
    return result;
}
pub fn QuaternionNormalize(arg_q: Quaternion) callconv(.C) Quaternion {
    const q = arg_q;
    var result: Quaternion = Quaternion{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
        .w = 0,
    };
    var length: f32 = sqrtf((((q.x * q.x) + (q.y * q.y)) + (q.z * q.z)) + (q.w * q.w));
    if (length == 0.0) {
        length = 1.0;
    }
    const ilength: f32 = 1.0 / length;
    result.x = q.x * ilength;
    result.y = q.y * ilength;
    result.z = q.z * ilength;
    result.w = q.w * ilength;
    return result;
}
pub fn QuaternionInvert(arg_q: Quaternion) callconv(.C) Quaternion {
    const q = arg_q;
    var result: Quaternion = q;
    const lengthSq: f32 = (((q.x * q.x) + (q.y * q.y)) + (q.z * q.z)) + (q.w * q.w);
    if (lengthSq != 0.0) {
        const invLength: f32 = 1.0 / lengthSq;
        result.x *= -invLength;
        result.y *= -invLength;
        result.z *= -invLength;
        result.w *= invLength;
    }
    return result;
}
pub fn QuaternionMultiply(arg_q1: Quaternion, arg_q2: Quaternion) callconv(.C) Quaternion {
    const q1 = arg_q1;
    const q2 = arg_q2;
    var result: Quaternion = Quaternion{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
        .w = 0,
    };
    const qax: f32 = q1.x;
    const qay: f32 = q1.y;
    const qaz: f32 = q1.z;
    const qaw: f32 = q1.w;
    const qbx: f32 = q2.x;
    const qby: f32 = q2.y;
    const qbz: f32 = q2.z;
    const qbw: f32 = q2.w;
    result.x = (((qax * qbw) + (qaw * qbx)) + (qay * qbz)) - (qaz * qby);
    result.y = (((qay * qbw) + (qaw * qby)) + (qaz * qbx)) - (qax * qbz);
    result.z = (((qaz * qbw) + (qaw * qbz)) + (qax * qby)) - (qay * qbx);
    result.w = (((qaw * qbw) - (qax * qbx)) - (qay * qby)) - (qaz * qbz);
    return result;
}
pub fn QuaternionScale(arg_q: Quaternion, arg_mul: f32) callconv(.C) Quaternion {
    const q = arg_q;
    const mul = arg_mul;
    var result: Quaternion = Quaternion{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
        .w = 0,
    };
    result.x = q.x * mul;
    result.y = q.y * mul;
    result.z = q.z * mul;
    result.w = q.w * mul;
    return result;
}
pub fn QuaternionDivide(arg_q1: Quaternion, arg_q2: Quaternion) callconv(.C) Quaternion {
    const q1 = arg_q1;
    const q2 = arg_q2;
    const result: Quaternion = Quaternion{
        .x = q1.x / q2.x,
        .y = q1.y / q2.y,
        .z = q1.z / q2.z,
        .w = q1.w / q2.w,
    };
    return result;
}
pub fn QuaternionLerp(arg_q1: Quaternion, arg_q2: Quaternion, arg_amount: f32) callconv(.C) Quaternion {
    const q1 = arg_q1;
    const q2 = arg_q2;
    const amount = arg_amount;
    var result: Quaternion = Quaternion{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
        .w = 0,
    };
    result.x = q1.x + (amount * (q2.x - q1.x));
    result.y = q1.y + (amount * (q2.y - q1.y));
    result.z = q1.z + (amount * (q2.z - q1.z));
    result.w = q1.w + (amount * (q2.w - q1.w));
    return result;
}
pub fn QuaternionNlerp(arg_q1: Quaternion, arg_q2: Quaternion, arg_amount: f32) callconv(.C) Quaternion {
    const q1 = arg_q1;
    const q2 = arg_q2;
    const amount = arg_amount;
    var result: Quaternion = Quaternion{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
        .w = 0,
    };
    result.x = q1.x + (amount * (q2.x - q1.x));
    result.y = q1.y + (amount * (q2.y - q1.y));
    result.z = q1.z + (amount * (q2.z - q1.z));
    result.w = q1.w + (amount * (q2.w - q1.w));
    const q: Quaternion = result;
    var length: f32 = sqrtf((((q.x * q.x) + (q.y * q.y)) + (q.z * q.z)) + (q.w * q.w));
    if (length == 0.0) {
        length = 1.0;
    }
    const ilength: f32 = 1.0 / length;
    result.x = q.x * ilength;
    result.y = q.y * ilength;
    result.z = q.z * ilength;
    result.w = q.w * ilength;
    return result;
}
pub fn QuaternionSlerp(arg_q1: Quaternion, arg_q2: Quaternion, arg_amount: f32) callconv(.C) Quaternion {
    const q1 = arg_q1;
    var q2 = arg_q2;
    const amount = arg_amount;
    var result: Quaternion = Quaternion{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
        .w = 0,
    };
    var cosHalfTheta: f32 = (((q1.x * q2.x) + (q1.y * q2.y)) + (q1.z * q2.z)) + (q1.w * q2.w);
    if (cosHalfTheta < @as(f32, @floatFromInt(@as(c_int, 0)))) {
        q2.x = -q2.x;
        q2.y = -q2.y;
        q2.z = -q2.z;
        q2.w = -q2.w;
        cosHalfTheta = -cosHalfTheta;
    }
    if (fabsf(cosHalfTheta) >= 1.0) {
        result = q1;
    } else if (cosHalfTheta > 0.949999988079071) {
        result = QuaternionNlerp(q1, q2, amount);
    } else {
        const halfTheta: f32 = acosf(cosHalfTheta);
        const sinHalfTheta: f32 = sqrtf(1.0 - (cosHalfTheta * cosHalfTheta));
        if (fabsf(sinHalfTheta) < 0.0000009999999974752427) {
            result.x = (q1.x * 0.5) + (q2.x * 0.5);
            result.y = (q1.y * 0.5) + (q2.y * 0.5);
            result.z = (q1.z * 0.5) + (q2.z * 0.5);
            result.w = (q1.w * 0.5) + (q2.w * 0.5);
        } else {
            const ratioA: f32 = sinf((@as(f32, @floatFromInt(@as(c_int, 1))) - amount) * halfTheta) / sinHalfTheta;
            const ratioB: f32 = sinf(amount * halfTheta) / sinHalfTheta;
            result.x = (q1.x * ratioA) + (q2.x * ratioB);
            result.y = (q1.y * ratioA) + (q2.y * ratioB);
            result.z = (q1.z * ratioA) + (q2.z * ratioB);
            result.w = (q1.w * ratioA) + (q2.w * ratioB);
        }
    }
    return result;
}
pub fn QuaternionCubicHermiteSpline(arg_q1: Quaternion, arg_outTangent1: Quaternion, arg_q2: Quaternion, arg_inTangent2: Quaternion, arg_t: f32) callconv(.C) Quaternion {
    const q1 = arg_q1;
    const outTangent1 = arg_outTangent1;
    const q2 = arg_q2;
    const inTangent2 = arg_inTangent2;
    const t = arg_t;
    const t2: f32 = t * t;
    const t3: f32 = t2 * t;
    const h00: f32 = ((@as(f32, @floatFromInt(@as(c_int, 2))) * t3) - (@as(f32, @floatFromInt(@as(c_int, 3))) * t2)) + @as(f32, @floatFromInt(@as(c_int, 1)));
    const h10: f32 = (t3 - (@as(f32, @floatFromInt(@as(c_int, 2))) * t2)) + t;
    const h01: f32 = (@as(f32, @floatFromInt(-@as(c_int, 2))) * t3) + (@as(f32, @floatFromInt(@as(c_int, 3))) * t2);
    const h11: f32 = t3 - t2;
    const p0: Quaternion = QuaternionScale(q1, h00);
    const m0: Quaternion = QuaternionScale(outTangent1, h10);
    const p1: Quaternion = QuaternionScale(q2, h01);
    const m1: Quaternion = QuaternionScale(inTangent2, h11);
    var result: Quaternion = Quaternion{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
        .w = 0,
    };
    result = QuaternionAdd(p0, m0);
    result = QuaternionAdd(result, p1);
    result = QuaternionAdd(result, m1);
    result = QuaternionNormalize(result);
    return result;
}
pub fn QuaternionFromVector3ToVector3(arg_from: Vector3, arg_to: Vector3) callconv(.C) Quaternion {
    const from = arg_from;
    const to = arg_to;
    var result: Quaternion = Quaternion{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
        .w = 0,
    };
    const cos2Theta: f32 = ((from.x * to.x) + (from.y * to.y)) + (from.z * to.z);
    const cross: Vector3 = Vector3{
        .x = (from.y * to.z) - (from.z * to.y),
        .y = (from.z * to.x) - (from.x * to.z),
        .z = (from.x * to.y) - (from.y * to.x),
    };
    result.x = cross.x;
    result.y = cross.y;
    result.z = cross.z;
    result.w = 1.0 + cos2Theta;
    const q: Quaternion = result;
    var length: f32 = sqrtf((((q.x * q.x) + (q.y * q.y)) + (q.z * q.z)) + (q.w * q.w));
    if (length == 0.0) {
        length = 1.0;
    }
    const ilength: f32 = 1.0 / length;
    result.x = q.x * ilength;
    result.y = q.y * ilength;
    result.z = q.z * ilength;
    result.w = q.w * ilength;
    return result;
}
pub fn QuaternionFromMatrix(arg_mat: Matrix) callconv(.C) Quaternion {
    const mat = arg_mat;
    var result: Quaternion = Quaternion{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
        .w = 0,
    };
    const fourWSquaredMinus1: f32 = (mat.m0 + mat.m5) + mat.m10;
    const fourXSquaredMinus1: f32 = (mat.m0 - mat.m5) - mat.m10;
    const fourYSquaredMinus1: f32 = (mat.m5 - mat.m0) - mat.m10;
    const fourZSquaredMinus1: f32 = (mat.m10 - mat.m0) - mat.m5;
    var biggestIndex: c_int = 0;
    var fourBiggestSquaredMinus1: f32 = fourWSquaredMinus1;
    if (fourXSquaredMinus1 > fourBiggestSquaredMinus1) {
        fourBiggestSquaredMinus1 = fourXSquaredMinus1;
        biggestIndex = 1;
    }
    if (fourYSquaredMinus1 > fourBiggestSquaredMinus1) {
        fourBiggestSquaredMinus1 = fourYSquaredMinus1;
        biggestIndex = 2;
    }
    if (fourZSquaredMinus1 > fourBiggestSquaredMinus1) {
        fourBiggestSquaredMinus1 = fourZSquaredMinus1;
        biggestIndex = 3;
    }
    const biggestVal: f32 = sqrtf(fourBiggestSquaredMinus1 + 1.0) * 0.5;
    const mult: f32 = 0.25 / biggestVal;
    while (true) {
        switch (biggestIndex) {
            @as(c_int, 0) => {
                result.w = biggestVal;
                result.x = (mat.m6 - mat.m9) * mult;
                result.y = (mat.m8 - mat.m2) * mult;
                result.z = (mat.m1 - mat.m4) * mult;
                break;
            },
            @as(c_int, 1) => {
                result.x = biggestVal;
                result.w = (mat.m6 - mat.m9) * mult;
                result.y = (mat.m1 + mat.m4) * mult;
                result.z = (mat.m8 + mat.m2) * mult;
                break;
            },
            @as(c_int, 2) => {
                result.y = biggestVal;
                result.w = (mat.m8 - mat.m2) * mult;
                result.x = (mat.m1 + mat.m4) * mult;
                result.z = (mat.m6 + mat.m9) * mult;
                break;
            },
            @as(c_int, 3) => {
                result.z = biggestVal;
                result.w = (mat.m1 - mat.m4) * mult;
                result.x = (mat.m8 + mat.m2) * mult;
                result.y = (mat.m6 + mat.m9) * mult;
                break;
            },
            else => {},
        }
        break;
    }
    return result;
}
pub fn QuaternionToMatrix(arg_q: Quaternion) callconv(.C) Matrix {
    const q = arg_q;
    var result: Matrix = Matrix{
        .m0 = 1.0,
        .m4 = 0.0,
        .m8 = 0.0,
        .m12 = 0.0,
        .m1 = 0.0,
        .m5 = 1.0,
        .m9 = 0.0,
        .m13 = 0.0,
        .m2 = 0.0,
        .m6 = 0.0,
        .m10 = 1.0,
        .m14 = 0.0,
        .m3 = 0.0,
        .m7 = 0.0,
        .m11 = 0.0,
        .m15 = 1.0,
    };
    const a2: f32 = q.x * q.x;
    const b2: f32 = q.y * q.y;
    const c2: f32 = q.z * q.z;
    const ac: f32 = q.x * q.z;
    const ab: f32 = q.x * q.y;
    const bc: f32 = q.y * q.z;
    const ad: f32 = q.w * q.x;
    const bd: f32 = q.w * q.y;
    const cd: f32 = q.w * q.z;
    result.m0 = @as(f32, @floatFromInt(@as(c_int, 1))) - (@as(f32, @floatFromInt(@as(c_int, 2))) * (b2 + c2));
    result.m1 = @as(f32, @floatFromInt(@as(c_int, 2))) * (ab + cd);
    result.m2 = @as(f32, @floatFromInt(@as(c_int, 2))) * (ac - bd);
    result.m4 = @as(f32, @floatFromInt(@as(c_int, 2))) * (ab - cd);
    result.m5 = @as(f32, @floatFromInt(@as(c_int, 1))) - (@as(f32, @floatFromInt(@as(c_int, 2))) * (a2 + c2));
    result.m6 = @as(f32, @floatFromInt(@as(c_int, 2))) * (bc + ad);
    result.m8 = @as(f32, @floatFromInt(@as(c_int, 2))) * (ac + bd);
    result.m9 = @as(f32, @floatFromInt(@as(c_int, 2))) * (bc - ad);
    result.m10 = @as(f32, @floatFromInt(@as(c_int, 1))) - (@as(f32, @floatFromInt(@as(c_int, 2))) * (a2 + b2));
    return result;
}
pub fn QuaternionFromAxisAngle(arg_axis: Vector3, arg_angle: f32) callconv(.C) Quaternion {
    var axis = arg_axis;
    var angle = arg_angle;
    var result: Quaternion = Quaternion{
        .x = 0.0,
        .y = 0.0,
        .z = 0.0,
        .w = 1.0,
    };
    const axisLength: f32 = sqrtf(((axis.x * axis.x) + (axis.y * axis.y)) + (axis.z * axis.z));
    if (axisLength != 0.0) {
        angle *= 0.5;
        var length: f32 = 0.0;
        var ilength: f32 = 0.0;
        length = axisLength;
        if (length == 0.0) {
            length = 1.0;
        }
        ilength = 1.0 / length;
        axis.x *= ilength;
        axis.y *= ilength;
        axis.z *= ilength;
        const sinres: f32 = sinf(angle);
        const cosres: f32 = cosf(angle);
        result.x = axis.x * sinres;
        result.y = axis.y * sinres;
        result.z = axis.z * sinres;
        result.w = cosres;
        const q: Quaternion = result;
        length = sqrtf((((q.x * q.x) + (q.y * q.y)) + (q.z * q.z)) + (q.w * q.w));
        if (length == 0.0) {
            length = 1.0;
        }
        ilength = 1.0 / length;
        result.x = q.x * ilength;
        result.y = q.y * ilength;
        result.z = q.z * ilength;
        result.w = q.w * ilength;
    }
    return result;
}
pub fn QuaternionToAxisAngle(arg_q: Quaternion, arg_outAxis: [*c]Vector3, arg_outAngle: [*c]f32) callconv(.C) void {
    var q = arg_q;
    const outAxis = arg_outAxis;
    const outAngle = arg_outAngle;
    if (fabsf(q.w) > 1.0) {
        var length: f32 = sqrtf((((q.x * q.x) + (q.y * q.y)) + (q.z * q.z)) + (q.w * q.w));
        if (length == 0.0) {
            length = 1.0;
        }
        const ilength: f32 = 1.0 / length;
        q.x = q.x * ilength;
        q.y = q.y * ilength;
        q.z = q.z * ilength;
        q.w = q.w * ilength;
    }
    var resAxis: Vector3 = Vector3{
        .x = 0.0,
        .y = 0.0,
        .z = 0.0,
    };
    const resAngle: f32 = 2.0 * acosf(q.w);
    const den: f32 = sqrtf(1.0 - (q.w * q.w));
    if (den > 0.0000009999999974752427) {
        resAxis.x = q.x / den;
        resAxis.y = q.y / den;
        resAxis.z = q.z / den;
    } else {
        resAxis.x = 1.0;
    }
    outAxis.* = resAxis;
    outAngle.* = resAngle;
}
pub fn QuaternionFromEuler(arg_pitch: f32, arg_yaw: f32, arg_roll: f32) callconv(.C) Quaternion {
    const pitch = arg_pitch;
    const yaw = arg_yaw;
    const roll = arg_roll;
    var result: Quaternion = Quaternion{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
        .w = 0,
    };
    const x0: f32 = cosf(pitch * 0.5);
    const x1: f32 = sinf(pitch * 0.5);
    const y0_1: f32 = cosf(yaw * 0.5);
    const y1_2: f32 = sinf(yaw * 0.5);
    const z0: f32 = cosf(roll * 0.5);
    const z1: f32 = sinf(roll * 0.5);
    result.x = ((x1 * y0_1) * z0) - ((x0 * y1_2) * z1);
    result.y = ((x0 * y1_2) * z0) + ((x1 * y0_1) * z1);
    result.z = ((x0 * y0_1) * z1) - ((x1 * y1_2) * z0);
    result.w = ((x0 * y0_1) * z0) + ((x1 * y1_2) * z1);
    return result;
}
pub fn QuaternionToEuler(arg_q: Quaternion) callconv(.C) Vector3 {
    const q = arg_q;
    var result: Vector3 = Vector3{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
    };
    const x0: f32 = 2.0 * ((q.w * q.x) + (q.y * q.z));
    const x1: f32 = 1.0 - (2.0 * ((q.x * q.x) + (q.y * q.y)));
    result.x = atan2f(x0, x1);
    var y0_1: f32 = 2.0 * ((q.w * q.y) - (q.z * q.x));
    y0_1 = if (y0_1 > 1.0) 1.0 else y0_1;
    y0_1 = if (y0_1 < -1.0) -1.0 else y0_1;
    result.y = asinf(y0_1);
    const z0: f32 = 2.0 * ((q.w * q.z) + (q.x * q.y));
    const z1: f32 = 1.0 - (2.0 * ((q.y * q.y) + (q.z * q.z)));
    result.z = atan2f(z0, z1);
    return result;
}

pub fn QuaternionTransform(arg_q: Quaternion, arg_mat: Matrix) callconv(.C) Quaternion {
    const q = arg_q;
    const mat = arg_mat;
    var result: Quaternion = Quaternion{
        .x = @as(f32, @floatFromInt(@as(c_int, 0))),
        .y = 0,
        .z = 0,
        .w = 0,
    };
    result.x = (((mat.m0 * q.x) + (mat.m4 * q.y)) + (mat.m8 * q.z)) + (mat.m12 * q.w);
    result.y = (((mat.m1 * q.x) + (mat.m5 * q.y)) + (mat.m9 * q.z)) + (mat.m13 * q.w);
    result.z = (((mat.m2 * q.x) + (mat.m6 * q.y)) + (mat.m10 * q.z)) + (mat.m14 * q.w);
    result.w = (((mat.m3 * q.x) + (mat.m7 * q.y)) + (mat.m11 * q.z)) + (mat.m15 * q.w);
    return result;
}
pub fn QuaternionEquals(arg_p: Quaternion, arg_q: Quaternion) callconv(.C) c_int {
    const p = arg_p;
    const q = arg_q;
    const result: c_int = @intFromBool(((((fabsf(p.x - q.x) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.x), fabsf(q.x))))) and (fabsf(p.y - q.y) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.y), fabsf(q.y)))))) and (fabsf(p.z - q.z) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.z), fabsf(q.z)))))) and (fabsf(p.w - q.w) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.w), fabsf(q.w)))))) or ((((fabsf(p.x + q.x) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.x), fabsf(q.x))))) and (fabsf(p.y + q.y) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.y), fabsf(q.y)))))) and (fabsf(p.z + q.z) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.z), fabsf(q.z)))))) and (fabsf(p.w + q.w) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.w), fabsf(q.w)))))));
    return result;
}
pub fn MatrixDecompose(arg_mat: Matrix, arg_translation: [*c]Vector3, arg_rotation: [*c]Quaternion, arg_scale: [*c]Vector3) callconv(.C) void {
    const mat = arg_mat;
    const translation = arg_translation;
    const rotation = arg_rotation;
    const scale = arg_scale;
    translation.*.x = mat.m12;
    translation.*.y = mat.m13;
    translation.*.z = mat.m14;
    const a: f32 = mat.m0;
    const b: f32 = mat.m4;
    const c: f32 = mat.m8;
    const d: f32 = mat.m1;
    const e: f32 = mat.m5;
    const f: f32 = mat.m9;
    const g: f32 = mat.m2;
    const h: f32 = mat.m6;
    const i: f32 = mat.m10;
    const A: f32 = (e * i) - (f * h);
    const B: f32 = (f * g) - (d * i);
    const C: f32 = (d * h) - (e * g);
    const det: f32 = ((a * A) + (b * B)) + (c * C);
    const abc: Vector3 = Vector3{
        .x = a,
        .y = b,
        .z = c,
    };
    const def: Vector3 = Vector3{
        .x = d,
        .y = e,
        .z = f,
    };
    const ghi: Vector3 = Vector3{
        .x = g,
        .y = h,
        .z = i,
    };
    const scalex: f32 = Vector3Length(abc);
    const scaley: f32 = Vector3Length(def);
    const scalez: f32 = Vector3Length(ghi);
    var s: Vector3 = Vector3{
        .x = scalex,
        .y = scaley,
        .z = scalez,
    };
    if (det < @as(f32, @floatFromInt(@as(c_int, 0)))) {
        s = Vector3Negate(s);
    }
    scale.* = s;
    var clone: Matrix = mat;
    if (!(FloatEquals(det, @as(f32, @floatFromInt(@as(c_int, 0)))) != 0)) {
        clone.m0 /= s.x;
        clone.m5 /= s.y;
        clone.m10 /= s.z;
        rotation.* = QuaternionFromMatrix(clone);
    } else {
        rotation.* = QuaternionIdentity();
    }
}
