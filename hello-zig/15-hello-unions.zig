const expect = @import("std").testing.expect;

const Result = union {
    int: i64,
    float: f64,
    bool: bool,
};

// test "simple union" {
//     var result = Result{ .int = 4 };
//     result.float = 12.3;
// }

const Tag = enum { a, b, c };
const Tagged = union(Tag) { a: u8, b: f32, c: bool };

test "switch on tagged union" {
    var value = Tagged{ .b = 1.5 };
    switch (value) {
        .a => |*byte| byte.* += 1,
        .b => |*float| float.* *= 2,
        .c => |*b| b.* = !b.*,
    }
    try expect(value.b == 3);
}
