const std = @import("std");
const capy = @import("capy");

// This is required for your app to build to WebAssembly and other particular architectures
pub usingnamespace capy.cross_platform;

pub fn main() !void {
    try capy.backend.init();

    var window = try capy.Window.init();
    try window.set(capy.Label(.{ .text = "Hello, World", .alignment = .Center }));

    window.setTitle("Hello");
    window.setPreferredSize(250, 100);
    window.show();

    capy.runEventLoop();
}
