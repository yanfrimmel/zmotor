const engine = @import("engine.zig");
const common = @import("common.zig");

pub fn start(width: u16, height: u16) !void {
    try engine.start(width, height, logic);
}

fn logic(input: ?common.InputEvent) common.GraphicalGameState {
    _ = input;
    return .{
        .objects = null,
        .screenCenterPoint = null,
    };
}
