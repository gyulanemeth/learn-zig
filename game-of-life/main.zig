const std = @import("std");

const state_path = "./state.txt";

var state: [10][10]u8 = undefined;
var next_state: [10][10]u8 = undefined;

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
            next_state[line_num][idx] = 0;
        }
    }
}

fn saveState() !void {}

fn cellValue(r_idx: i32, c_idx: i32) u8 {
    var real_r_idx = r_idx;
    var real_c_idx = c_idx;

    if (real_r_idx < 0) {
        real_r_idx += 10;
    }

    if (real_c_idx < 0) {
        real_c_idx += 10;
    }

    real_r_idx = @mod(real_r_idx, 10);
    real_c_idx = @mod(real_c_idx, 10);

    return state[@intCast(u32, real_r_idx)][@intCast(u32, real_c_idx)];
}

fn countNeighboursAlive(r_idx: i32, c_idx: i32) u8 {
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
    for (state) |row, r_idx| {
        for (row) |cell, c_idx| {
            const neighbors_alive = countNeighboursAlive(@intCast(i32, r_idx), @intCast(i32, c_idx));

            if (cell == 1 and neighbors_alive > 1 and neighbors_alive < 4) {
                next_state[r_idx][c_idx] = 1;
            } else if (cell == 0 and neighbors_alive == 3) {
                next_state[r_idx][c_idx] = 1;
            } else {
                next_state[r_idx][c_idx] = 0;
            }
        }
    }

    for (next_state) |row, r_idx| {
        for (row) |cell, c_idx| {
            state[r_idx][c_idx] = cell;
        }
    }
}

fn printStateMatrix(message: []const u8, state_matrix: [10][10]u8) void {
    std.debug.print("\n\n{s}\n", .{message});
    for (state_matrix) |row| {
        for (row) |cell| {
            if (cell == 0) {
                std.debug.print(" ", .{});
            } else {
                std.debug.print("*", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}

pub fn main() !void {
    try loadState();

    printStateMatrix("state matrix:", state);

    var x: u8 = 100;
    while (x > 0) : (x -= 1) {
        std.time.sleep(0.3 * std.time.ns_per_s);

        nextState();

        printStateMatrix("state matrix:", state);
    }
}
