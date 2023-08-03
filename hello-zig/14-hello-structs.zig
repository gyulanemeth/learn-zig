const expect = @import("std").testing.expect;

const Vec3 = struct { x: f32, y: f32, z: f32 };

test "struct usage" {
    const my_vector = Vec3{ .x = 0, .y = 10, .z = 20 };
    _ = my_vector;
}

// test "missing struct field" {
//     const my_vector = Vec3{
//         .x = 10,
//         .y = 20,
//     };
//     _ = my_vector;
// }

const Vec4 = struct { x: f32, y: f32, z: f32 = 0, w: f32 = undefined };

test "struct defaults" {
    const my_vector = Vec4{ .x = 0, .y = 10 };
    _ = my_vector;
}

const Stuff = struct {
    x: i32,
    y: i32,
    fn swap(self: *Stuff) void {
        const tmp = self.x;
        self.x = self.y;
        self.y = tmp;
    }
};

test "automatic dereference" {
    var thing = Stuff{ .x = 10, .y = 20 };
    thing.swap();
    try expect(thing.x == 20);
    try expect(thing.y == 10);
}
