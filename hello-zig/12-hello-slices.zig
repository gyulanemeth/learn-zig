const expect = @import("std").testing.expect;

fn total(values: []const u8) usize {
    var sum: usize = 0;
    for (values) |v| sum += v;
    return sum;
}

test "slices" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };
    const slice = array[0..3];
    try expect(total(slice) == 6);
    try expect(total(array[1..3]) == 5);
    try expect(total(array[3..]) == 9);
    try expect(@TypeOf(slice) == *const [3]u8);
}
