const std = @import("std");

// extern fn swapIfNeeded(array, idx1, idx2) void;


var arraySol = [_]i32{ 5, 2, 1, 3, 4 };
var arrayRef = [_]i32{ 5, 2, 1, 3, 4 };

fn check() bool {
    for (arrayRef, 0..) |act, idx| {
        if (act != arraySol[idx]) {
            return false;
        }
    }
    return true;
}

fn swapIfNeededRef(idx1: usize, idx2: usize) void {
    if (arrayRef[idx1] > arrayRef[idx2]) {
        const temp = arrayRef[idx1];
        arrayRef[idx1] = arrayRef[idx2];
        arrayRef[idx2] = temp;
    }
}

fn printArrayRef() void {
    for(arrayRef) |item| {
        std.debug.print("{d} ", .{ item });
    }
    std.debug.print("\n", .{});
}

fn sort() void {
    var idx_outer: usize = arrayRef.len;
    while(idx_outer > 0) : (idx_outer -= 1) {
        var idx_inner: usize = 0;
        while (idx_inner < idx_outer - 1) : (idx_inner += 1) {
            swapIfNeededRef(idx_inner, idx_inner + 1);
            printArrayRef();
        }
    }
}

pub fn main() void {
    std.debug.print("Original\n", .{});
    printArrayRef();
    std.debug.print("Start\n", .{});
    sort();
    std.debug.print("End\n", .{});
}