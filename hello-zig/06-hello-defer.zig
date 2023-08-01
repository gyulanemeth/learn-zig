const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;

test "fibonacci recursion" {
    var x: i16 = 5;
    {
        defer x += 2;
        try expect(x == 5);
    }
}
