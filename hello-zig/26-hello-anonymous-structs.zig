const expect = @import("std").testing.expect;

test "anonymous struct literal" {
    const Point = struct { x: i32, y: i32 };

    var pt: Point = .{ .x = 13, .y = 67 };

    try expect(pt.x == 13);
    try expect(pt.y == 67);
}

test "fully anonymous struct" {
    try dump(.{
        .int = @as(u32, 1337),
        .float = @as(f64, 13.37),
        .b = true,
        .s = "hi",
    });
}

fn dump(args: anytype) !void {
    try expect(args.int == 1337);
    try expect(args.float == 13.37);
    try expect(args.b);
    try expect(args.s[0] == 'h');
    try expect(args.s[1] == 'i');
}

test "tuples" {
    const values = .{ @as(u32, 1337), @as(f64, 13.37), true, "hi" } ++ .{false} ** 2;

    try expect(values[0] == 1337);
    try expect(values[4] == false);
    inline for (values) |v, i| { // if we wanna iterate, we need an inline loop here
        if (i != 2) continue;
        try expect(v);
    }
    try expect(values.len == 6);
    try expect(values.@"3"[0] == 'h');
}
