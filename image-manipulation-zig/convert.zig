const std = @import("std");

pub const RgbPixel = struct { r: u8, g: u8, b: u8, a: u8 };
pub const HslPixel = struct { h: f32, s: f32, l: f32, a: u8 };

pub fn rgb_to_hsl(rgb_pixel: RgbPixel) HslPixel {
    const r: f32 = @floatFromInt(rgb_pixel.r);
    const g: f32 = @floatFromInt(rgb_pixel.g);
    const b: f32 = @floatFromInt(rgb_pixel.b);
    const max = @max(@max(r, g), b);
    const min = @min(@min(r, g), b);
    const diff = (max - min) / 255;

    const l = (max + min) / 510;
    const s = if (l == 0) 0 else diff / (1 - std.math.fabs(2 * l - 1));

    var h: f32 = 0.0;

    if (s > std.math.floatEps(f32)) {
        h = std.math.radiansToDegrees(f32, std.math.acos((r - 0.5 * g - 0.5 * b) / std.math.sqrt(r * r + g * g + b * b - r * g - r * b - g * b)));

        if (b > g) {
            h = 360 - h;
        }
    }

    return HslPixel{ .h = h, .s = s, .l = l, .a = rgb_pixel.a };
}

pub fn hsl_to_rgb(hsl_pixel: HslPixel) RgbPixel {
    const h = hsl_pixel.h;
    const s = hsl_pixel.s;
    const l = hsl_pixel.l;

    const diff = s * (1 - std.math.fabs(2 * l - 1));
    const min = 255 * (l - 0.5 * diff);

    const x = diff * (1 - std.math.fabs(@mod((h / 60.0), 2) - 1));

    const val1 = 255 * diff + min;
    const val2 = 255 * x + min;

    var r: f32 = 0.0;
    var g: f32 = 0.0;
    var b: f32 = 0.0;

    if (h < 60) {
        r = val1;
        g = val2;
        b = min;
    } else if (h < 120) {
        r = val2;
        g = val1;
        b = min;
    } else if (h < 180) {
        r = min;
        g = val1;
        b = val2;
    } else if (h < 240) {
        r = min;
        g = val2;
        b = val1;
    } else if (h < 300) {
        r = val2;
        g = min;
        b = val1;
    } else {
        r = val1;
        g = min;
        b = val2;
    }

    return RgbPixel{ .r = @intFromFloat(r), .g = @intFromFloat(g), .b = @intFromFloat(b), .a = hsl_pixel.a };
}

const expect = std.testing.expect;
const eql = std.meta.eql;

test "RGB -> HSL" {
    try expect(eql(rgb_to_hsl(RgbPixel{ .r = 255, .g = 0, .b = 0, .a = 255 }), HslPixel{ .h = 0.0, .s = 1.0, .l = 0.5, .a = 255 }));
    try expect(eql(rgb_to_hsl(RgbPixel{ .r = 0, .g = 255, .b = 0, .a = 255 }), HslPixel{ .h = 120.0, .s = 1.0, .l = 0.5, .a = 255 }));
    try expect(eql(rgb_to_hsl(RgbPixel{ .r = 0, .g = 0, .b = 255, .a = 255 }), HslPixel{ .h = 240.0, .s = 1.0, .l = 0.5, .a = 255 }));
}
