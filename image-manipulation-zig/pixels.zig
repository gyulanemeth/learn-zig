pub fn get_pixel(ImageData imgData, r_idx: usize, c_idx: usize) RgbPixel {
    const red_idx = (r_idx * imgData.n_cols + c_idx) * 4;

    return RgbPixel{ .r = imgData.data[red_idx], .g = imgData.data[red_idx + 1], .b = imgData.data[red_idx + 2], .a = imgData.data[red_idx + 3] };
}

pub fn set_pixel(ImageData imgData, r_idx: usize, c_idx: usize, r: u8, g: u8, b: u8, a: u8) void {
    const red_idx: usize = (r_idx * imgData.n_cols + c_idx) * 4;
    imgData.data[red_idx] = r;
    imgData.data[red_idx + 1] = g;
    imgData.data[red_idx + 2] = b;
    imgData.data[red_idx + 3] = a;
}
