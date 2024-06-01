const engine = @import("engine.zig");
const common = @import("common.zig");
const std = @import("std");

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
    try engine.start(allocator, width, height, fps, atlases, fonts, logic);
}
fn logic(allocator: std.mem.Allocator, input: ?common.InputEvent) *common.GraphicalGameState {
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
