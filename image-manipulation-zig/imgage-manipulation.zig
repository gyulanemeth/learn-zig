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

fn avgPixels(pixelCoords: []Coord) Pixel {
    var avgR: u16 = 0;
    var avgG: u16 = 0;
    var avgB: u16 = 0;
    var avgA: u16 = 0;

    for (pixelCoords) |coord| {
        const actPixel = get_pixel(coord.y, coord.x);
        avgR += @intCast(actPixel.r);
        avgG += @intCast(actPixel.g);
        avgB += @intCast(actPixel.b);
        avgA += @intCast(actPixel.a);
    }

    avgR /= @intCast(pixelCoords.len);
    avgG /= @intCast(pixelCoords.len);
    avgB /= @intCast(pixelCoords.len);
    avgA /= @intCast(pixelCoords.len);

    return Pixel{
        .r = @intCast(avgR),
        .g = @intCast(avgG),
        .b = @intCast(avgB),
        .a = @intCast(avgA)
    };
}

export fn blur() void {
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
    set_next_pixel(Coord{ .x = 0, .y = 0}, avgPixels(@constCast(&corner_coords)));
    // top-right
    corner_coords = [4]Coord{
        .{ .x = maxX, .y = 0 },
        .{ .x = maxX, .y = 1 },
        .{ .x = maxX - 1, .y = 0 },
        .{ .x = maxX - 1, .y = 1 }
    };
    set_next_pixel(Coord{ .x = maxX, .y = 0 }, avgPixels(@constCast(&corner_coords)));
    // bottom-left
    corner_coords = [4]Coord{
        .{ .x = 0, .y = maxY },
        .{ .x = 0, .y = maxY - 1 },
        .{ .x = 1, .y = maxY },
        .{ .x = 1, .y = maxY - 1 }
    };
    set_next_pixel(Coord{ .x = 0, .y = maxY }, avgPixels(@constCast(&corner_coords)));
    // bottom-right
    corner_coords = [4]Coord{
        .{ .x = maxX, .y = maxY },
        .{ .x = maxX, .y = maxY - 1 },
        .{ .x = maxX - 1, .y = maxY },
        .{ .x = maxX - 1, .y = maxY - 1 }
    };
    set_next_pixel(Coord{ .x = maxX, .y = maxY}, avgPixels(@constCast(&corner_coords)));

    // edges
    // top & bottom
    for (1..maxX) |c_idx| {
        var edge_coords = [6]Coord{
            .{ .x = c_idx - 1, .y = 0 },
            .{ .x = c_idx, .y = 0 },
            .{ .x = c_idx + 1, .y = 0 },
            .{ .x = c_idx - 1, .y = 1 },
            .{ .x = c_idx, .y = 1 },
            .{ .x = c_idx + 1, .y = 1 }
        };
        set_next_pixel(Coord{ .x = c_idx, .y = 0}, avgPixels(@constCast(&edge_coords)));
        edge_coords = [6]Coord{
            .{ .x = c_idx - 1, .y = maxY },
            .{ .x = c_idx, .y = maxY },
            .{ .x = c_idx + 1, .y = maxY },
            .{ .x = c_idx - 1, .y = maxY - 1 },
            .{ .x = c_idx, .y = maxY - 1 },
            .{ .x = c_idx + 1, .y = maxY - 1 }
        };
        set_next_pixel(Coord{ .x = c_idx, .y = maxY}, avgPixels(@constCast(&edge_coords)));
    }
    // left & right
    for (1..maxY) |r_idx| {
        var edge_coords = [6]Coord{
            .{ .x = 0, .y = r_idx - 1 },
            .{ .x = 0, .y = r_idx },
            .{ .x = 0, .y = r_idx + 1 },
            .{ .x = 1, .y = r_idx - 1 },
            .{ .x = 1, .y = r_idx },
            .{ .x = 1, .y = r_idx + 1 }
        };
        set_next_pixel(Coord{ .x = 0, .y = r_idx}, avgPixels(@constCast(&edge_coords)));
        edge_coords = [6]Coord{
            .{ .x = maxX, .y = r_idx - 1 },
            .{ .x = maxX, .y = r_idx },
            .{ .x = maxX, .y = r_idx + 1 },
            .{ .x = maxX - 1, .y = r_idx - 1 },
            .{ .x = maxX - 1, .y = r_idx },
            .{ .x = maxX - 1, .y = r_idx + 1 }
        };
        set_next_pixel(Coord{ .x = maxX, .y = r_idx}, avgPixels(@constCast(&edge_coords)));
    }

    // middle part
    for(1..maxY) |r_idx| {
        for(1..maxX) |c_idx| {
            const coords = [9]Coord{
                .{ .x = c_idx - 1, .y = r_idx - 1},
                .{ .x = c_idx - 1, .y = r_idx},
                .{ .x = c_idx - 1, .y = r_idx + 1},
                .{ .x = c_idx, .y = r_idx - 1},
                .{ .x = c_idx, .y = r_idx},
                .{ .x = c_idx, .y = r_idx + 1},
                .{ .x = c_idx + 1, .y = r_idx - 1},
                .{ .x = c_idx + 1, .y = r_idx},
                .{ .x = c_idx + 1, .y = r_idx + 1}
            };
            set_next_pixel(Coord{ .x = c_idx, .y = r_idx}, avgPixels(@constCast(&coords)));
        }
    }

    swap_states();
    draw_pixels();
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
