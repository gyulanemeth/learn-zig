const std = @import("std");

const StateDescriptor = struct { n_rows: u32, n_cols: u32, memory: []u8 };

fn loadState(allocator: std.mem.Allocator) !StateDescriptor {
    const state_path = "./state.txt";

    var state_file = try std.fs.cwd().openFile(state_path, .{});
    defer state_file.close();

    var buf_reader = std.io.bufferedReader(state_file.reader());
    var in_stream = buf_reader.reader();

    var line_num: u8 = 0;

    var n_rows: u32 = 0;
    var n_cols: u32 = 0;

    var buffer: [128]u8 = undefined;

    var buffer_line = try in_stream.readUntilDelimiterOrEof(&buffer, '\n');
    if (buffer_line) |line| {
        n_rows = try std.fmt.parseInt(u32, line, 10);
    }

    buffer_line = try in_stream.readUntilDelimiterOrEof(&buffer, '\n');
    if (buffer_line) |line| {
        n_cols = try std.fmt.parseInt(u32, line, 10);
    }

    std.debug.print("rows: {d}, cols: {d}\n", .{ n_rows, n_cols });

    var memory = try allocator.alloc(u8, n_rows * n_cols * 2);

    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| : (line_num += 1) {
        std.debug.print("file line read {s}\n", .{line});

        for (line) |char, idx| {
            memory[line_num * n_cols + idx] = char - 48;
        }
    }

    return StateDescriptor{ .n_rows = n_rows, .n_cols = n_cols, .memory = memory };
}

fn saveState() !void {}

fn getCellValue(n_rows: u32, n_cols: u32, state_matrix: []u8, r_idx: i32, c_idx: i32) u8 {
    var real_r_idx = r_idx;
    var real_c_idx = c_idx;

    if (real_r_idx < 0) {
        real_r_idx += @intCast(i32, n_rows);
    }

    if (real_c_idx < 0) {
        real_c_idx += @intCast(i32, n_cols);
    }

    real_r_idx = @mod(real_r_idx, @intCast(i32, n_rows));
    real_c_idx = @mod(real_c_idx, @intCast(i32, n_cols));

    return state_matrix[@intCast(u32, real_r_idx * @intCast(i32, n_cols) + real_c_idx)];
}

fn setCellValue(n_cols: u32, state_matrix: []u8, r_idx: usize, c_idx: usize, value: u8) void {
    state_matrix[r_idx * n_cols + c_idx] = value;
}

fn countNeighboursAlive(n_rows: u32, n_cols: u32, state_matrix: []u8, r_idx: i32, c_idx: i32) u8 {
    var neighbors_alive: u8 = 0;

    neighbors_alive += getCellValue(n_rows, n_cols, state_matrix, r_idx - 1, c_idx - 1);
    neighbors_alive += getCellValue(n_rows, n_cols, state_matrix, r_idx - 1, c_idx);
    neighbors_alive += getCellValue(n_rows, n_cols, state_matrix, r_idx - 1, c_idx + 1);
    neighbors_alive += getCellValue(n_rows, n_cols, state_matrix, r_idx, c_idx - 1);
    neighbors_alive += getCellValue(n_rows, n_cols, state_matrix, r_idx, c_idx + 1);
    neighbors_alive += getCellValue(n_rows, n_cols, state_matrix, r_idx + 1, c_idx - 1);
    neighbors_alive += getCellValue(n_rows, n_cols, state_matrix, r_idx + 1, c_idx);
    neighbors_alive += getCellValue(n_rows, n_cols, state_matrix, r_idx + 1, c_idx + 1);

    return neighbors_alive;
}

fn nextState(n_rows: u32, n_cols: u32, state_matrix: []u8, next_state_matrix: []u8) void {
    for (state_matrix) |cell, idx| {
        const r_idx: usize = idx / n_cols;
        const c_idx: usize = @mod(idx, n_cols);
        const neighbors_alive = countNeighboursAlive(n_rows, n_cols, state_matrix, @intCast(i32, r_idx), @intCast(i32, c_idx));

        if (cell == 1 and neighbors_alive > 1 and neighbors_alive < 4) {
            setCellValue(n_cols, next_state_matrix, r_idx, c_idx, 1);
        } else if (cell == 0 and neighbors_alive == 3) {
            setCellValue(n_cols, next_state_matrix, r_idx, c_idx, 1);
        } else {
            setCellValue(n_cols, next_state_matrix, r_idx, c_idx, 0);
        }
    }
}

fn printStateMatrix(message: []const u8, n_cols: u32, state_matrix: []u8) void {
    std.debug.print("\n\n{s}", .{message});
    for (state_matrix) |cell, idx| {
        if (idx % n_cols == 0) {
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
    var stateVars = try loadState(std.heap.page_allocator);
    defer std.heap.page_allocator.free(stateVars.memory);

    var state1: []u8 = stateVars.memory[0 .. stateVars.n_rows * stateVars.n_cols];
    var state2: []u8 = stateVars.memory[stateVars.n_rows * stateVars.n_cols ..];

    var state: []u8 = state1;
    var next_state: []u8 = state2;

    printStateMatrix("state: matrix:", stateVars.n_cols, state);

    var x: u8 = 100;
    while (x > 0) : (x -= 1) {
        std.time.sleep(0.3 * std.time.ns_per_s);

        nextState(stateVars.n_rows, stateVars.n_cols, state, next_state);

        var tmp = state;
        state = next_state;
        next_state = tmp;

        printStateMatrix("state matrix:", stateVars.n_cols, state);
    }
}
