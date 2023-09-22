const std = @import("std");

extern fn swapIfNeeded(array: [*]i32, idx1: usize, idx2: usize) callconv(.C) void;
extern fn logRef(arr: [*]i32) callconv(.C) void;
extern fn logSol(arr: [*]i32) callconv(.C) void;

var arraySol = [_]i32{ 5, 2, 1, 3, 4 };
var arrayRef = [_]i32{ 5, 2, 1, 3, 4 };

fn areTheSame() bool {
    for (arrayRef, 0..) |act, idx| {
        if (act != arraySol[idx]) {
            return false;
        }
    }
    return true;
}

fn swapIfNeededRef(idx1: usize, idx2: usize) bool {
    if (arrayRef[idx1] > arrayRef[idx2]) {
        const temp = arrayRef[idx1];
        arrayRef[idx1] = arrayRef[idx2];
        arrayRef[idx2] = temp;

        return true;
    }
    return false;
}

export fn logArrays() void {
    logRef(&arrayRef);
    logSol(&arraySol);
}

export fn sort() bool {
    var idx_outer: usize = arrayRef.len;
    while(idx_outer > 0) : (idx_outer -= 1) {
        var idx_inner: usize = 0;
        var swapped: bool = false;
        while (idx_inner < idx_outer - 1) : (idx_inner += 1) {
            swapped = swapIfNeededRef(idx_inner, idx_inner + 1) or swapped;
            swapIfNeeded(&arraySol, idx_inner, idx_inner + 1);

            logArrays();

            if (!areTheSame()) {
                return false;
            }
        }
        if (!swapped) {
            break;
        }
    }
    return true;
}
