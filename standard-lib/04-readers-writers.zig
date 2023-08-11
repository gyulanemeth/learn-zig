const std = @import("std");

const ArrayList = std.ArrayList;

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const eql = std.mem.eql;

test "io writer usage" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();
    const bytes_written = try list.writer().write("Hello World!");
    try expect(bytes_written == 12);
    try expect(eql(u8, list.items, "Hello World!"));
}

test "io reader usage" {
    const message = "Hello File!";

    const file = try std.fs.cwd().createFile("junk_file3.txt", .{ .read = true });
    defer file.close();

    try file.writeAll(message);
    try file.seekTo(0);

    const contents = try file.reader().readAllAlloc(test_allocator, message.len);
    defer test_allocator.free(contents);

    try expect(eql(u8, contents, message));
}

fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    var line = (try reader.readUntilDelimiterOrEof(buffer, '\n')) orelse return null;

    if (@import("builtin").os.tag == .windows) {
        return std.mem.trimRight(u8, line, '\r');
    } else {
        return line;
    }
}

test "read until next line" {
    const stdout = std.io.getStdOut();
    const stdin = std.io.getStdIn();

    try stdout.writeAll("\\ Enter your name:");

    var buffer: [100]u8 = undefined;

    const input = (try nextLine(stdin.reader(), &buffer)).?;

    try stdout.writer().print("Your name is: \"{s}\"\n", .{input});
}

const MyByteList = struct {
    data: [100]u8 = undefined,
    items: []u8 = &[_]u8{},

    const Writer = std.io.Writer(*MyByteList, error{EndOfBuffer}, appendWrite);

    fn appendWrite(self: *MyByteList, data: []const u8) error{EndOfBuffer}!usize {
        if (self.items.len + data.len > self.data.len) {
            return error.EndOfBuffer;
        }

        std.mem.copy(u8, self.data[self.items.len..], data);

        self.items = self.data[0 .. self.items.len + data.len];
        return data.len;
    }

    fn writer(self: *MyByteList) Writer {
        return .{ .context = self };
    }
};

test "custom writer" {
    var bytes = MyByteList{};
    _ = try bytes.writer().write("Hello");
    _ = try bytes.writer().write(" Custom Writer!");
    try expect(eql(u8, bytes.items, "Hello Custom Writer!"));
}
