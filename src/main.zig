const api = @import("api.zig");
const common = @import("common.zig");
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
    try Example.start(screenWidth, screenHeight, fps, allocator);
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
pub const Example = struct {
    var screenWidth: u16 = undefined;
    var screenHeight: u16 = undefined;

    pub fn start(width: u16, height: u16, fps: u16, allocator: std.mem.Allocator) !void {
        const atlases = try allocator.alloc(common.Atlas, 1);
        atlases[0].id = "tiles";
        atlases[0].path = "assets/dirt.png";
        defer allocator.free(atlases);

        const fonts = try allocator.alloc(common.Font, 1);
        fonts[0].id = "fonts";
        fonts[0].path = "assets/ObliviousFont.ttf";
        defer allocator.free(fonts);

        screenHeight = height;
        screenWidth = width;

        const apiExample: api.Api = api.Api{ .logicFn = exampleLogic };
        try apiExample.start(width, height, fps, atlases, fonts, allocator);
    }

    fn exampleLogic(input: ?common.InputEvent, allocator: std.mem.Allocator) *common.GraphicalGameState {
        const camera = common.Rectangle{
            .x = 0,
            .y = 0,
            .w = screenWidth,
            .h = screenHeight,
        };
        var position = common.Point{ .x = 0, .y = 0 };

        if (input) |in| {
            position = switch (in.eventType) {
                common.EventType.MOTION => common.Point{
                    .x = in.position.?.x,
                    .y = in.position.?.y,
                },
                common.EventType.CLICK => common.Point{
                    .x = in.position.?.x,
                    .y = in.position.?.y,
                },
            };
        }
        const obj = common.GraphicalObject.init(allocator, position, common.Rectangle{
            .x = 0,
            .y = 0,
            .w = 32,
            .h = 32,
        }, "tiles") catch unreachable;
        var objects = [_]*common.GraphicalObject{obj};
        const state = common.GraphicalGameState.init(
            allocator,
            &objects,
            null,
            camera,
        ) catch unreachable;

        return state;
    }
};
