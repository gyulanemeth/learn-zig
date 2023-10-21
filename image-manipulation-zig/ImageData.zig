const RgbPixel = @import("./convert.zig").RgbPixel;

pub const ImageData = struct {
  n_rows: u32,
  n_cols: u32,
  data: []u8,

  fn get_pixel(self: *ImageData, r_idx: usize, c_idx: usize) RgbPixel {
    const red_idx = (r_idx * self.n_cols + c_idx) * 4;

    return RgbPixel{ .r = self.data[red_idx], .g = self.data[red_idx + 1], .b = self.data[red_idx + 2], .a = self.data[red_idx + 3] };
  }

  fn set_pixel(self: *ImageData, r_idx: usize, c_idx: usize, rgb_pixel: RgbPixel) void {
    const red_idx: usize = (r_idx * self.n_cols + c_idx) * 4;
    self.data[red_idx] = rgb_pixel.r;
    self.data[red_idx + 1] = rgb_pixel.g;
    self.data[red_idx + 2] = rgb_pixel.b;
    self.data[red_idx + 3] = rgb_pixel.a;
  }
};

const expect = @import("std").testing.expect;

test "get_pixel" {
    var byteArray = [1]u8{0} ** 24;
    for (0..byteArray.len) |idx| {
      byteArray[idx] = @intCast(idx);
    }
    var imgData = ImageData{ .n_cols = 2, .n_rows = 3, .data = byteArray[0..byteArray.len] };

    const rgb_pixel = imgData.get_pixel(1, 2);
    try expect(rgb_pixel.r == 16);
    try expect(rgb_pixel.g == 17);
    try expect(rgb_pixel.b == 18);
    try expect(rgb_pixel.a == 19);
}

test "set_pixel" {
  var byteArray = [1]u8{0} ** 24;

  var imgData = ImageData{ .n_cols = 2, .n_rows = 3, .data = byteArray[0..byteArray.len] };

  imgData.set_pixel(0, 2, RgbPixel{ .r = 200, .g = 50, .b = 100, .a = 255 });

  var rgb_pixel = imgData.get_pixel(0, 2);

  try expect(rgb_pixel.r == 200);
  try expect(rgb_pixel.g == 50);
  try expect(rgb_pixel.b == 100);
  try expect(rgb_pixel.a == 255);
}
