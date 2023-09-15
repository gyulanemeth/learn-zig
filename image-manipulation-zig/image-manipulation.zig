const std = @import("std");

const ImageData = struct { n_rows: u32, n_cols: u32, data: []u8 };
const RgbPixel = struct { r: u8, g: u8, b: u8, a: u8 };
const HslPixel = struct { h: f32, s: f32, l: f32, a: u8 };
const Coord = struct { x: u32, y: u32 };

extern fn debug(r_idx: usize, c_idx: usize) void;

var full_state: ImageData = undefined;
var state_1: ImageData = undefined;
var state_2: ImageData = undefined;

var current_state: ImageData = undefined;
var next_state: ImageData = undefined;

export fn init(n_rows: u32, n_cols: u32) callconv(.C) [*]u8 {
    const num_color_values = n_rows * n_cols * 4; // 4x -> r, g, b, a;
    const memory_size = num_color_values * 2; // 2x -> current_state, next_state
    var memory = std.heap.wasm_allocator.alloc(u8, memory_size) catch unreachable;

    full_state = ImageData{ .n_rows = n_rows, .n_cols = n_cols, .data = memory };
    state_1 = ImageData{ .n_rows = full_state.n_rows, .n_cols = full_state.n_cols, .data = full_state.data[0..num_color_values] };
    state_2 = ImageData{ .n_rows = full_state.n_rows, .n_cols = full_state.n_cols, .data = full_state.data[num_color_values..] };

    current_state = state_1;
    next_state = state_2;

    return memory.ptr;
}

export fn currentImgAddress() callconv(.C) [*]u8 {
    return current_state.data.ptr;
}

export fn destroy() void {
    std.heap.wasm_allocator.free(full_state.data);
}

fn swap_states() void {
    var tmp = current_state;
    current_state = next_state;
    next_state = tmp;
}

fn get_pixel(r_idx: usize, c_idx: usize) RgbPixel {
    const red_idx = (r_idx * current_state.n_cols + c_idx) * 4;


    return RgbPixel{
        .r = current_state.data[red_idx],
        .g = current_state.data[red_idx + 1],
        .b = current_state.data[red_idx + 2],
        .a = current_state.data[red_idx + 3]
    };
}

export fn set_pixel(r_idx: usize, c_idx: usize, r: u8, g: u8, b: u8, a: u8) void {
    const red_idx: usize = (r_idx * current_state.n_cols + c_idx) * 4;
    current_state.data[red_idx] = r;
    current_state.data[red_idx + 1] = g;
    current_state.data[red_idx + 2] = b;
    current_state.data[red_idx + 3] = a;
}

fn set_next_pixel(coord: Coord, pixel: RgbPixel) void {
    const red_idx = (coord.y * next_state.n_cols + coord.x) * 4;
    next_state.data[red_idx] = pixel.r;
    next_state.data[red_idx + 1] = pixel.g;
    next_state.data[red_idx + 2] = pixel.b;
    next_state.data[red_idx + 3] = pixel.a;
}

export fn invert() void {
    var idx: u32 = 0;
    while (idx < current_state.data.len) : (idx += 4) {
        next_state.data[idx] = 255 - current_state.data[idx];
        next_state.data[idx + 1] = 255 - current_state.data[idx + 1];
        next_state.data[idx + 2] = 255 - current_state.data[idx + 2];
        next_state.data[idx + 3] = current_state.data[idx + 3];
    }
    swap_states();
}

export fn to_grayscale() void {
    var idx: u32 = 0;
    while (idx < current_state.data.len) : (idx += 4) {
        const r: u16 = @intCast(current_state.data[idx]);
        const g: u16 = @intCast(current_state.data[idx + 1]);
        const b: u16 = @intCast(current_state.data[idx + 2]);

        const avg: u16 = (r + g + b) / 3;
        const avg8: u8 = @intCast(avg);

        next_state.data[idx] = avg8;
        next_state.data[idx + 1] = avg8;
        next_state.data[idx + 2] = avg8;
        next_state.data[idx + 3] = current_state.data[idx + 3];
    }
    swap_states();
}

fn avg_pixels(pixelCoords: []Coord, kernel: []f32) RgbPixel {
    var avgR: f32 = 0;
    var avgG: f32 = 0;
    var avgB: f32 = 0;
    var avgA: u8 = 255; // 255 alpha is temporal

    for (pixelCoords, 0..) |coord, idx| {
        const actRgbPixel: RgbPixel = get_pixel(coord.y, coord.x);
        const actKernel = kernel[idx];

        const actR: f32 = @floatFromInt(actRgbPixel.r);
        const actG: f32 = @floatFromInt(actRgbPixel.g);
        const actB: f32 = @floatFromInt(actRgbPixel.b);

        avgR += actR * actKernel;
        avgG += actG * actKernel;
        avgB += actB * actKernel;
    }



    const r: u8 = if (avgR > 255) 255 else if (avgR < 0) 0 else @intFromFloat(avgR);
    const g: u8 = if (avgG > 255) 255 else if (avgG < 0) 0 else @intFromFloat(avgG);
    const b: u8 = if (avgB > 255) 255 else if (avgB < 0) 0 else @intFromFloat(avgB);

    return RgbPixel{
        .r = r,
        .g = g,
        .b = b,
        .a = avgA
    };
}

fn convolution(kernel: []f32) void {
    const maxX = current_state.n_cols - 1;
    const maxY = current_state.n_rows - 1;

    // corners
    // top-left
    var corner_coords = [4]Coord{
        .{ .x = 0, .y = 0 },
        .{ .x = 0, .y = 1 },
        .{ .x = 1, .y = 0 },
        .{ .x = 1, .y = 1 }
    };
    var cornerKernel = [_]f32{ kernel[4], kernel[7], kernel[5], kernel[8] };
    set_next_pixel(Coord{ .x = 0, .y = 0}, avg_pixels(@constCast(&corner_coords), @constCast(&cornerKernel)));
    // top-right
    corner_coords = [4]Coord{
        .{ .x = maxX, .y = 0 },
        .{ .x = maxX, .y = 1 },
        .{ .x = maxX - 1, .y = 0 },
        .{ .x = maxX - 1, .y = 1 }
    };
    cornerKernel = [_]f32{ kernel[4], kernel[7], kernel[3], kernel[6] };
    set_next_pixel(Coord{ .x = maxX, .y = 0 }, avg_pixels(@constCast(&corner_coords), @constCast(&cornerKernel)));
    // bottom-left
    corner_coords = [4]Coord{
        .{ .x = 0, .y = maxY },
        .{ .x = 0, .y = maxY - 1 },
        .{ .x = 1, .y = maxY },
        .{ .x = 1, .y = maxY - 1 }
    };
    cornerKernel = [_]f32{ kernel[4], kernel[1], kernel[5], kernel[2] };
    set_next_pixel(Coord{ .x = 0, .y = maxY }, avg_pixels(@constCast(&corner_coords), @constCast(&cornerKernel)));
    // bottom-right
    corner_coords = [4]Coord{
        .{ .x = maxX, .y = maxY },
        .{ .x = maxX, .y = maxY - 1 },
        .{ .x = maxX - 1, .y = maxY },
        .{ .x = maxX - 1, .y = maxY - 1 }
    };
    cornerKernel = [_]f32{ kernel[4], kernel[1], kernel[3], kernel[0] };
    set_next_pixel(Coord{ .x = maxX, .y = maxY}, avg_pixels(@constCast(&corner_coords), @constCast(&cornerKernel)));

    // edges
    // top & bottom
    var topKernel = [_]f32{ kernel[3], kernel[4], kernel[5], kernel[6], kernel[7], kernel[8] };
    var bottomKernel = [_]f32{ kernel[0], kernel[1], kernel[2], kernel[3], kernel[4], kernel[5] };
    for (1..maxX) |c_idx| {
        var edge_coords = [6]Coord{
            .{ .x = c_idx - 1, .y = 0 },
            .{ .x = c_idx, .y = 0 },
            .{ .x = c_idx + 1, .y = 0 },
            .{ .x = c_idx - 1, .y = 1 },
            .{ .x = c_idx, .y = 1 },
            .{ .x = c_idx + 1, .y = 1 }
        };
        set_next_pixel(Coord{ .x = c_idx, .y = 0}, avg_pixels(@constCast(&edge_coords), @constCast(&topKernel)));
        edge_coords = [6]Coord{
            .{ .x = c_idx - 1, .y = maxY - 1 },
            .{ .x = c_idx, .y = maxY - 1 },
            .{ .x = c_idx + 1, .y = maxY - 1 },
            .{ .x = c_idx - 1, .y = maxY },
            .{ .x = c_idx, .y = maxY },
            .{ .x = c_idx + 1, .y = maxY }
        };
        set_next_pixel(Coord{ .x = c_idx, .y = maxY}, avg_pixels(@constCast(&edge_coords), @constCast(&bottomKernel)));
    }
    // left & right
    var leftKernel = [_]f32{ kernel[3], kernel[4], kernel[5], kernel[6], kernel[7], kernel[8] };
    var rightKernel = [_]f32{ kernel[0], kernel[1], kernel[2], kernel[3], kernel[4], kernel[5] };
    for (1..maxY) |r_idx| {
        var edge_coords = [6]Coord{
            .{ .x = 0, .y = r_idx - 1 },
            .{ .x = 0, .y = r_idx },
            .{ .x = 0, .y = r_idx + 1 },
            .{ .x = 1, .y = r_idx - 1 },
            .{ .x = 1, .y = r_idx },
            .{ .x = 1, .y = r_idx + 1 }
        };
        set_next_pixel(Coord{ .x = 0, .y = r_idx}, avg_pixels(@constCast(&edge_coords), @constCast(&leftKernel)));
        edge_coords = [6]Coord{
            .{ .x = maxX - 1, .y = r_idx - 1 },
            .{ .x = maxX - 1, .y = r_idx },
            .{ .x = maxX - 1, .y = r_idx + 1 },
            .{ .x = maxX, .y = r_idx - 1 },
            .{ .x = maxX, .y = r_idx },
            .{ .x = maxX, .y = r_idx + 1 }
        };
        set_next_pixel(Coord{ .x = maxX, .y = r_idx}, avg_pixels(@constCast(&edge_coords), @constCast(&rightKernel)));
    }

    // middle part
    for(1..maxY) |r_idx| {
        for(1..maxX) |c_idx| {
            const coords = [9]Coord{
                .{ .y = r_idx - 1, .x = c_idx - 1},
                .{ .y = r_idx - 1, .x = c_idx},
                .{ .y = r_idx - 1, .x = c_idx + 1},
                .{ .y = r_idx, .x = c_idx - 1},
                .{ .y = r_idx, .x = c_idx},
                .{ .y = r_idx, .x = c_idx + 1},
                .{ .y = r_idx + 1, .x = c_idx - 1},
                .{ .y = r_idx + 1, .x = c_idx},
                .{ .y = r_idx + 1, .x = c_idx + 1}
            };
            set_next_pixel(Coord{ .x = c_idx, .y = r_idx}, avg_pixels(@constCast(&coords), kernel));
        }
    }

    swap_states();
}

export fn blur() void {
    const kernel = [_]f32{
        0.1, 0.1, 0.1,
        0.1, 0.2, 0.1,
        0.1, 0.1, 0.1
    };

    convolution(@constCast(&kernel));
}

export fn sharpen() void {
    const kernel = [_]f32{
        0.0, -1.0, 0.0,
        -1.0, 5.0, -1.0,
        0.0, -1.0, 0.0
    };

    convolution(@constCast(&kernel));
}

export fn edge_detection() void {
    const kernel = [_]f32{
        -1.0, -1.0, -1.0,
        -1.0, 8.0, -1.0,
        -1.0, -1.0, -1.0
    };

    convolution(@constCast(&kernel));
}


export fn emboss() void {
    const kernel = [_]f32{
        -2.0, -1.0, 0.0,
        -1.0, 1.0, 1.0,
        0.0, 1.0, 2.0
    };

    convolution(@constCast(&kernel));
}

export fn motion_blur() void {
    const kernel = [_]f32{
        0.33, 0.0, 0.0,
        0.34, 0.0, 0.0,
        0.33, 0.0, 0.0
    };

    convolution(@constCast(&kernel));
}

export fn edge_detection_perwitt_horizontal() void {
    const kernel = [_]f32{
        -1.0, 0.0, 1.0,
        -1.0, 0.0, 1.0,
        -1.0, 0.0, 1.0
    };

    convolution(@constCast(&kernel));
}

export fn edge_detection_perwitt_vertical() void {
    const kernel = [_]f32{
        -1.0, -1.0, -1.0,
        0.0, 0.0, 0.0,
        1.0, 1.0, 1.0
    };

    convolution(@constCast(&kernel));
}

export fn edge_detection_sobel_horizontal() void {
    const kernel = [_]f32{
        -1.0, 0.0, 1.0,
        -2.0, 0.0, 2.0,
        -1.0, 0.0, 1.0
    };

    convolution(@constCast(&kernel));
}

export fn edge_detection_sobel_vertical() void {
    const kernel = [_]f32{
        -1.0, -2.0, -1.0,
        0.0, 0.0, 0.0,
        1.0, 2.0, 1.0
    };

    convolution(@constCast(&kernel));
}

fn rgb_to_hsl(rgb_pixel: RgbPixel) HslPixel {
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

fn hsl_to_rgb(hsl_pixel: HslPixel) RgbPixel {
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

    return RgbPixel{
        .r = @intFromFloat(r),
        .g = @intFromFloat(g),
        .b = @intFromFloat(b),
        .a = hsl_pixel.a
    };
}

export fn rotate_hue_by_10_deg() void {
    var idx: u32 = 0;
    while (idx < current_state.data.len) : (idx += 4) {
        const r = current_state.data[idx];
        const g = current_state.data[idx + 1];
        const b = current_state.data[idx + 2];
        const a = current_state.data[idx + 3];

        var hsla = rgb_to_hsl(RgbPixel{
            .r = r,
            .g = g,
            .b = b,
            .a = a
        });
        hsla.h = @mod(hsla.h + 10, 360.0);

        const newRgba = hsl_to_rgb(hsla);

        next_state.data[idx] = newRgba.r;
        next_state.data[idx + 1] = newRgba.g;
        next_state.data[idx + 2] = newRgba.b;
        next_state.data[idx + 3] = newRgba.a;
    }
    swap_states();
}
