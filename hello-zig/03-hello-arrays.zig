const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const myArray = [5]u8{'h', 'e', 'l', 'l', 'o'};
    const myArray2 = [_]u8{'w', 'o', 'r', 'l', 'd'};

    print("myArray.length: {}, myArray2.lenght: {}\n", .{myArray.len, myArray2.len});

    var i: u8 = 0;
    while (i < myArray.len) {
        print("{c}", .{myArray[i]});
        i = i + 1;
    }
    print("\n", .{});

    for (myArray2) |character, index| {
        print("{c} - {}\n", .{character, index});
    }
    print("\n", .{});
}