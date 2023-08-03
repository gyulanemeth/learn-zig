const std = @import("std");
const expect = std.testing.expect;

fn asciiToUpper(x: u8) u8 {
    return switch (x) {
        'a'...'z' => x + 'A' - 'a',
        'A'...'Z' => x,
        else => unreachable,
    };
}

test "unreachable" {
    try expect(asciiToUpper('b') == 'B');
    try expect(asciiToUpper('C') == 'C');
}
