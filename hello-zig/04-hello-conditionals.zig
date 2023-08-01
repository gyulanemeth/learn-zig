const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;

pub fn main() void {
    const rand = std.crypto.random;
    const fullRandom = rand.int(u8);

    if (fullRandom % 2 == 1) {
        print("This number is odd: {}\n", .{fullRandom});
    } else {
        print("This number is even: {}\n", .{fullRandom});
    }
}
