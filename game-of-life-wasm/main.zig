const std = @import("std");

extern fn drawCell(r_idx: i32, c_idx: i32, value: u8) void;

const GameState = struct { n_rows: u32, n_cols: u32, state_matrix: []u8 };

var full_game_state: GameState = undefined;
var game_state_1: GameState = undefined;
var game_state_2: GameState = undefined;

var current_game_state: GameState = undefined;
var next_game_state: GameState = undefined;

export fn init(n_rows: u32, n_cols: u32) void {
    const memory_size = n_rows * n_cols * 2;
    var memory = std.heap.page_allocator.alloc(u8, memory_size) catch unreachable;
    for(0..memory_size) |idx| {
        memory[idx] = 0;
    }

    full_game_state = GameState{ .n_rows = n_rows, .n_cols = n_cols, .state_matrix = memory };
    const state_matrix_length = full_game_state.n_rows * full_game_state.n_cols;
    game_state_1 = GameState{ .n_rows = full_game_state.n_rows, .n_cols = full_game_state.n_cols, .state_matrix = full_game_state.state_matrix[0..state_matrix_length] };
    game_state_2 = GameState{ .n_rows = full_game_state.n_rows, .n_cols = full_game_state.n_cols, .state_matrix = full_game_state.state_matrix[state_matrix_length..] };

    current_game_state = game_state_1;
    next_game_state = game_state_2;
}

fn getCellValue(r_idx: i32, c_idx: i32) u8 {
    var real_r_idx = r_idx;
    var real_c_idx = c_idx;

    if (real_r_idx < 0) {
        real_r_idx += @as(i32, @intCast(current_game_state.n_rows));
    }

    if (real_c_idx < 0) {
        real_c_idx += @as(i32, @intCast(current_game_state.n_cols));
    }

    real_r_idx = @mod(real_r_idx, @as(i32, @intCast(current_game_state.n_rows)));
    real_c_idx = @mod(real_c_idx, @as(i32, @intCast(current_game_state.n_cols)));

    return current_game_state.state_matrix[@as(u32, @intCast(real_r_idx * @as(i32, @intCast(current_game_state.n_cols)) + real_c_idx))];
}

export fn setCellValue(r_idx: usize, c_idx: usize, value: u8) void {
    current_game_state.state_matrix[r_idx * current_game_state.n_cols + c_idx] = value;
    drawCell(@as(i32, @intCast(r_idx)), @as(i32, @intCast(c_idx)), value);
}

fn setNextCellValue(r_idx: usize, c_idx: usize, value: u8) void {
    next_game_state.state_matrix[r_idx * next_game_state.n_cols + c_idx] = value;
}

fn countNeighboursAlive(r_idx: i32, c_idx: i32) u8 {
    var neighbors_alive: u8 = 0;

    neighbors_alive += getCellValue(r_idx - 1, c_idx - 1);
    neighbors_alive += getCellValue(r_idx - 1, c_idx);
    neighbors_alive += getCellValue(r_idx - 1, c_idx + 1);
    neighbors_alive += getCellValue(r_idx, c_idx - 1);
    neighbors_alive += getCellValue(r_idx, c_idx + 1);
    neighbors_alive += getCellValue(r_idx + 1, c_idx - 1);
    neighbors_alive += getCellValue(r_idx + 1, c_idx);
    neighbors_alive += getCellValue(r_idx + 1, c_idx + 1);

    return neighbors_alive;
}

export fn calcNextState() void {
    for (current_game_state.state_matrix, 0..) |cell, idx| {
        const r_idx: usize = idx / current_game_state.n_cols;
        const c_idx: usize = @mod(idx, current_game_state.n_cols);
        const neighbors_alive = countNeighboursAlive(@as(i32, @intCast(r_idx)), @as(i32, @intCast(c_idx)));

        if (cell == 1 and neighbors_alive > 1 and neighbors_alive < 4) {
            setNextCellValue(r_idx, c_idx, 1);
        } else if (cell == 0 and neighbors_alive == 3) {
            setNextCellValue(r_idx, c_idx, 1);
        } else {
            setNextCellValue(r_idx, c_idx, 0);
        }
    }

    var tmp = current_game_state;
    current_game_state = next_game_state;
    next_game_state = tmp;
}

export fn drawCurrentGameState() void {
    for (current_game_state.state_matrix, 0..) |cell, idx| {
        const r_idx: usize = idx / current_game_state.n_cols;
        const c_idx: usize = @mod(idx, current_game_state.n_cols);

        drawCell(@as(i32, @intCast(r_idx)), @as(i32, @intCast(c_idx)), cell);
    }
}
