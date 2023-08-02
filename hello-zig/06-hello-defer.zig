const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;

test "defer value test" {
    var x: i16 = 5;
    {
        defer x += 2;
        try expect(x == 5);
    }
    try expect(x == 7);
}
