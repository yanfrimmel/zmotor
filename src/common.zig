pub const Point = struct {
    x: u16,
    y: u16,
};

pub const Sprite = struct {
    id: []const u8,
    size: Point, // To fetch the right area from the atlas
    positionInAtlas: Point, // To fetch the right area from atlas
    atlas: []const u8, // Could be multiple atlases, based on sprite sizes or animations
};

pub const GraphicalObject = struct {
    sprite: ?*Sprite, // If the object is off screen it's sprite will not be used
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
    MOUSE_CLICK,
};
