const ImageData = @import("./ImageData.zig");

pub fn invert(current_img: ImageData, next_img: ImageData, swap_states: *const fn () void) void {
    var idx: u32 = 0;
    while (idx < current_img.data.len) : (idx += 4) {
        next_img.data[idx] = 255 - current_img.data[idx];
        next_img.data[idx + 1] = 255 - current_img.data[idx + 1];
        next_img.data[idx + 2] = 255 - current_img.data[idx + 2];
        next_img.data[idx + 3] = current_img.data[idx + 3];
    }
    swap_states();
}

pub fn to_grayscale(current_img: ImageData, next_img: ImageData, swap_states: *const fn () void) void {
    var idx: u32 = 0;
    while (idx < current_img.data.len) : (idx += 4) {
        const r: u16 = @intCast(current_img.data[idx]);
        const g: u16 = @intCast(current_img.data[idx + 1]);
        const b: u16 = @intCast(current_img.data[idx + 2]);

        const avg: u16 = (r + g + b) / 3;
        const avg8: u8 = @intCast(avg);

        next_img.data[idx] = avg8;
        next_img.data[idx + 1] = avg8;
        next_img.data[idx + 2] = avg8;
        next_img.data[idx + 3] = current_img.data[idx + 3];
    }
    swap_states();
}

fn avg_pixels(current_img: ImageData, pixelCoords: []Coord, kernel: []f32) RgbPixel {
    var avgR: f32 = 0;
    var avgG: f32 = 0;
    var avgB: f32 = 0;
    var avgA: u8 = 255; // 255 alpha is temporal

    for (pixelCoords, 0..) |coord, idx| {
        const actRgbPixel: RgbPixel = current_img.get_pixel(coord);
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

    return RgbPixel{ .r = r, .g = g, .b = b, .a = avgA };
}

pub fn convolution(current_img: ImageData, next_img: ImageData, kernel: []f32, swap_states: *const fn () void) void {
    const maxX = current_state.n_cols - 1;
    const maxY = current_state.n_rows - 1;

    // corners
    // top-left
    var corner_coords = [4]Coord{ .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 0 }, .{ .x = 1, .y = 1 } };
    var cornerKernel = [_]f32{ kernel[4], kernel[7], kernel[5], kernel[8] };
    next_img.set_pixel(Coord{ .x = 0, .y = 0 }, avg_pixels(current_img, @constCast(&corner_coords), @constCast(&cornerKernel)));
    // top-right
    corner_coords = [4]Coord{ .{ .x = maxX, .y = 0 }, .{ .x = maxX, .y = 1 }, .{ .x = maxX - 1, .y = 0 }, .{ .x = maxX - 1, .y = 1 } };
    cornerKernel = [_]f32{ kernel[4], kernel[7], kernel[3], kernel[6] };
    next_img.set_pixel(Coord{ .x = maxX, .y = 0 }, avg_pixels(current_img, @constCast(&corner_coords), @constCast(&cornerKernel)));
    // bottom-left
    corner_coords = [4]Coord{ .{ .x = 0, .y = maxY }, .{ .x = 0, .y = maxY - 1 }, .{ .x = 1, .y = maxY }, .{ .x = 1, .y = maxY - 1 } };
    cornerKernel = [_]f32{ kernel[4], kernel[1], kernel[5], kernel[2] };
    next_img.set_pixel(Coord{ .x = 0, .y = maxY }, avg_pixels(current_img, @constCast(&corner_coords), @constCast(&cornerKernel)));
    // bottom-right
    corner_coords = [4]Coord{ .{ .x = maxX, .y = maxY }, .{ .x = maxX, .y = maxY - 1 }, .{ .x = maxX - 1, .y = maxY }, .{ .x = maxX - 1, .y = maxY - 1 } };
    cornerKernel = [_]f32{ kernel[4], kernel[1], kernel[3], kernel[0] };
    next_img.set_pixel(Coord{ .x = maxX, .y = maxY }, avg_pixels(current_img, @constCast(&corner_coords), @constCast(&cornerKernel)));

    // edges
    // top & bottom
    var topKernel = [_]f32{ kernel[3], kernel[4], kernel[5], kernel[6], kernel[7], kernel[8] };
    var bottomKernel = [_]f32{ kernel[0], kernel[1], kernel[2], kernel[3], kernel[4], kernel[5] };
    for (1..maxX) |c_idx| {
        var edge_coords = [6]Coord{ .{ .x = c_idx - 1, .y = 0 }, .{ .x = c_idx, .y = 0 }, .{ .x = c_idx + 1, .y = 0 }, .{ .x = c_idx - 1, .y = 1 }, .{ .x = c_idx, .y = 1 }, .{ .x = c_idx + 1, .y = 1 } };
        next_img.set_pixel(Coord{ .x = c_idx, .y = 0 }, avg_pixels(current_img, @constCast(&edge_coords), @constCast(&topKernel)));
        edge_coords = [6]Coord{ .{ .x = c_idx - 1, .y = maxY - 1 }, .{ .x = c_idx, .y = maxY - 1 }, .{ .x = c_idx + 1, .y = maxY - 1 }, .{ .x = c_idx - 1, .y = maxY }, .{ .x = c_idx, .y = maxY }, .{ .x = c_idx + 1, .y = maxY } };
        next_img.set_pixel(Coord{ .x = c_idx, .y = maxY }, avg_pixels(current_img, @constCast(&edge_coords), @constCast(&bottomKernel)));
    }
    // left & right
    var leftKernel = [_]f32{ kernel[3], kernel[4], kernel[5], kernel[6], kernel[7], kernel[8] };
    var rightKernel = [_]f32{ kernel[0], kernel[1], kernel[2], kernel[3], kernel[4], kernel[5] };
    for (1..maxY) |r_idx| {
        var edge_coords = [6]Coord{ .{ .x = 0, .y = r_idx - 1 }, .{ .x = 0, .y = r_idx }, .{ .x = 0, .y = r_idx + 1 }, .{ .x = 1, .y = r_idx - 1 }, .{ .x = 1, .y = r_idx }, .{ .x = 1, .y = r_idx + 1 } };
        next_img.set_pixel(Coord{ .x = 0, .y = r_idx }, avg_pixels(current_img, @constCast(&edge_coords), @constCast(&leftKernel)));
        edge_coords = [6]Coord{ .{ .x = maxX - 1, .y = r_idx - 1 }, .{ .x = maxX - 1, .y = r_idx }, .{ .x = maxX - 1, .y = r_idx + 1 }, .{ .x = maxX, .y = r_idx - 1 }, .{ .x = maxX, .y = r_idx }, .{ .x = maxX, .y = r_idx + 1 } };
        next_img.set_pixel(Coord{ .x = maxX, .y = r_idx }, avg_pixels(current_img, @constCast(&edge_coords), @constCast(&rightKernel)));
    }

    // middle part
    for (1..maxY) |r_idx| {
        for (1..maxX) |c_idx| {
            const coords = [9]Coord{ .{ .y = r_idx - 1, .x = c_idx - 1 }, .{ .y = r_idx - 1, .x = c_idx }, .{ .y = r_idx - 1, .x = c_idx + 1 }, .{ .y = r_idx, .x = c_idx - 1 }, .{ .y = r_idx, .x = c_idx }, .{ .y = r_idx, .x = c_idx + 1 }, .{ .y = r_idx + 1, .x = c_idx - 1 }, .{ .y = r_idx + 1, .x = c_idx }, .{ .y = r_idx + 1, .x = c_idx + 1 } };
            next_img.set_pixel(Coord{ .x = c_idx, .y = r_idx }, avg_pixels(current_img, @constCast(&coords), kernel));
        }
    }

    swap_states();
}

pub const kernels: [_][9]f32 {
  [_]f32{ 0.1, 0.1, 0.1, 0.1, 0.2, 0.1, 0.1, 0.1, 0.1 }, // blur
  [_]f32{ 0.0, -1.0, 0.0, -1.0, 5.0, -1.0, 0.0, -1.0, 0.0 }, // sharpen
  [_]f32{ -1.0, -1.0, -1.0, -1.0, 8.0, -1.0, -1.0, -1.0, -1.0 }, // edge_detection
  [_]f32{ -2.0, -1.0, 0.0, -1.0, 1.0, 1.0, 0.0, 1.0, 2.0 }, // emboss
  [_]f32{ 0.33, 0.0, 0.0, 0.34, 0.0, 0.0, 0.33, 0.0, 0.0 }, // motion blur
  [_]f32{ -1.0, 0.0, 1.0, -1.0, 0.0, 1.0, -1.0, 0.0, 1.0 }, // edge_detection_perwitt_horizontal
  [_]f32{ -1.0, -1.0, -1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0 }, // edge_detection_perwitt_vertical
  [_]f32{ -1.0, 0.0, 1.0, -2.0, 0.0, 2.0, -1.0, 0.0, 1.0 }, // edge_detection_sobel_horizontal
  [_]f32{ -1.0, -2.0, -1.0, 0.0, 0.0, 0.0, 1.0, 2.0, 1.0 } // edge_detection_sobel_vertical
}

pub const ConvolutionKernels = enum {
  blur,
  sharpen,
  edge_detection,
  emboss,
  motion_blur,
  edge_detection_perwitt_horizontal,
  edge_detection_perwitt_vertical,
  edge_detection_sobel_horizontal,
  edge_detection_sobel_vertical
};
