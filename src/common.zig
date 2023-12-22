const std = @import("std");

pub const Point = struct {
    x: u16,
    y: u16,
};

pub const Rectangle = struct {
    x: u16,
    y: u16,
    w: u16,
    h: u16,
};

pub const Atlas = struct {
    id: []const u8,
    path: []const u8,
};

pub const GraphicalObject = struct {
    id: []u8,
    position: *Point, // Location in the world
    layer: *u8, // Controls the order in which the sprites renders, a sprite with high `layer` will dispaly in front of others
    positionInAtlas: *Rectangle, // To fetch the right area from atlas
    atlas: []u8, // There could be multiple atlases, based on sprite sizes or animations

    pub fn init(allocator: std.mem.Allocator, id: []const u8, position: Point, layer: u8, positionInAtlas: Rectangle, atlas: []const u8) !*GraphicalObject {
        const objectPtr = try allocator.create(GraphicalObject);
        objectPtr.id = try allocator.alloc(u8, id.len);
        std.mem.copy(u8, objectPtr.id, id);

        objectPtr.position = try allocator.create(Point);
        objectPtr.position.* = position;

        objectPtr.layer = try allocator.create(u8);
        objectPtr.layer.* = layer;
        objectPtr.positionInAtlas = try allocator.create(Rectangle);
        objectPtr.positionInAtlas.* = positionInAtlas;

        objectPtr.atlas = try allocator.alloc(u8, atlas.len);
        std.mem.copy(u8, objectPtr.atlas, atlas);
        return objectPtr;
    }

    pub fn deinit(self: *GraphicalObject, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.destroy(self.position);
        allocator.destroy(self.layer);
        allocator.destroy(self.positionInAtlas);
        allocator.free(self.atlas);
        allocator.destroy(self);
    }
};

pub const GraphicalGameState = struct {
    objects: ?[]*GraphicalObject,
    camera: *Rectangle,

    pub fn init(allocator: std.mem.Allocator, objects: ?[]*GraphicalObject, camera: Rectangle) !*GraphicalGameState {
        const statePtr = try allocator.create(GraphicalGameState);
        if (objects) |objectsUnbox| {
            statePtr.objects = try allocator.alloc(*GraphicalObject, objectsUnbox.len);
            std.mem.copy(*GraphicalObject, statePtr.objects.?, objectsUnbox);
        }

        statePtr.camera = try allocator.create(Rectangle);
        statePtr.camera.* = camera;

        return statePtr;
    }

    pub fn deinit(self: *GraphicalGameState, allocator: std.mem.Allocator) void {
        if (self.objects) |objects| {
            for (objects) |*obj| {
                obj.*.deinit(allocator);
            }
            allocator.free(objects);
        }
        allocator.destroy(self.camera);
        allocator.destroy(self);
    }
};

pub const InputEvent = struct {
    position: ?Point,
    eventType: EventType,
};

pub const EventType = enum {
    CLICK,
};
