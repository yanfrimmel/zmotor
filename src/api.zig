const engine = @import("engine.zig");
const common = @import("common.zig");
const std = @import("std");

//Inteface
pub const Api = struct {
    logicFn: common.LogicFuncType,

    pub fn start(self: Api, width: u16, height: u16, fps: u16, atlases: []common.Atlas, allocator: std.mem.Allocator) !void {
        try engine.start(allocator, width, height, fps, atlases, self.logicFn);
    }
};
