const std = @import("std");
const ArrayList = std.ArrayList;
const expect = std.testing.expect;
const eql = std.mem.eql;
const test_allocator = std.testing.allocator;

const img_data = @import("./ImageData.zig");
const Coord = img_data.Coord;
const ImageData = img_data.ImageData;

const convert = @import("./convert.zig");

const RgbPixel = convert.RgbPixel;
const HslPixel = convert.HslPixel;
const rgb_to_hsl = convert.rgb_to_hsl;
const hsl_to_rgb = convert.hsl_to_rgb;

const SelectionData = struct { width: u32, height: u32, data: []u8 };

pub var selection: SelectionData = undefined;

pub fn init(allocator: std.mem.Allocator ,width: u32, height: u32) void {
    const length = height * width;
    var data = allocator.alloc(u8, length) catch unreachable;
    for (data, 0..) |_, idx| {
      data[idx] = 0;
    }

    selection = SelectionData{ .width = width, .height = height, .data = data };
}

pub fn deinit(allocator: std.mem.Allocator) void {
    allocator.free(selection.data);
}

pub fn select_all() void {
    for (selection.data, 0..) |_, idx| {
        selection.data[idx] = 1;
    }
}

test "select all" {
  init(test_allocator, 3, 3);
  defer deinit(test_allocator);
  select_all();
  const expected_data: [9]u8 = .{ 1, 1, 1, 1, 1, 1, 1, 1, 1 };
  try expect(eql(u8, selection.data[0..selection.data.len], &expected_data));
}

pub fn deselect_all() void {
    for (selection.data, 0..) |_, idx| {
        selection.data[idx] = 0;
    }
}

test "deselect all" {
  init(test_allocator, 3, 3);
  defer deinit(test_allocator);

  selection.data[2] = 1;
  selection.data[3] = 1;
  selection.data[5] = 1;
  selection.data[7] = 1;

  deselect_all();
  const expected_data: [9]u8 = .{ 0, 0, 0, 0, 0, 0, 0, 0, 0 };
  try expect(eql(u8, selection.data[0..selection.data.len], &expected_data));
}

pub fn invert() void {
    for (selection.data, 0..) |value, idx| {
        selection.data[idx] = 1 - value;
    }
}

test "invert" {
  init(test_allocator, 3, 3);
  defer deinit(test_allocator);

  selection.data[2] = 1;
  selection.data[3] = 1;
  selection.data[5] = 1;
  selection.data[7] = 1;

  invert();
  const expected_data: [9]u8 = .{ 1, 1, 0, 0, 1, 0, 1, 0, 1 };
  try expect(eql(u8, selection.data[0..selection.data.len], &expected_data));
}

pub fn rectangular_selection(from: Coord, to: Coord) void {
    const from_y = @max(@min(from.y, to.y), 0);
    const to_y = @min(@max(from.y, to.y), selection.height - 1);

    const from_x = @max(@min(from.x, to.x), 0);
    const to_x = @min(@max(from.x, to.x), selection.width - 1);

    var y_idx: u32 = from_y;
    while (y_idx <= to_y) : (y_idx += 1) {
        var x_idx: u32 = from_x;
        while (x_idx <= to_x) : (x_idx += 1) {
            selection.data[y_idx * selection.width + x_idx] = 1;
        }
    }
}

test "rectangular_selection" {
  init(test_allocator, 6, 5);
  defer deinit(test_allocator);

  const from1 = Coord{ .x = 1, .y = 2 };
  const to1 = Coord{ .x = 3, .y = 3 };

  rectangular_selection(from1, to1);

  const expected_data1: [30]u8 = .{
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0,
    0, 1, 1, 1, 0, 0,
    0, 1, 1, 1, 0, 0,
    0, 0, 0, 0, 0, 0
  };

  try expect(eql(u8, selection.data[0..selection.data.len], &expected_data1));

  const from2 = Coord{ .x = 0, .y = 0 };
  const to2 = Coord{ .x = 1, .y = 1 };

  rectangular_selection(from2, to2);

  const expected_data2: [30]u8 = .{
    1, 1, 0, 0, 0, 0,
    1, 1, 0, 0, 0, 0,
    0, 1, 1, 1, 0, 0,
    0, 1, 1, 1, 0, 0,
    0, 0, 0, 0, 0, 0
  };
  try expect(eql(u8, selection.data[0..selection.data.len], &expected_data2));
}

pub fn setSelectionBasedOnHslRange(allocator: std.mem.Allocator, img: ImageData, coord: Coord, range: HslPixel, value: u8) void {
    const rgb_start_px = img.get_pixel(coord);
    const hsl_start_px = rgb_to_hsl(rgb_start_px);

    const h_min = hsl_start_px.hue - range.hue;
    const h_max = hsl_start_px.hue + range.hue;
    const l_min = hsl_start_px.l - range.l;
    const l_max = hsl_start_px.l + range.l;
    const s_min = hsl_start_px.s - range.s;
    const s_max = hsl_start_px.s + range.s;

    const visited = allocator.alloc(u8, img.width * img.height) catch unreachable;
    defer allocator.free(visited);

    const coords_to_visit = ArrayList(Coord).init(allocator);
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

pub fn setSelectionBasedOnNeighbouringHslRange(allocator: std.mem.Allocator, img: ImageData, coord: Coord, range: HslPixel, value: u8) void {
    const visited = allocator.alloc(u8, img.width * img.height);
    defer allocator.free(visited);

    const coords_to_visit = ArrayList(Coord).init(allocator);
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

fn sum_coords(coords: []const Coord) u8 {
  var sum: u8 = 0;

  for(coords) |coord| {
    sum += selection.data[coord.y * selection.width + coord.x];
  }

  return sum;
}

pub fn dilate(allocator: std.mem.Allocator) void {
  var new_selection_data = allocator.alloc(u8, selection.width * selection.height) catch unreachable;
  defer allocator.free(new_selection_data);

  const max_x = selection.width - 1;
  const max_y = selection.height - 1;

  // top-left corner
  if (selection.data[0] == 1) {
    new_selection_data[0] = 1;
  } else {
    const tlSum = sum_coords(&[3]Coord{
      Coord{ .x = 0, .y = 1 },
      Coord{ .x = 1, .y = 0 },
      Coord{ .x = 1, .y = 1 }
    });
    new_selection_data[0] = if (tlSum > 1) 1 else 0;
  }

  // top-right corner
  if (selection.data[max_x] == 1) {
    new_selection_data[max_x] = 1;
  } else {
    const trSum = sum_coords(&[3]Coord{
      Coord{ .x = max_x, .y = 1 },
      Coord{ .x = max_x - 1, .y = 0 },
      Coord{ .x = max_x - 1, .y = 1 }
    });
    new_selection_data[max_x] = if (trSum > 1) 1 else 0;
  }

  // bottom-left corner
  if (selection.data[max_y * selection.width] == 1) {
    new_selection_data[max_y * selection.width] = 1;
  } else {
    const blSum = sum_coords(&[3]Coord{
      Coord{ .x = 0, .y = max_y - 1 },
      Coord{ .x = 1, .y = max_y },
      Coord{ .x = 1, .y = max_y - 1 }
    });
    new_selection_data[max_y * selection.width] = if (blSum > 1) 1 else 0;
  } 

  // bottom-right corner
  if (selection.data[max_y * selection.width + max_x] == 1) {
    new_selection_data[max_y * selection.width + max_x] = 1;
  } else {
    const brSum = sum_coords(&[3]Coord{
      Coord{ .x = max_x, .y = max_y - 1 },
      Coord{ .x = max_x - 1, .y = max_y },
      Coord{ .x = max_x - 1, .y = max_y - 1 }
    });
    new_selection_data[max_y * selection.width + max_x] = if (brSum > 1) 1 else 0;
  } 

  // top & bottom edges
  var c_idx: u32 = 1;
  while (c_idx < max_x) : (c_idx += 1) {
    if (selection.data[c_idx] == 1) {
      new_selection_data[c_idx] = 1;
    } else {
      const top_sum = sum_coords(&[5]Coord{
        Coord{ .x = c_idx - 1, .y = 0 },
        Coord{ .x = c_idx + 1, .y = 0 },
        Coord{ .x = c_idx - 1, .y = 1 },
        Coord{ .x = c_idx, .y = 1 },
        Coord{ .x = c_idx + 1, .y = 1 }
      });
      new_selection_data[c_idx] = if (top_sum > 2) 1 else 0;
    }

    if (selection.data[max_y * selection.width + c_idx] == 1) {
      new_selection_data[max_y * selection.width + c_idx] = 1;
    } else {
      const bottom_sum = sum_coords(&[5]Coord{
        Coord{ .x = c_idx - 1, .y = max_y - 1 },
        Coord{ .x = c_idx, .y = max_y - 1 },
        Coord{ .x = c_idx + 1, .y = max_y - 1 },
        Coord{ .x = c_idx - 1, .y = max_y },
        Coord{ .x = c_idx + 1, .y = max_y }
      });
      new_selection_data[max_y * selection.width + c_idx] = if (bottom_sum > 2) 1 else 0;
    }
  }

  // left & right edges
  var r_idx: u32 = 1;
  while (r_idx < max_y) : (r_idx += 1) {
    if (selection.data[r_idx * selection.width] == 1) {
      new_selection_data[r_idx * selection.width] = 1;
    } else {
      const left_sum = sum_coords(&[5]Coord{
        Coord{ .x = 0, .y = r_idx - 1 },
        Coord{ .x = 0, .y = r_idx + 1 },
        Coord{ .x = 1, .y = r_idx - 1 },
        Coord{ .x = 1, .y = r_idx },
        Coord{ .x = 1, .y = r_idx + 1 }
      });
      new_selection_data[r_idx * selection.width] = if (left_sum > 2) 1 else 0;
    }

    if (selection.data[r_idx * selection.width + max_x] == 1) {
      new_selection_data[r_idx * selection.width + max_x] = 1;
    } else {
      const right_sum = sum_coords(&[5]Coord{
        Coord{ .x = max_x - 1, .y = r_idx - 1 },
        Coord{ .x = max_x - 1, .y = r_idx },
        Coord{ .x = max_x - 1, .y = r_idx + 1 },
        Coord{ .x = max_x, .y = r_idx - 1 },
        Coord{ .x = max_x, .y = r_idx + 1 }
      });
      new_selection_data[r_idx * selection.width + max_x] = if (right_sum > 2) 1 else 0;
    }
  }

  // middle
  r_idx = 1;
  while(r_idx < max_y) : (r_idx += 1) {
    c_idx = 1;
    while(c_idx < max_x) : (c_idx += 1) {
      // ide is if
      if (selection.data[r_idx * selection.width + c_idx] == 1) {
        new_selection_data[r_idx * selection.width + c_idx] = 1;
      } else {
        const sum = sum_coords(&[8]Coord{
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
  }

  @memcpy(selection.data, new_selection_data);
}

test "dilate - corners" {
  init(test_allocator, 3, 3);
  defer deinit(test_allocator);

  // top left
  // 0 1 0
  // 1 0 0
  // 0 0 0
  selection.data[1] = 1;
  selection.data[3] = 1;
  dilate(test_allocator);

  // 1 1 0
  // 1 0 0
  // 0 0 0
  try expect(selection.data[0] == 1);
  try expect(selection.data[1] == 1);
  try expect(selection.data[2] == 0);
  try expect(selection.data[3] == 1);
  try expect(selection.data[4] == 0);
  try expect(selection.data[5] == 0);
  try expect(selection.data[6] == 0);
  try expect(selection.data[7] == 0);
  try expect(selection.data[8] == 0);

  deselect_all();

  // top-right
  // 0 1 0
  // 0 0 1
  // 0 0 0
  selection.data[1] = 1;
  selection.data[5] = 1;
  dilate(test_allocator);

  // 0 1 1
  // 0 0 1
  // 0 0 0
  try expect(selection.data[0] == 0);
  try expect(selection.data[1] == 1);
  try expect(selection.data[2] == 1);
  try expect(selection.data[3] == 0);
  try expect(selection.data[4] == 0);
  try expect(selection.data[5] == 1);
  try expect(selection.data[6] == 0);
  try expect(selection.data[7] == 0);
  try expect(selection.data[8] == 0);

  deselect_all();

  // bottom-right
  // 0 0 0
  // 0 0 1
  // 0 1 0
  selection.data[5] = 1;
  selection.data[7] = 1;
  dilate(test_allocator);

  // 0 0 0
  // 0 0 1
  // 0 1 1
  try expect(selection.data[0] == 0);
  try expect(selection.data[1] == 0);
  try expect(selection.data[2] == 0);
  try expect(selection.data[3] == 0);
  try expect(selection.data[4] == 0);
  try expect(selection.data[5] == 1);
  try expect(selection.data[6] == 0);
  try expect(selection.data[7] == 1);
  try expect(selection.data[8] == 1);

  deselect_all();

  // bottom-left
  // 0 0 0
  // 1 0 0
  // 0 1 0
  selection.data[3] = 1;
  selection.data[7] = 1;
  dilate(test_allocator);

  // 0 0 0
  // 1 0 0
  // 1 1 0
  try expect(selection.data[0] == 0);
  try expect(selection.data[1] == 0);
  try expect(selection.data[2] == 0);
  try expect(selection.data[3] == 1);
  try expect(selection.data[4] == 0);
  try expect(selection.data[5] == 0);
  try expect(selection.data[6] == 1);
  try expect(selection.data[7] == 1);
  try expect(selection.data[8] == 0);

  deselect_all();


  // top-right & top-left
  // 0 1 0
  // 0 1 0
  // 0 0 0
  selection.data[1] = 1;
  selection.data[4] = 1;
  dilate(test_allocator);

  // 1 1 1
  // 0 1 0
  // 0 0 0
  try expect(selection.data[0] == 1);
  try expect(selection.data[1] == 1);
  try expect(selection.data[2] == 1);
  try expect(selection.data[3] == 0);
  try expect(selection.data[4] == 1);
  try expect(selection.data[5] == 0);
  try expect(selection.data[6] == 0);
  try expect(selection.data[7] == 0);
  try expect(selection.data[8] == 0);

  deselect_all();

  // top-left & bottom-left
  // 0 0 0
  // 0 1 1
  // 0 0 0
  selection.data[4] = 1;
  selection.data[5] = 1;
  dilate(test_allocator);

  // 0 0 1
  // 0 1 1
  // 0 0 1
  try expect(selection.data[0] == 0);
  try expect(selection.data[1] == 0);
  try expect(selection.data[2] == 1);
  try expect(selection.data[3] == 0);
  try expect(selection.data[4] == 1);
  try expect(selection.data[5] == 1);
  try expect(selection.data[6] == 0);
  try expect(selection.data[7] == 0);
  try expect(selection.data[8] == 1);

  deselect_all();

  // bottom-left & bottom-right
  // 0 0 0
  // 0 1 0
  // 0 1 0
  selection.data[4] = 1;
  selection.data[7] = 1;
  dilate(test_allocator);

  // 0 0 0
  // 0 1 0
  // 1 1 1
  try expect(selection.data[0] == 0);
  try expect(selection.data[1] == 0);
  try expect(selection.data[2] == 0);
  try expect(selection.data[3] == 0);
  try expect(selection.data[4] == 1);
  try expect(selection.data[5] == 0);
  try expect(selection.data[6] == 1);
  try expect(selection.data[7] == 1);
  try expect(selection.data[8] == 1);

  deselect_all();

  // bottom-right & top-right
  // 0 0 0
  // 1 1 0
  // 0 0 0
  selection.data[3] = 1;
  selection.data[4] = 1;
  dilate(test_allocator);

  // 1 0 0
  // 1 1 0
  // 1 0 0
  try expect(selection.data[0] == 1);
  try expect(selection.data[1] == 0);
  try expect(selection.data[2] == 0);
  try expect(selection.data[3] == 1);
  try expect(selection.data[4] == 1);
  try expect(selection.data[5] == 0);
  try expect(selection.data[6] == 1);
  try expect(selection.data[7] == 0);
  try expect(selection.data[8] == 0);
}
