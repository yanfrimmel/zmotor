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

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

pub const Font = struct {
    id: []const u8,
    path: []const u8,

    pub fn init(allocator: std.mem.Allocator, id: []const u8, path: []const u8) !*Font {
        const self = try allocator.create(Font);
        self.id = try allocator.alloc(u8, id.len);
        @memcpy(self.id, id);
        self.path = try allocator.alloc(u8, path.len);
        @memcpy(self.path, path);
        return self;
    }

    pub fn deinit(self: *Font, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.path);
        allocator.destroy(self);
    }
};

pub const TextObject = struct {
    font: []u8,
    position: Point,
    text: []u8,
    color: Color,

    pub fn init(allocator: std.mem.Allocator, font: []const u8, position: Point, text: []const u8, color: Color) !*TextObject {
        const self = try allocator.create(TextObject);
        self.font = try allocator.alloc(u8, font.len);
        @memcpy(self.font, font);
        self.position = position;
        self.text = try allocator.alloc(u8, text.len);
        @memcpy(self.text, text);
        self.color = color;
        return self;
    }

    pub fn deinit(self: *TextObject, allocator: std.mem.Allocator) void {
        allocator.free(self.font);
        allocator.free(self.text);
        allocator.destroy(self);
    }
};

pub const GraphicalObject = struct {
    position: Point, // Location in the world
    positionInAtlas: Rectangle, // To fetch the right area from atlas
    atlas: []u8, // There could be multiple atlases, based on sprite sizes or animations

    pub fn init(allocator: std.mem.Allocator, position: Point, positionInAtlas: Rectangle, atlas: []const u8) !*GraphicalObject {
        const self = try allocator.create(GraphicalObject);
        self.position = position;
        self.positionInAtlas = positionInAtlas;
        self.atlas = try allocator.alloc(u8, atlas.len);
        @memcpy(self.atlas, atlas);
        return self;
    }

    pub fn deinit(self: *GraphicalObject, allocator: std.mem.Allocator) void {
        allocator.free(self.atlas);
        allocator.destroy(self);
    }
};

pub const GraphicalGameState = struct {
    objects: ?[]*GraphicalObject,
    texts: ?[]*TextObject,
    camera: Rectangle,
    // call init to allocate memory for pointer elements outside of this init
    pub fn init(allocator: std.mem.Allocator, objects: ?[]*GraphicalObject, texts: ?[]*TextObject, camera: Rectangle) !*GraphicalGameState {
        const self = try allocator.create(GraphicalGameState);
        if (objects) |objectsUnbox| {
            self.objects = try allocator.alloc(*GraphicalObject, objectsUnbox.len);
            @memcpy(self.objects.?, objectsUnbox);
        } else {
            self.objects = null;
        }

        if (texts) |textsUnbox| {
            self.texts = try allocator.alloc(*TextObject, textsUnbox.len);
            @memcpy(self.texts.?, textsUnbox);
        } else {
            self.texts = null; // will not work without this - seg fault if null passed
        }

        self.camera = camera;

        return self;
    }

    pub fn deinit(self: *GraphicalGameState, allocator: std.mem.Allocator) void {
        if (self.objects) |objects| {
            for (objects) |obj| {
                obj.deinit(allocator);
            }
            allocator.free(objects);
        }
        if (self.texts) |texts| {
            for (texts) |text| {
                text.deinit(allocator);
            }
            allocator.free(texts);
        }
        allocator.destroy(self);
    }
};

pub const InputEvent = struct {
    position: ?Point,
    eventType: EventType,
};

pub const EventType = enum {
    CLICK,
    MOTION,
};

pub const LogicFuncType = fn (input: ?InputEvent, allocator: std.mem.Allocator) *GraphicalGameState;
