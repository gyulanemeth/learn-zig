const std = @import("std");

fn loadState(state_matrix: []u8, next_state_matrix: []u8) !void {
    const state_path = "./state.txt";

    var state_file = try std.fs.cwd().openFile(state_path, .{});
    defer state_file.close();

    var buf_reader = std.io.bufferedReader(state_file.reader());
    var in_stream = buf_reader.reader();

    var line_num: u8 = 0;

    var buffer: [11]u8 = undefined; // I needed a 11 long array, because of the '\n' character.
    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| : (line_num += 1) {
        std.debug.print("file line read {s}\n", .{line});

        for (line) |char, idx| {
            state_matrix[line_num * 10 + idx] = char - 48; // 0 in ascii is 48
            next_state_matrix[line_num * 10 + idx] = 0;
        }
    }
}

fn saveState() !void {}

fn getCellValue(state_matrix: []u8, r_idx: i32, c_idx: i32) u8 {
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

    return state_matrix[@intCast(u32, real_r_idx * 10 + real_c_idx)];
}

fn setCellValue(state_matrix: []u8, r_idx: usize, c_idx: usize, value: u8) void {
    state_matrix[r_idx * 10 + c_idx] = value;
}

fn countNeighboursAlive(state_matrix: []u8, r_idx: i32, c_idx: i32) u8 {
    var neighbors_alive: u8 = 0;

    neighbors_alive += getCellValue(state_matrix, r_idx - 1, c_idx - 1);
    neighbors_alive += getCellValue(state_matrix, r_idx - 1, c_idx);
    neighbors_alive += getCellValue(state_matrix, r_idx - 1, c_idx + 1);
    neighbors_alive += getCellValue(state_matrix, r_idx, c_idx - 1);
    neighbors_alive += getCellValue(state_matrix, r_idx, c_idx + 1);
    neighbors_alive += getCellValue(state_matrix, r_idx + 1, c_idx - 1);
    neighbors_alive += getCellValue(state_matrix, r_idx + 1, c_idx);
    neighbors_alive += getCellValue(state_matrix, r_idx + 1, c_idx + 1);

    return neighbors_alive;
}

fn nextState(state_matrix: []u8, next_state_matrix: []u8) void {
    for (state_matrix) |cell, idx| {
        const r_idx: usize = idx / 10;
        const c_idx: usize = @mod(idx, 10);
        const neighbors_alive = countNeighboursAlive(state_matrix, @intCast(i32, r_idx), @intCast(i32, c_idx));

        if (cell == 1 and neighbors_alive > 1 and neighbors_alive < 4) {
            setCellValue(next_state_matrix, r_idx, c_idx, 1);
        } else if (cell == 0 and neighbors_alive == 3) {
            setCellValue(next_state_matrix, r_idx, c_idx, 1);
        } else {
            setCellValue(next_state_matrix, r_idx, c_idx, 0);
        }
    }
}

fn printStateMatrix(message: []const u8, state_matrix: []u8) void {
    std.debug.print("\n\n{s}", .{message});
    for (state_matrix) |cell, idx| {
        if (idx % 10 == 0) {
            std.debug.print("\n", .{});
        }
        if (cell == 0) {
            std.debug.print("_", .{});
        } else {
            std.debug.print("•", .{});
        }
    }
    std.debug.print("\n", .{});
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var memory = try allocator.alloc(u8, 200);
    defer allocator.free(memory);

    var state1: []u8 = memory[0..100];
    var state2: []u8 = memory[100..memory.len];

    try loadState(state1, state2);

    var state: []u8 = state1;
    var next_state: []u8 = state2;

    printStateMatrix("state matrix:", state);

    var x: u8 = 100;
    while (x > 0) : (x -= 1) {
        std.time.sleep(0.3 * std.time.ns_per_s);

        nextState(state, next_state);

        var tmp = state;
        state = next_state;
        next_state = tmp;

        printStateMatrix("state matrix:", state);
    }
}
