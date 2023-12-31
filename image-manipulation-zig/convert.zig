const std = @import("std");

pub const RgbPixel = struct { r: u8, g: u8, b: u8, a: u8 };
pub const HslPixel = struct { h: f64, s: f64, l: f64, a: u8 };

pub fn rgb_to_hsl(rgb_pixel: RgbPixel) HslPixel {
    var r: f64 = @floatFromInt(rgb_pixel.r);
    var g: f64 = @floatFromInt(rgb_pixel.g);
    var b: f64 = @floatFromInt(rgb_pixel.b);
    r /= 255.0;
    g /= 255.0;
    b /= 255.0;
    const max = @max(r, g, b);
    const min = @min(r, g, b);
    const diff = (max - min);

    const l = (max + min) / 2;
    const s = if (l < std.math.floatEps(f64)) 0.0 else diff / (1.0 - std.math.fabs(2.0 * l - 1.0));

    var h: f64 = if (s < std.math.floatEps(f64)) 0.0 else if (max == r) (g - b) / diff else if (max == g) 2.0 + (b - r) / diff else 4.0 + (r - g) / diff;

    h *= 60;
    h = if (h >= 0) h else h + 360;

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

    var r: f64 = 0.0;
    var g: f64 = 0.0;
    var b: f64 = 0.0;

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

    r = std.math.round(r);
    g = std.math.round(g);
    b = std.math.round(b);

    return RgbPixel{ .r = @intFromFloat(r), .g = @intFromFloat(g), .b = @intFromFloat(b), .a = hsl_pixel.a };
}

const expect = std.testing.expect;
const eql = std.meta.eql;

test "RGB -> HSL" {
    try expect(eql(rgb_to_hsl(RgbPixel{ .r = 255, .g = 0, .b = 0, .a = 255 }), HslPixel{ .h = 0.0, .s = 1.0, .l = 0.5, .a = 255 }));
    try expect(eql(rgb_to_hsl(RgbPixel{ .r = 0, .g = 255, .b = 0, .a = 255 }), HslPixel{ .h = 120.0, .s = 1.0, .l = 0.5, .a = 255 }));
    try expect(eql(rgb_to_hsl(RgbPixel{ .r = 0, .g = 0, .b = 255, .a = 255 }), HslPixel{ .h = 240.0, .s = 1.0, .l = 0.5, .a = 255 }));
}

test "HSL -> RGB" {
    try expect(eql(hsl_to_rgb(HslPixel{ .h = 0.0, .s = 1.0, .l = 0.5, .a = 255 }), RgbPixel{ .r = 255, .g = 0, .b = 0, .a = 255 }));
    try expect(eql(hsl_to_rgb(HslPixel{ .h = 120.0, .s = 1.0, .l = 0.5, .a = 255 }), RgbPixel{ .r = 0, .g = 255, .b = 0, .a = 255 }));
    try expect(eql(hsl_to_rgb(HslPixel{ .h = 240.0, .s = 1.0, .l = 0.5, .a = 255 }), RgbPixel{ .r = 0, .g = 0, .b = 255, .a = 255 }));
}

test "RGB -> HSL -> RGB equality" {
  for(0..255) |r| {
    for(0..255) |g| {
      for(0..255) |b| {
        const actRgb = RgbPixel{.r = @intCast(r), .g = @intCast(g), .b = @intCast(b), .a = 255 };
        const actHsl = rgb_to_hsl(actRgb);
        const actRgb2 = hsl_to_rgb(actHsl);
        try expect(eql(actRgb, actRgb2));
      }
    }
  }
}
