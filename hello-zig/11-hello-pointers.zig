const std = @import("std");
const expect = std.testing.expect;

fn increment(num: *u8) void {
    num.* += 1;
}

test "pointers" {
    var x: u8 = 1;
    increment(&x);
    try expect(x == 2);
}

test "naughty pointer" {
    var x: u16 = 0;
    var y: *u8 = @intToPtr(*u8, x);
    _ = y;
}

test "const pointers" {
    const x: u8 = 1;
    var y = &x;
    y.* += 1;
}
