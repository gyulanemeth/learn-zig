const RgbPixel = @import("./convert.zig").RgbPixel;

pub const Coord = struct { x: u32, y: u32 };

pub const ImageData = struct {
  height: u32,
  width: u32,
  data: []u8,

  fn get_pixel(self: *ImageData, coord: Coord) RgbPixel {
    const red_idx = (coord.y * self.width + coord.x) * 4;

    return RgbPixel{ .r = self.data[red_idx], .g = self.data[red_idx + 1], .b = self.data[red_idx + 2], .a = self.data[red_idx + 3] };
  }

  fn set_pixel(self: *ImageData, coord: Coord, rgb_pixel: RgbPixel) void {
    const red_idx: usize = (coord.y * self.width + coord.x) * 4;
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
    var imgData = ImageData{ .width = 3, .height = 2, .data = byteArray[0..byteArray.len] };

    const rgb_pixel = imgData.get_pixel(Coord{ .x = 2, .y = 1 });
    try expect(rgb_pixel.r == 20);
    try expect(rgb_pixel.g == 21);
    try expect(rgb_pixel.b == 22);
    try expect(rgb_pixel.a == 23);
}

test "set_pixel" {
  var byteArray = [1]u8{0} ** 24;

  var imgData = ImageData{ .width = 3, .height = 2, .data = byteArray[0..byteArray.len] };

  imgData.set_pixel(Coord{ .x = 2, .y = 0 }, RgbPixel{ .r = 200, .g = 50, .b = 100, .a = 255 });

  var rgb_pixel = imgData.get_pixel(Coord{ .x = 2, .y = 0 });

  try expect(rgb_pixel.r == 200);
  try expect(rgb_pixel.g == 50);
  try expect(rgb_pixel.b == 100);
  try expect(rgb_pixel.a == 255);
}
