const expect = @import("std").testing.expect;
const Vector = @import("std").meta.Vector;
const eql = @import("std").meta.eql;

test "vector add" {
    const x: Vector(4, f32) = .{ 1, -10, 20, -1 };
    const y: Vector(4, f32) = .{ 2, 10, 0, 1 };

    const z = x + y;

    try expect(eql(z, Vector(4, f32){ 3, 0, 20, 0 }));
}

test "vector indexing" {
    const x: Vector(4, u8) = .{ 255, 0, 255, 0 };
    try expect(x[0] == 255);
}

test "vector * scalar" {
    const x: Vector(3, f32) = .{ 12.5, 37.5, 2.5 };
    const y = x * @splat(3, @as(f32, 2)); // @splat creates a vector of 2-s
    try expect(eql(y, Vector(3, f32){ 25, 75, 5 }));
}

const len = @import("std").mem.len;
test "vector looping" {
    const x = Vector(4, u8){ 255, 0, 255, 0 };
    var sum = blk: {
        var tmp: u10 = 0;
        var i: u8 = 0;
        while (i < len(x)) : (i += 1) tmp += x[i];
        break :blk tmp;
    };
    try expect(sum == 510);
}
