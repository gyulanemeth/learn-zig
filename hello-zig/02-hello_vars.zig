const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const myConst: u32 = 2;
    var myVar: i32 = 4;

    print("myConst: {}, myVar: {}", .{myConst, myVar});
}