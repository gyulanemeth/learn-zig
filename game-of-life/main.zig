const std = @import("std");

const GameState = struct { n_rows: u32, n_cols: u32, state_matrix: []u8 };

fn loadState(allocator: std.mem.Allocator) !GameState {
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

        for (line, 0..) |char, idx| {
            memory[line_num * n_cols + idx] = char - 48;
        }
    }

    return GameState{ .n_rows = n_rows, .n_cols = n_cols, .state_matrix = memory };
}

fn saveState() !void {}

fn getCellValue(game_state: GameState, r_idx: i32, c_idx: i32) u8 {
    var real_r_idx = r_idx;
    var real_c_idx = c_idx;

    if (real_r_idx < 0) {
        real_r_idx += @as(i32, @intCast(game_state.n_rows));
    }

    if (real_c_idx < 0) {
        real_c_idx += @as(i32, @intCast(game_state.n_cols));
    }

    real_r_idx = @mod(real_r_idx, @as(i32, @intCast(game_state.n_rows)));
    real_c_idx = @mod(real_c_idx, @as(i32, @intCast(game_state.n_cols)));

    return game_state.state_matrix[@as(u32, @intCast(real_r_idx * @as(i32, @intCast(game_state.n_cols)) + real_c_idx))];
}

fn setCellValue(game_state: GameState, r_idx: usize, c_idx: usize, value: u8) void {
    game_state.state_matrix[r_idx * game_state.n_cols + c_idx] = value;
}

fn countNeighboursAlive(game_state: GameState, r_idx: i32, c_idx: i32) u8 {
    var neighbors_alive: u8 = 0;

    neighbors_alive += getCellValue(game_state, r_idx - 1, c_idx - 1);
    neighbors_alive += getCellValue(game_state, r_idx - 1, c_idx);
    neighbors_alive += getCellValue(game_state, r_idx - 1, c_idx + 1);
    neighbors_alive += getCellValue(game_state, r_idx, c_idx - 1);
    neighbors_alive += getCellValue(game_state, r_idx, c_idx + 1);
    neighbors_alive += getCellValue(game_state, r_idx + 1, c_idx - 1);
    neighbors_alive += getCellValue(game_state, r_idx + 1, c_idx);
    neighbors_alive += getCellValue(game_state, r_idx + 1, c_idx + 1);

    return neighbors_alive;
}

fn calcNextState(current_game_state: GameState, next_game_state: GameState) void {
    for (current_game_state.state_matrix, 0..) |cell, idx| {
        const r_idx: usize = idx / current_game_state.n_cols;
        const c_idx: usize = @mod(idx, current_game_state.n_cols);
        const neighbors_alive = countNeighboursAlive(current_game_state, @as(i32, @intCast(r_idx)), @as(i32, @intCast(c_idx)));

        if (cell == 1 and neighbors_alive > 1 and neighbors_alive < 4) {
            setCellValue(next_game_state, r_idx, c_idx, 1);
        } else if (cell == 0 and neighbors_alive == 3) {
            setCellValue(next_game_state, r_idx, c_idx, 1);
        } else {
            setCellValue(next_game_state, r_idx, c_idx, 0);
        }
    }
}

fn printStateMatrix(message: []const u8, game_state: GameState) void {
    std.debug.print("\n\n{s}", .{message});
    for (game_state.state_matrix, 0..) |cell, idx| {
        if (idx % game_state.n_cols == 0) {
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
    var full_game_state: GameState = try loadState(std.heap.page_allocator);
    defer std.heap.page_allocator.free(full_game_state.state_matrix);

    const state_matrix_length = full_game_state.n_rows * full_game_state.n_cols;

    var game_state_1 = GameState{ .n_rows = full_game_state.n_rows, .n_cols = full_game_state.n_cols, .state_matrix = full_game_state.state_matrix[0..state_matrix_length] };
    var game_state_2 = GameState{ .n_rows = full_game_state.n_rows, .n_cols = full_game_state.n_cols, .state_matrix = full_game_state.state_matrix[state_matrix_length..] };

    var state: GameState = game_state_1;
    var next_state: GameState = game_state_2;

    printStateMatrix("state: matrix:", state);

    var x: u8 = 100;
    while (x > 0) : (x -= 1) {
        std.time.sleep(0.3 * std.time.ns_per_s);

        calcNextState(state, next_state);

        var tmp = state;
        state = next_state;
        next_state = tmp;

        printStateMatrix("state matrix:", state);
    }
}
