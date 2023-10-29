const std = @import("std");

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

pub fn addToSelectionBasedOnHslRange() void {}

pub fn dilate() void {}
