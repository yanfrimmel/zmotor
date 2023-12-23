const engine = @import("engine.zig");
const common = @import("common.zig");
const std = @import("std");

var screenWidth: u16 = undefined;
var screenHeight: u16 = undefined;

pub fn start(width: u16, height: u16, allocator: std.mem.Allocator) !void {
    const atlases = try allocator.create([1]common.Atlas);
    atlases[0].id = "tiles";
    atlases[0].path = "assets/dirt.png";
    defer allocator.destroy(atlases);
    screenHeight = height;
    screenWidth = width;
    try engine.start(allocator, width, height, atlases, logic);
}
fn logic(allocator: std.mem.Allocator, input: ?common.InputEvent) *common.GraphicalGameState {
    _ = input; //TODO: handle input
    var obj = common.GraphicalObject.init(allocator, "test", common.Point{ .x = 0, .y = 0 }, 1, common.Rectangle{
        .x = 0,
        .y = 0,
        .w = 32,
        .h = 32,
    }, "tiles") catch unreachable;
    var objects = [_]*common.GraphicalObject{obj};
    var state = common.GraphicalGameState.init(
        allocator,
        &objects,
        common.Rectangle{
            .x = 0,
            .y = 0,
            .w = screenWidth,
            .h = screenHeight,
        },
    ) catch unreachable;

    return state;
}
