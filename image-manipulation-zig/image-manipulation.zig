const std = @import("std");

const convert = @import("./convert.zig");

const RgbPixel = convert.RgbPixel;
const HslPixel = convert.HslPixel;
const rgb_to_hsl = convert.rgb_to_hsl;
const hsl_to_rgb = convert.hsl_to_rgb;

extern fn debug(r_idx: usize, c_idx: usize) void;

var full_state: ImageData = undefined;
var state_1: ImageData = undefined;
var state_2: ImageData = undefined;

var current_state: ImageData = undefined;
var next_state: ImageData = undefined;

export fn init(height: u32, width: u32) callconv(.C) [*]u8 {
    const num_color_values = height * width * 4; // 4x -> r, g, b, a;
    const memory_size = num_color_values * 2; // 2x -> current_state, next_state
    var memory = std.heap.wasm_allocator.alloc(u8, memory_size) catch unreachable;

    var selection = std.heap.wasm_allocator.alloc(u8, height * width);

    full_state = ImageData{ .height = height, .width = width, .data = memory };
    state_1 = ImageData{ .height = full_state.height, .width = full_state.width, .data = full_state.data[0..num_color_values] };
    state_2 = ImageData{ .height = full_state.height, .width = full_state.width, .data = full_state.data[num_color_values..] };

    current_state = state_1;
    next_state = state_2;

    selection = SelectionData{ .width = full_state.width, .height = full_state.height, .selection = selection[0 .. width * height] };

    return memory.ptr;
}

export fn currentImgAddress() callconv(.C) [*]u8 {
    return current_state.data.ptr;
}

export fn selectionAddress() callconv(.C) [*]u8 {
    return selection.selection.ptr;
}

export fn destroy() void {
    std.heap.wasm_allocator.free(full_state.data);
}

fn swap_states() void {
    var tmp = current_state;
    current_state = next_state;
    next_state = tmp;
}
