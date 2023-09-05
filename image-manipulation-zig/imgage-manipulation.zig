const std = @import("std");

const ImageData = struct { n_rows: u32, n_cols: u32, data: []u8 };
const Pixel = struct { r: u8, g: u8, b: u8, a: u8 };
const Coord = struct { x: u32, y: u32 };

extern fn drawPixel(r_idx: usize, c_idx: usize, r: u8, g: u8, b: u8, a: u8) void;
extern fn drawPixelsDone() void;

var full_state: ImageData = undefined;
var state_1: ImageData = undefined;
var state_2: ImageData = undefined;

var current_state: ImageData = undefined;
var next_state: ImageData = undefined;

export fn init(n_rows: u32, n_cols: u32) void {
    const num_color_values = n_rows * n_cols * 4; // 4x -> r, g, b, a;
    const memory_size = num_color_values * 2; // 2x -> current_state, next_state
    var memory = std.heap.page_allocator.alloc(u8, memory_size) catch unreachable;

    full_state = ImageData{ .n_rows = n_rows, .n_cols = n_cols, .data = memory };
    state_1 = ImageData{ .n_rows = full_state.n_rows, .n_cols = full_state.n_cols, .data = full_state.data[0..num_color_values] };
    state_2 = ImageData{ .n_rows = full_state.n_rows, .n_cols = full_state.n_cols, .data = full_state.data[num_color_values..] };

    current_state = state_1;
    next_state = state_2;
}

export fn destroy() void {
    std.heap.page_allocator.free(full_state.data);
}

fn swap_states() void {
    var tmp = current_state;
    current_state = next_state;
    next_state = tmp;
}

fn get_pixel(r_idx: usize, c_idx: usize) Pixel {
    const red_idx = (r_idx * current_state.n_cols + c_idx) * 4;

    return Pixel{
        .r = current_state.data[red_idx],
        .g = current_state.data[red_idx + 1],
        .b = current_state.data[red_idx + 2],
        .a = current_state.data[red_idx + 3]
    };
}

export fn set_pixel(r_idx: usize, c_idx: usize, r: u8, g: u8, b: u8, a: u8) void {
    const red_idx = (r_idx * current_state.n_cols + c_idx) * 4;
    current_state.data[red_idx] = r;
    current_state.data[red_idx + 1] = g;
    current_state.data[red_idx + 2] = b;
    current_state.data[red_idx + 3] = a;
}

fn set_next_pixel(coord: Coord, pixel: Pixel) void {
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
    }
    swap_states();
    draw_pixels();
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
    }
    swap_states();
    draw_pixels();
}

fn avgPixels(pixelCoords: []Coord, kernel: []f32) Pixel {
    var avgR: f32 = 0;
    var avgG: f32 = 0;
    var avgB: f32 = 0;
    var avgA: u16 = 255; // 255 alpha is temporal

    for (pixelCoords, 0..) |coord, idx| {
        const actPixel: Pixel = get_pixel(coord.y, coord.x);
        const actKernel = kernel[idx];

        const actR: f32 = @floatFromInt(actPixel.r);
        const actG: f32 = @floatFromInt(actPixel.g);
        const actB: f32 = @floatFromInt(actPixel.b);

        avgR += actR * actKernel;
        avgG += actG * actKernel;
        avgB += actB * actKernel;
    }

    if (avgR < 0) {
        avgR = 0.0;
    } else if (avgR > 255) {
        avgR = 255.0;
    }

    if (avgG < 0) {
        avgG = 0.0;
    } else if (avgG > 255) {
        avgG = 255.0;
    }

    if (avgB < 0) {
        avgB = 0.0;
    } else if (avgB > 255) {
        avgB = 255.0;
    }

    return Pixel{
        .r = @intFromFloat(avgR),
        .g = @intFromFloat(avgG),
        .b = @intFromFloat(avgB),
        .a = @intCast(avgA)
    };
}

fn convolution(kernel: []f32) void {
    const maxX = current_state.n_rows - 1;
    const maxY = current_state.n_cols - 1;

    // corners
    // top-left
    var corner_coords = [4]Coord{
        .{ .x = 0, .y = 0 },
        .{ .x = 0, .y = 1 },
        .{ .x = 1, .y = 0 },
        .{ .x = 1, .y = 1 }
    };
    var cornerKernel = [_]f32{ kernel[4], kernel[7], kernel[5], kernel[8] };
    set_next_pixel(Coord{ .x = 0, .y = 0}, avgPixels(@constCast(&corner_coords), @constCast(&cornerKernel)));
    // top-right
    corner_coords = [4]Coord{
        .{ .x = maxX, .y = 0 },
        .{ .x = maxX, .y = 1 },
        .{ .x = maxX - 1, .y = 0 },
        .{ .x = maxX - 1, .y = 1 }
    };
    cornerKernel = [_]f32{ kernel[4], kernel[7], kernel[3], kernel[6] };
    set_next_pixel(Coord{ .x = maxX, .y = 0 }, avgPixels(@constCast(&corner_coords), @constCast(&cornerKernel)));
    // bottom-left
    corner_coords = [4]Coord{
        .{ .x = 0, .y = maxY },
        .{ .x = 0, .y = maxY - 1 },
        .{ .x = 1, .y = maxY },
        .{ .x = 1, .y = maxY - 1 }
    };
    cornerKernel = [_]f32{ kernel[4], kernel[1], kernel[5], kernel[2] };
    set_next_pixel(Coord{ .x = 0, .y = maxY }, avgPixels(@constCast(&corner_coords), @constCast(&cornerKernel)));
    // bottom-right
    corner_coords = [4]Coord{
        .{ .x = maxX, .y = maxY },
        .{ .x = maxX, .y = maxY - 1 },
        .{ .x = maxX - 1, .y = maxY },
        .{ .x = maxX - 1, .y = maxY - 1 }
    };
    cornerKernel = [_]f32{ kernel[4], kernel[1], kernel[3], kernel[0] };
    set_next_pixel(Coord{ .x = maxX, .y = maxY}, avgPixels(@constCast(&corner_coords), @constCast(&cornerKernel)));

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
        set_next_pixel(Coord{ .x = c_idx, .y = 0}, avgPixels(@constCast(&edge_coords), @constCast(&topKernel)));
        edge_coords = [6]Coord{
            .{ .x = c_idx - 1, .y = maxY - 1 },
            .{ .x = c_idx, .y = maxY - 1 },
            .{ .x = c_idx + 1, .y = maxY - 1 },
            .{ .x = c_idx - 1, .y = maxY },
            .{ .x = c_idx, .y = maxY },
            .{ .x = c_idx + 1, .y = maxY }
        };
        set_next_pixel(Coord{ .x = c_idx, .y = maxY}, avgPixels(@constCast(&edge_coords), @constCast(&bottomKernel)));
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
        set_next_pixel(Coord{ .x = 0, .y = r_idx}, avgPixels(@constCast(&edge_coords), @constCast(&leftKernel)));
        edge_coords = [6]Coord{
            .{ .x = maxX - 1, .y = r_idx - 1 },
            .{ .x = maxX - 1, .y = r_idx },
            .{ .x = maxX - 1, .y = r_idx + 1 },
            .{ .x = maxX, .y = r_idx - 1 },
            .{ .x = maxX, .y = r_idx },
            .{ .x = maxX, .y = r_idx + 1 }
        };
        set_next_pixel(Coord{ .x = maxX, .y = r_idx}, avgPixels(@constCast(&edge_coords), @constCast(&rightKernel)));
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
            set_next_pixel(Coord{ .x = c_idx, .y = r_idx}, avgPixels(@constCast(&coords), kernel));
        }
    }

    swap_states();
    draw_pixels();
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

export fn draw_pixels() void {
    var idx: u32 = 0;
    while (idx < current_state.data.len) : (idx += 4) {
        const curr_pixel_values = current_state.data[idx .. idx + 4];

        const px_idx = idx / 4;
        const r_idx: usize = px_idx / current_state.n_cols;
        const c_idx: usize = @mod(px_idx, current_state.n_cols);
        drawPixel(r_idx, c_idx, curr_pixel_values[0], curr_pixel_values[1], curr_pixel_values[2], curr_pixel_values[3]);
    }
    drawPixelsDone();
}
