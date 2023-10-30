const std = @import("std");
const ArrayList = std.ArrayList;

const convert = @import("./convert.zig");

const RgbPixel = convert.RgbPixel;
const HslPixel = convert.HslPixel;
const rgb_to_hsl = convert.rgb_to_hsl;
const hsl_to_rgb = convert.hsl_to_rgb;

const SelectionData = struct { width: u32, height: u32, data: []u8 };

pub const selection: SelectionData = undefined;

pub fn init(width: u32, height: u32) void {
    const length = height * width;
    var data = std.heap.wasm_allocator.alloc(u8, length);

    selection = SelectionData{ .width = width, .height = height, .data = data };
}

pub fn deinit() void {
    std.heap.wasm_allocator.free(selection.data);
}

pub fn selectAll() void {
    for (selection.data, 0..) |value, idx| {
        selection.data[idx] = 1;
    }
}

pub fn deselectAll() void {
    for (selection.data, 0..) |value, idx| {
        selection.data[idx] = 0;
    }
}

pub fn invert() void {
    for (selection.data, 0..) |value, idx| {
        selection.data[idx] = 1 - value;
    }
}

pub fn rectangularSelection(from: Coord, to: Coord) void {
    const fromY = @min(from.y, to.y, 0);
    const toY = @max(from.y, to.y, selection.height - 1);

    const fromX = @min(from.x, to.x, 0);
    const toX = @max(from.x, to.x, selection.width - 1);

    var yIdx = fromY;
    while (yIdx <= toY) : (yIdx += 1) {
        var xIdx = fromX;
        while (xIdx <= toX) : (xIdx += 1) {
            selection.data[yIdx * selection.width + xIdx] = 1;
        }
    }
}

pub fn setSelectionBasedOnHslRange(img: ImageData, coord: Coord, range: HslPixel, value: u8) void {
    const rgb_start_px = img.get_pixel(coord);
    const hsl_start_px = rgb_to_hsl(rgb_start_px);

    const h_min = hsl_start_px.hue - range.hue;
    const h_max = hsl_start_px.hue + range.hue;
    const l_min = hsl_start_px.l - range.l;
    const l_max = hsl_start_px.l + range.l;
    const s_min = hsl_start_px.s - range.s;
    const s_max = hsl_start_px.s + range.s;

    const visited = std.heap.wasm_allocator.alloc(u8, img.width * img.height);
    defer std.heap.wasm_allocator.free(visited);

    const coors_to_visit = ArrayList(Coord).init(std.heap.wasm_allocator);
    defer coors_to_visit.deinit();

    coors_to_visit.append(coord);

    while (coors_to_visit.items.len > 0) {
        const act_coord = coors_to_visit.pop();

        if (act_coord.x < 0 || act_coord.y < 0) {
          continue;
        }

        if (act_coord.x >= img.width || act_coord.y >= img.height) {
          continue;
        }

        if (visited[act_coord.y * img.width + act_coord.x] == 1) {
          continue;
        }

        visited[act_coord.y * img.width + act_coord.x] = 1;

        const act_rgb = img.get_pixel(act_coord);
        const act_hsl = rgb_to_hsl(act_rgb);

        if (act_hsl.h < h_min) {
          continue;
        }

        if (act_hsl.h > h_max) {
          continue;
        }

        if (act_hsl.l < l_min) {
          continue;
        }

        if (act_hsl.l > l_max) {
          continue;
        }

        if (act_hsl.s < s_min) {
          continue;
        }

        if (act_hsl.s > s_max) {
          continue;
        }

        selection[act_coord.y * img.width + act_coord.x] = 1;

        coords_to_visit.append(Coord{ .y = act_coord.y - 1, .x = act_coord.x - 1 })
        coords_to_visit.append(Coord{ .y = act_coord.y - 1, .x = act_coord.x })
        coords_to_visit.append(Coord{ .y = act_coord.y - 1, .x = act_coord.x + 1 })

        coords_to_visit.append(Coord{ .y = act_coord.y, .x = act_coord.x - 1 })
        coords_to_visit.append(Coord{ .y = act_coord.y, .x = act_coord.x + 1 })

        coords_to_visit.append(Coord{ .y = act_coord.y + 1, .x = act_coord.x - 1 })
        coords_to_visit.append(Coord{ .y = act_coord.y + 1, .x = act_coord.x })
        coords_to_visit.append(Coord{ .y = act_coord.y + 1, .x = act_coord.x + 1 })
    }
}

pub fn dilate() void {}
