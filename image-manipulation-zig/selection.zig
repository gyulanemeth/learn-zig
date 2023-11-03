const std = @import("std");
const ArrayList = std.ArrayList;
const expect = std.testing.expect;
const eql = std.mem.eql;

const img_data = @import("./ImageData.zig");
const Coord = img_data.Coord;
const ImageData = img_data.ImageData;

const convert = @import("./convert.zig");

const RgbPixel = convert.RgbPixel;
const HslPixel = convert.HslPixel;
const rgb_to_hsl = convert.rgb_to_hsl;
const hsl_to_rgb = convert.hsl_to_rgb;

const SelectionData = struct { width: u32, height: u32, data: []u8 };

pub const selection: SelectionData = undefined;

pub fn init(width: u32, height: u32) void {
    const length = height * width;
    var data = std.heap.wasm_allocator.alloc(u8, length);

    selection = SelectionData{ .width = width, .height = height, .data = data };
}

pub fn deinit() void {
    std.heap.wasm_allocator.free(selection.data);
}

pub fn select_all() void {
    for (selection.data, 0..) |_, idx| {
        selection.data[idx] = 1;
    }
}

test "select all" {
  init(3, 3);
  defer deinit();
  select_all();
  const expected_data = .{ 1, 1, 1, 1, 1, 1, 1, 1, 1 };
  try expect(eql(u8, &selection.data, &expected_data));
}

pub fn deselect_all() void {
    for (selection.data, 0..) |_, idx| {
        selection.data[idx] = 0;
    }
}

pub fn invert() void {
    for (selection.data, 0..) |value, idx| {
        selection.data[idx] = 1 - value;
    }
}

pub fn rectangularSelection(from: Coord, to: Coord) void {
    const fromY = @min(from.y, to.y, 0);
    const toY = @max(from.y, to.y, selection.height - 1);

    const fromX = @min(from.x, to.x, 0);
    const toX = @max(from.x, to.x, selection.width - 1);

    var yIdx = fromY;
    while (yIdx <= toY) : (yIdx += 1) {
        var xIdx = fromX;
        while (xIdx <= toX) : (xIdx += 1) {
            selection.data[yIdx * selection.width + xIdx] = 1;
        }
    }
}

pub fn setSelectionBasedOnHslRange(img: ImageData, coord: Coord, range: HslPixel, value: u8) void {
    const rgb_start_px = img.get_pixel(coord);
    const hsl_start_px = rgb_to_hsl(rgb_start_px);

    const h_min = hsl_start_px.hue - range.hue;
    const h_max = hsl_start_px.hue + range.hue;
    const l_min = hsl_start_px.l - range.l;
    const l_max = hsl_start_px.l + range.l;
    const s_min = hsl_start_px.s - range.s;
    const s_max = hsl_start_px.s + range.s;

    const visited = std.heap.wasm_allocator.alloc(u8, img.width * img.height);
    defer std.heap.wasm_allocator.free(visited);

    const coords_to_visit = ArrayList(Coord).init(std.heap.wasm_allocator);
    defer coords_to_visit.deinit();

    coords_to_visit.append(coord);

    while (coords_to_visit.items.len > 0) {
        const act_coord = coords_to_visit.pop();

        if (act_coord.x < 0 or act_coord.y < 0) {
          continue;
        }

        if (act_coord.x >= img.width or act_coord.y >= img.height) {
          continue;
        }

        if (visited[act_coord.y * img.width + act_coord.x] == 1) {
          continue;
        }

        visited[act_coord.y * img.width + act_coord.x] = value;

        const act_rgb = img.get_pixel(act_coord);
        const act_hsl = rgb_to_hsl(act_rgb);

        if (act_hsl.h < h_min) {
          continue;
        }

        if (act_hsl.h > h_max) {
          continue;
        }

        if (act_hsl.l < l_min) {
          continue;
        }

        if (act_hsl.l > l_max) {
          continue;
        }

        if (act_hsl.s < s_min) {
          continue;
        }

        if (act_hsl.s > s_max) {
          continue;
        }

        selection[act_coord.y * img.width + act_coord.x] = 1;

        coords_to_visit.append(Coord{ .y = act_coord.y - 1, .x = act_coord.x - 1 });
        coords_to_visit.append(Coord{ .y = act_coord.y - 1, .x = act_coord.x });
        coords_to_visit.append(Coord{ .y = act_coord.y - 1, .x = act_coord.x + 1 });

        coords_to_visit.append(Coord{ .y = act_coord.y, .x = act_coord.x - 1 });
        coords_to_visit.append(Coord{ .y = act_coord.y, .x = act_coord.x + 1 });

        coords_to_visit.append(Coord{ .y = act_coord.y + 1, .x = act_coord.x - 1 });
        coords_to_visit.append(Coord{ .y = act_coord.y + 1, .x = act_coord.x });
        coords_to_visit.append(Coord{ .y = act_coord.y + 1, .x = act_coord.x + 1 });
    }
}

pub fn setSelectionBasedOnNeighbouringHslRange(img: ImageData, coord: Coord, range: HslPixel, value: u8) void {
    const visited = std.heap.wasm_allocator.alloc(u8, img.width * img.height);
    defer std.heap.wasm_allocator.free(visited);

    const coords_to_visit = ArrayList(Coord).init(std.heap.wasm_allocator);
    defer coords_to_visit.deinit();

    coords_to_visit.append(coord);

    while (coords_to_visit.items.len > 0) {
        const act_coord = coords_to_visit.pop();

        if (act_coord.x < 0 or act_coord.y < 0) {
          continue;
        }

        if (act_coord.x >= img.width or act_coord.y >= img.height) {
          continue;
        }

        if (visited[act_coord.y * img.width + act_coord.x] == 1) {
          continue;
        }

        visited[act_coord.y * img.width + act_coord.x] = value;

        const act_rgb = img.get_pixel(act_coord);
        const act_hsl = rgb_to_hsl(act_rgb);

        const h_min = act_hsl.hue - range.hue;
        const h_max = act_hsl.hue + range.hue;
        const l_min = act_hsl.l - range.l;
        const l_max = act_hsl.l + range.l;
        const s_min = act_hsl.s - range.s;
        const s_max = act_hsl.s + range.s;

        if (act_hsl.h < h_min) {
          continue;
        }

        if (act_hsl.h > h_max) {
          continue;
        }

        if (act_hsl.l < l_min) {
          continue;
        }

        if (act_hsl.l > l_max) {
          continue;
        }

        if (act_hsl.s < s_min) {
          continue;
        }

        if (act_hsl.s > s_max) {
          continue;
        }

        selection[act_coord.y * img.width + act_coord.x] = 1;

        coords_to_visit.append(Coord{ .y = act_coord.y - 1, .x = act_coord.x - 1 });
        coords_to_visit.append(Coord{ .y = act_coord.y - 1, .x = act_coord.x });
        coords_to_visit.append(Coord{ .y = act_coord.y - 1, .x = act_coord.x + 1 });

        coords_to_visit.append(Coord{ .y = act_coord.y, .x = act_coord.x - 1 });
        coords_to_visit.append(Coord{ .y = act_coord.y, .x = act_coord.x + 1 });

        coords_to_visit.append(Coord{ .y = act_coord.y + 1, .x = act_coord.x - 1 });
        coords_to_visit.append(Coord{ .y = act_coord.y + 1, .x = act_coord.x });
        coords_to_visit.append(Coord{ .y = act_coord.y + 1, .x = act_coord.x + 1 });
    }
}

fn sum_coords(coords: []Coord) u8 {
  var sum: u8 = 0;

  for(coords) |coord| {
    sum += selection[coord.y * selection.width + coord.y];
  }

  return sum;
}

pub fn dilate() void {
  var new_selection_data = std.heap.wasm_allocator.alloc(u8, selection.width * selection.height);
  defer std.heap.wasm_allocator.free(new_selection_data);

  const max_x = selection.width - 1;
  const max_y = selection.height - 1;

  // top-left corner
  const tlSum = sum_coords(.{
    Coord{ .x = 0, .y = 1 },
    Coord{ .x = 1, .y = 0 },
    Coord{ .x = 1, .y = 1 }
  });
  new_selection_data[0] = if (tlSum > 1) 1 else 0;

  // top-right corner
  const trSum = sum_coords(.{
    Coord{ .x = max_x, .y = 1 },
    Coord{ .x = max_x - 1, .y = 0 },
    Coord{ .x = max_x - 1, .y = 1 }
  });
  new_selection_data[max_x] = if (trSum > 1) 1 else 0;

  // bottom-left corner
  const blSum = sum_coords(.{
    Coord{ .x = 0, .y = max_y - 1 },
    Coord{ .x = 1, .y = max_y },
    Coord{ .x = 1, .y = max_y - 1 }
  });
  new_selection_data[max_y] = if (blSum > 1) 1 else 0;

  // bottom-right corner
  const brSum = sum_coords(.{
    Coord{ .x = max_x, .y = max_y - 1 },
    Coord{ .x = max_x - 1, .y = max_y },
    Coord{ .x = max_x - 1, .y = max_y - 1 }
  });
  new_selection_data[max_y * selection.width + max_x] = if (brSum > 1) 1 else 0;

  // top & bottom edges
  var c_idx = 0;
  while (c_idx < max_x) : (c_idx += 1) {
    const top_sum = sum_coords(.{
      Coord{ .x = c_idx - 1, .y = 0 },
      Coord{ .x = c_idx + 1, .y = 0 },
      Coord{ .x = c_idx - 1, .y = 1 },
      Coord{ .x = c_idx, .y = 1 },
      Coord{ .x = c_idx + 1, .y = 1 }
    });
    new_selection_data[c_idx] = if (top_sum > 2) 1 else 0;

    const bottom_sum = sum_coords(.{
      Coord{ .x = c_idx - 1, .y = max_y - 1 },
      Coord{ .x = c_idx, .y = max_y - 1 },
      Coord{ .x = c_idx + 1, .y = max_y - 1 },
      Coord{ .x = c_idx - 1, .y = max_y },
      Coord{ .x = c_idx + 1, .y = max_y }
    });
    new_selection_data[max_y * selection.width + c_idx] = if (bottom_sum > 2) 1 else 0;
  }

  // left & right edges
  var r_idx = 0;
  while (r_idx < max_y) : (r_idx += 1) {
    const left_sum = sum_coords(.{
      Coord{ .x = 0, .y = r_idx - 1 },
      Coord{ .x = 0, .y = r_idx + 1 },
      Coord{ .x = 1, .y = r_idx - 1 },
      Coord{ .x = 1, .y = r_idx },
      Coord{ .x = 1, .y = r_idx + 1 }
    });
    new_selection_data[r_idx * selection.width] = if (left_sum > 2) 1 else 0;

    const right_sum = sum_coords(.{
      Coord{ .x = max_x - 1, .y = r_idx - 1 },
      Coord{ .x = max_x - 1, .y = r_idx },
      Coord{ .x = max_x - 1, .y = r_idx + 1 },
      Coord{ .x = max_x, .y = r_idx - 1 },
      Coord{ .x = max_x, .y = r_idx + 1 }
    });
    new_selection_data[r_idx * selection.width + max_x] = if (right_sum > 2) 1 else 0;
  }

  // middle
  r_idx = 0;
  while(r_idx < max_y) : (r_idx += 1) {
    c_idx = 0;
    while(c_idx < max_x) : (c_idx += 1) {
      const sum = sum_coords(.{
        Coord{ .y = r_idx - 1, .x = c_idx - 1 },
        Coord{ .y = r_idx - 1, .x = c_idx },
        Coord{ .y = r_idx - 1, .x = c_idx + 1 },
        Coord{ .y = r_idx, .x = c_idx - 1 },
        Coord{ .y = r_idx, .x = c_idx + 1 },
        Coord{ .y = r_idx + 1, .x = c_idx - 1 },
        Coord{ .y = r_idx + 1, .x = c_idx },
        Coord{ .y = r_idx + 1, .x = c_idx + 1 }
      });
      new_selection_data[r_idx * selection.width + c_idx] = if (sum > 3) 1 else 0;
    }
  }

  @memcpy(selection.data, new_selection_data);
}
