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

pub const Sprite = struct {
    id: []const u8,
    positionInAtlas: Rectangle, // To fetch the right area from atlas
    atlas: []const u8, // Could be multiple atlases, based on sprite sizes or animations
};

pub const GraphicalObject = struct {
    spriteId: []const u8,
    location: Point, // Location in the world
    layer: u8, // Controls the order in which the sprites renders, a sprite with high `layer` will dispaly in front of others
};

pub const GraphicalGameState = struct {
    objects: ?[]GraphicalObject,
    screenCenterPoint: ?Point, //To calc what to draw based on screen position
};

pub const InputEvent = struct {
    position: ?Point,
    eventType: EventType,
};

pub const EventType = enum {
    CLICK,
};
