const std = @import("std");

const state_path = "./state.txt";

var state: [10][10]u8 = undefined;

fn loadState() !void {
    var state_file = try std.fs.cwd().openFile(state_path, .{});
    defer state_file.close();

    var buf_reader = std.io.bufferedReader(state_file.reader());
    var in_stream = buf_reader.reader();

    var line_num: u8 = 0;

    var buffer: [11]u8 = undefined; // I needed a 11 long array, because of the '\n' character.
    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| : (line_num += 1) {
        std.debug.print("file line read {s}\n", .{line});

        for (line) |char, idx| {
            state[line_num][idx] = char - 48; // 0 in ascii is 48
        }
    }
}

fn saveState() !void {}

fn cellValue(r_idx: usize, c_idx: usize) u8 {
    var real_r_idx = r_idx;
    var real_c_idx = c_idx;

    if (real_r_idx < 0) {
        real_r_idx += 10;
    }

    if (real_c_idx < 0) {
        real_c_idx += 10;
    }

    real_r_idx = real_r_idx % 10;
    real_c_idx = real_c_idx % 10;

    return state[real_r_idx][real_c_idx];
}

fn countNeighboursAlive(r_idx: usize, c_idx: usize) u8 {
    var neighbors_alive: u8 = 0;

    neighbors_alive += cellValue(r_idx - 1, c_idx - 1);
    neighbors_alive += cellValue(r_idx - 1, c_idx);
    neighbors_alive += cellValue(r_idx - 1, c_idx + 1);
    neighbors_alive += cellValue(r_idx, c_idx - 1);
    neighbors_alive += cellValue(r_idx, c_idx + 1);
    neighbors_alive += cellValue(r_idx + 1, c_idx - 1);
    neighbors_alive += cellValue(r_idx + 1, c_idx);
    neighbors_alive += cellValue(r_idx + 1, c_idx + 1);

    return neighbors_alive;
}

fn nextState() void {
    var next_state: [10][10]u8 = undefined;

    for (state) |row, r_idx| {
        for (row) |cell, c_idx| {
            const neighbors_alive = countNeighboursAlive(r_idx, c_idx);

            // TODO: update rules!
        }
    }
}

pub fn main() !void {
    try loadState();

    std.debug.print("\n\nstate matrix:\n", .{});
    for (state) |row| {
        for (row) |cell| {
            std.debug.print("{}", .{cell});
        }
        std.debug.print("\n", .{});
    }
}
