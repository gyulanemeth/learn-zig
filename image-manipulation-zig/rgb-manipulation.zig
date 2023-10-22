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
