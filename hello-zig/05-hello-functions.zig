const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;

fn fibonacci(n: u16) u16 {
    if (n == 0 or n == 1) {
        return n;
    }

    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "fibonacci recursion" {
    var x = fibonacci(3);
    try expect(x == 2);
    x = fibonacci(6);
    try expect(x == 8);
}
