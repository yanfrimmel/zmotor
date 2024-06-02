const game = @import("api.zig");
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

    const screenWidth = intArgsHandler(&argsIterator, 640, "width");
    const screenHeight = intArgsHandler(&argsIterator, 480, "height");
    const fps = intArgsHandler(&argsIterator, 60, "fps");
    try game.Example.start(screenWidth, screenHeight, fps, allocator);
}

fn intArgsHandler(argsIterator: *std.process.ArgIterator, defaultSize: u16, str: []const u8) u16 {
    var size = defaultSize;
    if (argsIterator.next()) |arg| {
        size = std.fmt.parseInt(u16, arg, 10) catch |err| switch (err) {
            error.Overflow, error.InvalidCharacter => blk: {
                std.debug.print("{}: when parsing args\n", .{err});
                break :blk defaultSize;
            },
        };
        std.debug.print("Arg {s}: {d}\n", .{ str, size });
    }
    return size;
}
