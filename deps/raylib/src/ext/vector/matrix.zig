const std = @import("std");
const util = @import("util.zig");
pub const Quaternion = @import("Vector4.zig").Vector4;
pub const Vector3 = @import("Vector3.zig").Vector3;
pub const Vector4 = @import("Vector4.zig").Vector4;

const math = std.math;
const sqrtf = math.sqrt;
const cosf = math.cos;
const sinf = math.sin;
const tan = math.tan;
const atan2f = math.atan2;
const acosf = math.acos;
const asinf = math.asin;
const fabsf = math.fabsf;
const fmaxf = math.fmaxf;
const feql = util.feql;

pub const Matrix = extern struct {
    m0: f32 = 0,
    m4: f32 = 0,
    m8: f32 = 0,
    m12: f32 = 0,
    m1: f32 = 0,
    m5: f32 = 0,
    m9: f32 = 0,
    m13: f32 = 0,
    m2: f32 = 0,
    m6: f32 = 0,
    m10: f32 = 0,
    m14: f32 = 0,
    m3: f32 = 0,
    m7: f32 = 0,
    m11: f32 = 0,
    m15: f32 = 0,
};

pub fn MatrixDeterminant(mat: Matrix) callconv(.c) f32 {
    const result: f32 = 0.0;
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

pub fn MatrixTrace(mat: Matrix) callconv(.c) f32 {
    const result: f32 = ((mat.m0 + mat.m5) + mat.m10) + mat.m15;
    return result;
}

pub fn MatrixTranspose(mat: Matrix) callconv(.c) Matrix {
    const result: Matrix = Matrix{
        .m0 = 0,
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

pub fn MatrixInvert(mat: Matrix) callconv(.c) Matrix {
    const result: Matrix = Matrix{
        .m0 = 0,
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

pub fn MatrixIdentity() callconv(.c) Matrix {
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

pub fn MatrixAdd(left: Matrix, right: Matrix) callconv(.c) Matrix {
    const result: Matrix = Matrix{
        .m0 = 0,
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

pub fn MatrixSubtract(left: Matrix, right: Matrix) callconv(.c) Matrix {
    const result: Matrix = Matrix{
        .m0 = 0,
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

pub fn MatrixMultiply(left: Matrix, right: Matrix) callconv(.c) Matrix {
    const result: Matrix = Matrix{
        .m0 = 0,
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

pub fn MatrixTranslate(x: f32, y: f32, z: f32) callconv(.c) Matrix {
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

pub fn MatrixRotate(axis: Vector3, angle: f32) callconv(.c) Matrix {
    const result: Matrix = Matrix{
        .m0 = 0,
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

    const x: f32 = axis.x;
    const y: f32 = axis.y;
    const z: f32 = axis.z;
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

pub fn MatrixRotateX(angle: f32) callconv(.c) Matrix {
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

    const cosres: f32 = cosf(angle);
    const sinres: f32 = sinf(angle);
    result.m5 = cosres;
    result.m6 = sinres;
    result.m9 = -sinres;
    result.m10 = cosres;
    return result;
}

pub fn MatrixRotateY(angle: f32) callconv(.c) Matrix {
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

    const cosres: f32 = cosf(angle);
    const sinres: f32 = sinf(angle);
    result.m0 = cosres;
    result.m2 = -sinres;
    result.m8 = sinres;
    result.m10 = cosres;
    return result;
}

pub fn MatrixRotateZ(angle: f32) callconv(.c) Matrix {
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

    const cosres: f32 = cosf(angle);
    const sinres: f32 = sinf(angle);
    result.m0 = cosres;
    result.m1 = sinres;
    result.m4 = -sinres;
    result.m5 = cosres;
    return result;
}

pub fn MatrixRotateXYZ(angle: Vector3) callconv(.c) Matrix {
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

pub fn MatrixRotateZYX(angle: Vector3) callconv(.c) Matrix {
    const result: Matrix = Matrix{
        .m0 = 0,
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

pub fn MatrixScale(x: f32, y: f32, z: f32) callconv(.c) Matrix {
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

pub fn MatrixFrustum(left: f64, right: f64, bottom: f64, top: f64, nearPlane: f64, farPlane: f64) callconv(.c) Matrix {
    const result: Matrix = Matrix{
        .m0 = 0,
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
    var @"fn": f32 = @as(f32, @floatCast(farPlane - nearPlane));
    _ = &@"fn";
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

pub fn MatrixPerspective(fovY: f64, aspect: f64, nearPlane: f64, farPlane: f64) callconv(.c) Matrix {
    const result: Matrix = Matrix{
        .m0 = 0,
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
    var @"fn": f32 = @as(f32, @floatCast(farPlane - nearPlane));
    _ = &@"fn";
    result.m0 = (@as(f32, @floatCast(nearPlane)) * 2.0) / rl;
    result.m5 = (@as(f32, @floatCast(nearPlane)) * 2.0) / tb;
    result.m8 = (@as(f32, @floatCast(right)) + @as(f32, @floatCast(left))) / rl;
    result.m9 = (@as(f32, @floatCast(top)) + @as(f32, @floatCast(bottom))) / tb;
    result.m10 = -(@as(f32, @floatCast(farPlane)) + @as(f32, @floatCast(nearPlane))) / @"fn";
    result.m11 = -1.0;
    result.m14 = -((@as(f32, @floatCast(farPlane)) * @as(f32, @floatCast(nearPlane))) * 2.0) / @"fn";
    return result;
}

pub fn MatrixOrtho(left: f64, right: f64, bottom: f64, top: f64, nearPlane: f64, farPlane: f64) callconv(.c) Matrix {
    const result: Matrix = Matrix{
        .m0 = 0,
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
    var @"fn": f32 = @as(f32, @floatCast(farPlane - nearPlane));
    _ = &@"fn";
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

pub fn MatrixLookAt(eye: Vector3, target: Vector3, up: Vector3) callconv(.c) Matrix {
    const result: Matrix = Matrix{
        .m0 = 0,
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

    const length: f32 = 0.0;
    const ilength: f32 = 0.0;
    var vz: Vector3 = Vector3{
        .x = eye.x - target.x,
        .y = eye.y - target.y,
        .z = eye.z - target.z,
    };

    const v: Vector3 = vz;
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

pub fn MatrixToFloatV(mat: Matrix) callconv(.c) float16 {
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

pub fn QuaternionAdd(q1: Quaternion, q2: Quaternion) callconv(.c) Quaternion {
    const result: Quaternion = Quaternion{
        .x = q1.x + q2.x,
        .y = q1.y + q2.y,
        .z = q1.z + q2.z,
        .w = q1.w + q2.w,
    };

    return result;
}

pub fn QuaternionAddValue(q: Quaternion, add: f32) callconv(.c) Quaternion {
    const result: Quaternion = Quaternion{
        .x = q.x + add,
        .y = q.y + add,
        .z = q.z + add,
        .w = q.w + add,
    };

    return result;
}

pub fn QuaternionSubtract(q1: Quaternion, q2: Quaternion) callconv(.c) Quaternion {
    const result: Quaternion = Quaternion{
        .x = q1.x - q2.x,
        .y = q1.y - q2.y,
        .z = q1.z - q2.z,
        .w = q1.w - q2.w,
    };

    return result;
}

pub fn QuaternionSubtractValue(q: Quaternion, sub: f32) callconv(.c) Quaternion {
    const result: Quaternion = Quaternion{
        .x = q.x - sub,
        .y = q.y - sub,
        .z = q.z - sub,
        .w = q.w - sub,
    };

    return result;
}

pub fn QuaternionIdentity() callconv(.c) Quaternion {
    const result: Quaternion = Quaternion{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 1.0 };

    return result;
}

pub fn QuaternionLength(q: Quaternion) callconv(.c) f32 {
    const result: f32 = sqrtf((((q.x * q.x) + (q.y * q.y)) + (q.z * q.z)) + (q.w * q.w));
    return result;
}

pub fn QuaternionNormalize(q: Quaternion) callconv(.c) Quaternion {
    const result: Quaternion = Quaternion{ .x = 0, .y = 0, .z = 0, .w = 0 };

    const length: f32 = sqrtf((((q.x * q.x) + (q.y * q.y)) + (q.z * q.z)) + (q.w * q.w));
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

pub fn QuaternionInvert(q: Quaternion) callconv(.c) Quaternion {
    const result: Quaternion = q;
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

pub fn QuaternionMultiply(q1: Quaternion, q2: Quaternion) callconv(.c) Quaternion {
    const result: Quaternion = Quaternion{ .x = 0, .y = 0, .z = 0, .w = 0 };

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

pub fn QuaternionScale(q: Quaternion, mul: f32) callconv(.c) Quaternion {
    const result: Quaternion = Quaternion{ .x = 0, .y = 0, .z = 0, .w = 0 };

    result.x = q.x * mul;
    result.y = q.y * mul;
    result.z = q.z * mul;
    result.w = q.w * mul;
    return result;
}

pub fn QuaternionDivide(q1: Quaternion, q2: Quaternion) callconv(.c) Quaternion {
    const result: Quaternion = Quaternion{
        .x = q1.x / q2.x,
        .y = q1.y / q2.y,
        .z = q1.z / q2.z,
        .w = q1.w / q2.w,
    };

    return result;
}

pub fn QuaternionLerp(q1: Quaternion, q2: Quaternion, amount: f32) callconv(.c) Quaternion {
    const result: Quaternion = Quaternion{ .x = 0, .y = 0, .z = 0, .w = 0 };

    result.x = q1.x + (amount * (q2.x - q1.x));
    result.y = q1.y + (amount * (q2.y - q1.y));
    result.z = q1.z + (amount * (q2.z - q1.z));
    result.w = q1.w + (amount * (q2.w - q1.w));
    return result;
}

pub fn QuaternionNlerp(q1: Quaternion, q2: Quaternion, amount: f32) callconv(.c) Quaternion {
    const result: Quaternion = Quaternion{ .x = 0, .y = 0, .z = 0, .w = 0 };

    result.x = q1.x + (amount * (q2.x - q1.x));
    result.y = q1.y + (amount * (q2.y - q1.y));
    result.z = q1.z + (amount * (q2.z - q1.z));
    result.w = q1.w + (amount * (q2.w - q1.w));
    const q: Quaternion = result;
    const length: f32 = sqrtf((((q.x * q.x) + (q.y * q.y)) + (q.z * q.z)) + (q.w * q.w));
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

pub fn QuaternionSlerp(q1: Quaternion, q2: Quaternion, amount: f32) callconv(.c) Quaternion {
    const result: Quaternion = Quaternion{ .x = 0, .y = 0, .z = 0, .w = 0 };

    const cosHalfTheta: f32 = (((q1.x * q2.x) + (q1.y * q2.y)) + (q1.z * q2.z)) + (q1.w * q2.w);
    if (cosHalfTheta < 0) {
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
            const ratioA: f32 = sinf((1.0 - amount) * halfTheta) / sinHalfTheta;
            const ratioB: f32 = sinf(amount * halfTheta) / sinHalfTheta;
            result.x = (q1.x * ratioA) + (q2.x * ratioB);
            result.y = (q1.y * ratioA) + (q2.y * ratioB);
            result.z = (q1.z * ratioA) + (q2.z * ratioB);
            result.w = (q1.w * ratioA) + (q2.w * ratioB);
        }
    }
    return result;
}

pub fn QuaternionCubicHermiteSpline(q1: Quaternion, outTangent1: Quaternion, q2: Quaternion, inTangent2: Quaternion, t: f32) callconv(.c) Quaternion {
    const t2: f32 = t * t;
    const t3: f32 = t2 * t;
    const h00: f32 = ((2.0 * t3) - (3.0 * t2)) + 1.0;
    const h10: f32 = (t3 - (2.0 * t2)) + t;
    const h01: f32 = (@as(f32, @floatFromInt(-@as(c_int, 2))) * t3) + (3.0 * t2);
    const h11: f32 = t3 - t2;
    const p0: Quaternion = QuaternionScale(q1, h00);
    const m0: Quaternion = QuaternionScale(outTangent1, h10);
    const p1: Quaternion = QuaternionScale(q2, h01);
    const m1: Quaternion = QuaternionScale(inTangent2, h11);
    const result: Quaternion = Quaternion{ .x = 0, .y = 0, .z = 0, .w = 0 };

    result = QuaternionAdd(p0, m0);
    result = QuaternionAdd(result, p1);
    result = QuaternionAdd(result, m1);
    result = QuaternionNormalize(result);
    return result;
}

pub fn QuaternionFromVector3ToVector3(from: Vector3, to: Vector3) callconv(.c) Quaternion {
    const result: Quaternion = Quaternion{ .x = 0, .y = 0, .z = 0, .w = 0 };

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
    const length: f32 = sqrtf((((q.x * q.x) + (q.y * q.y)) + (q.z * q.z)) + (q.w * q.w));
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

pub fn QuaternionFromMatrix(mat: Matrix) callconv(.c) Quaternion {
    const result: Quaternion = Quaternion{ .x = 0, .y = 0, .z = 0, .w = 0 };

    const fourWSquaredMinus1: f32 = (mat.m0 + mat.m5) + mat.m10;
    const fourXSquaredMinus1: f32 = (mat.m0 - mat.m5) - mat.m10;
    const fourYSquaredMinus1: f32 = (mat.m5 - mat.m0) - mat.m10;
    const fourZSquaredMinus1: f32 = (mat.m10 - mat.m0) - mat.m5;
    const biggestIndex: c_int = 0;
    const fourBiggestSquaredMinus1: f32 = fourWSquaredMinus1;
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

pub fn QuaternionToMatrix(q: Quaternion) callconv(.c) Matrix {
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

    const a2: f32 = q.x * q.x;
    const b2: f32 = q.y * q.y;
    const c2: f32 = q.z * q.z;
    const ac: f32 = q.x * q.z;
    const ab: f32 = q.x * q.y;
    const bc: f32 = q.y * q.z;
    const ad: f32 = q.w * q.x;
    const bd: f32 = q.w * q.y;
    const cd: f32 = q.w * q.z;
    result.m0 = 1.0 - (2.0 * (b2 + c2));
    result.m1 = 2.0 * (ab + cd);
    result.m2 = 2.0 * (ac - bd);
    result.m4 = 2.0 * (ab - cd);
    result.m5 = 1.0 - (2.0 * (a2 + c2));
    result.m6 = 2.0 * (bc + ad);
    result.m8 = 2.0 * (ac + bd);
    result.m9 = 2.0 * (bc - ad);
    result.m10 = 1.0 - (2.0 * (a2 + b2));
    return result;
}

pub fn QuaternionFromAxisAngle(axis: Vector3, angle: f32) callconv(.c) Quaternion {
    const result: Quaternion = Quaternion{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 1.0 };

    const axisLength: f32 = sqrtf(((axis.x * axis.x) + (axis.y * axis.y)) + (axis.z * axis.z));
    if (axisLength != 0.0) {
        angle *= 0.5;
        const length: f32 = 0.0;
        const ilength: f32 = 0.0;
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

pub fn QuaternionToAxisAngle(q: Quaternion, outAxis: [*c]Vector3, outAngle: [*c]f32) callconv(.c) void {
    if (fabsf(q.w) > 1.0) {
        const length: f32 = sqrtf((((q.x * q.x) + (q.y * q.y)) + (q.z * q.z)) + (q.w * q.w));
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

pub fn QuaternionFromEuler(pitch: f32, yaw: f32, roll: f32) callconv(.c) Quaternion {
    const result: Quaternion = Quaternion{ .x = 0, .y = 0, .z = 0, .w = 0 };

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

pub fn QuaternionToEuler(q: Quaternion) callconv(.c) Vector3 {
    const result: Vector3 = Vector3{
        .x = 0,
        .y = 0,
        .z = 0,
    };

    const x0: f32 = 2.0 * ((q.w * q.x) + (q.y * q.z));
    const x1: f32 = 1.0 - (2.0 * ((q.x * q.x) + (q.y * q.y)));
    result.x = atan2f(x0, x1);
    const y0_1: f32 = 2.0 * ((q.w * q.y) - (q.z * q.x));
    y0_1 = if (y0_1 > 1.0) 1.0 else y0_1;
    y0_1 = if (y0_1 < -1.0) -1.0 else y0_1;
    result.y = asinf(y0_1);
    const z0: f32 = 2.0 * ((q.w * q.z) + (q.x * q.y));
    const z1: f32 = 1.0 - (2.0 * ((q.y * q.y) + (q.z * q.z)));
    result.z = atan2f(z0, z1);
    return result;
}

pub fn QuaternionTransform(q: Quaternion, mat: Matrix) callconv(.c) Quaternion {
    const result: Quaternion = Quaternion{ .x = 0, .y = 0, .z = 0, .w = 0 };

    result.x = (((mat.m0 * q.x) + (mat.m4 * q.y)) + (mat.m8 * q.z)) + (mat.m12 * q.w);
    result.y = (((mat.m1 * q.x) + (mat.m5 * q.y)) + (mat.m9 * q.z)) + (mat.m13 * q.w);
    result.z = (((mat.m2 * q.x) + (mat.m6 * q.y)) + (mat.m10 * q.z)) + (mat.m14 * q.w);
    result.w = (((mat.m3 * q.x) + (mat.m7 * q.y)) + (mat.m11 * q.z)) + (mat.m15 * q.w);
    return result;
}

pub fn QuaternionEquals(p: Quaternion, q: Quaternion) callconv(.c) c_int {
    const result: c_int = @intFromBool(((((fabsf(p.x - q.x) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.x), fabsf(q.x))))) and (fabsf(p.y - q.y) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.y), fabsf(q.y)))))) and (fabsf(p.z - q.z) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.z), fabsf(q.z)))))) and (fabsf(p.w - q.w) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.w), fabsf(q.w)))))) or ((((fabsf(p.x + q.x) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.x), fabsf(q.x))))) and (fabsf(p.y + q.y) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.y), fabsf(q.y)))))) and (fabsf(p.z + q.z) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.z), fabsf(q.z)))))) and (fabsf(p.w + q.w) <= (0.0000009999999974752427 * fmaxf(1.0, fmaxf(fabsf(p.w), fabsf(q.w)))))));
    return result;
}

pub fn MatrixDecompose(mat: Matrix, translation: [*c]Vector3, rotation: [*c]Quaternion, scale: [*c]Vector3) callconv(.c) void {
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
    var abc: Vector3 = Vector3{ .x = a, .y = b, .z = c };
    var def: Vector3 = Vector3{ .x = d, .y = e, .z = f };
    var ghi: Vector3 = Vector3{ .x = g, .y = h, .z = i };

    const scalex: f32 = abc.length();
    const scaley: f32 = def.length();
    const scalez: f32 = ghi.length();
    var s: Vector3 = Vector3{
        .x = scalex,
        .y = scaley,
        .z = scalez,
    };

    if (det < 0) {
        s = s.negate();
    }
    scale.* = s;
    const clone: Matrix = mat;
    if (!(feql(det, 0) != 0)) {
        clone.m0 /= s.x;
        clone.m4 /= s.x;
        clone.m8 /= s.x;
        clone.m1 /= s.y;
        clone.m5 /= s.y;
        clone.m9 /= s.y;
        clone.m2 /= s.z;
        clone.m6 /= s.z;
        clone.m10 /= s.z;
        rotation.* = QuaternionFromMatrix(clone);
    } else {
        rotation.* = QuaternionIdentity();
    }
}

pub const float16 = extern struct {
    v: [16]f32 = .{},
};
