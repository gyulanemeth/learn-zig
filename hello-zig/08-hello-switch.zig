const std = @import("std");
const expect = std.testing.expect;

test "switch statement" {
    var x: i16 = 100;

    switch (x) {
        -1...1 => {
            x = -x;
        },
        10, 100 => {
            x = @divExact(x, 10);
        },
        else => {},
    }

    try expect(x == 10);
}

test "switch expression" {
    const x: i16 = 10;

    var y = switch (x) {
        -1...1 => -x,
        10, 100 => @divExact(x, 10),
        else => x,
    };

    try expect(y == 1);
}
