const engine = @import("engine.zig");
const common = @import("common.zig");
const std = @import("std");

pub fn start(width: u16, height: u16, allocator: std.mem.Allocator) !void {
    const atlases = try allocator.create([1]common.Atlas);
    atlases[0].id = "tiles";
    atlases[0].path = "assets/dirt.png";
    // = common.Atlas{ .id = "tiles", .path = "assets/dirt.png" };
    defer allocator.destroy(atlases);
    try engine.start(allocator, width, height, atlases, logic);
}

fn logic(input: ?common.InputEvent) common.GraphicalGameState {
    _ = input;
    return .{
        .objects = null,
        .screenCenterPoint = null,
    };
}
