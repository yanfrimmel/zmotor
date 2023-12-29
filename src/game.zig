const engine = @import("engine.zig");
const common = @import("common.zig");
const std = @import("std");

var screenWidth: u16 = undefined;
var screenHeight: u16 = undefined;

pub fn start(width: u16, height: u16, fps: u16, allocator: std.mem.Allocator) !void {
    const atlases = try allocator.create([1]common.Atlas);
    atlases[0].id = "tiles";
    atlases[0].path = "assets/dirt.png";
    defer allocator.destroy(atlases);
    screenHeight = height;
    screenWidth = width;
    try engine.start(allocator, width, height, fps, atlases, logic);
}
fn logic(allocator: std.mem.Allocator, input: ?common.InputEvent) *common.GraphicalGameState {
    var camera = common.Rectangle{
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
    var obj = common.GraphicalObject.init(allocator, position, common.Rectangle{
        .x = 0,
        .y = 0,
        .w = 32,
        .h = 32,
    }, "tiles") catch unreachable;
    var objects = [_]*common.GraphicalObject{obj};
    var state = common.GraphicalGameState.init(
        allocator,
        &objects,
        null,
        camera,
    ) catch unreachable;

    return state;
}
