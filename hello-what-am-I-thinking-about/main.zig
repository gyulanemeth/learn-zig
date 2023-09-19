const std = @import("std");

pub fn main() void {
    const s: [16]u8 = .{ 8, 6, 4, 7, 2, 5, 1, 5, 7, 2, 5, 5, 5, 7, 2, 1 };

    const d: [8]u8 = .{2, 0, 2, 4, 0, 2, 1, 6};
    const o: [8]u8 = .{2, 0, 3, 1, 4, 7, 5, 6 };

    var l: [16]u8 = .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

    for (o, 0..) |a, i| {
        l[i] = d[a] + s[i] + 65;
        l[i + 8] = a + s[i + 8] + 65;
    }

    std.debug.print("{s}\n", .{ l });
}