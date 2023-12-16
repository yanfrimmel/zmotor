const game = @import("game.zig");
const std = @import("std");

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);
    // Initialize arguments
    // Then deinitialize at the end of scope
    var argsIterator = try std.process.ArgIterator.initWithAllocator(allocator);
    defer argsIterator.deinit();
    _ = argsIterator.next(); // Skip executable

    const screenWidth = windowSizeArgsHandler(&argsIterator, 400, "width");
    const screenHeight = windowSizeArgsHandler(&argsIterator, 140, "height");

    try game.start(screenWidth, screenHeight);
}

fn windowSizeArgsHandler(argsIterator: *std.process.ArgIterator, defaultSize: u16, str: []const u8) u16 {
    var size = defaultSize;
    if (argsIterator.next()) |arg| {
        size = std.fmt.parseInt(u16, arg, 10) catch |err| switch (err) {
            error.Overflow, error.InvalidCharacter => blk: {
                std.debug.print("{}: when parsing args\n", .{err});
                break :blk defaultSize;
            },
        };
        std.debug.print("Screen {s}:  {d}\n", .{ str, size });
    }
    return size;
}
