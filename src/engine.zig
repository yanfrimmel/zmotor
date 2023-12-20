const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});

const assert = @import("std").debug.assert;
const common = @import("common.zig");
const std = @import("std");

pub fn start(allocator: std.mem.Allocator, width: u16, height: u16, atlases: []common.Atlas, logic: *const fn (input: ?common.InputEvent) common.GraphicalGameState) !void {
    try initSdl();
    defer sdl.SDL_Quit();
    defer sdl.IMG_Quit();

    const window = try initWindow(width, height);
    defer sdl.SDL_DestroyWindow(window);

    const renderer = try initRenderer(window);
    defer sdl.SDL_DestroyRenderer(renderer);

    try gameLoop(allocator, renderer, atlases, logic);
}

fn initRenderer(window: *sdl.SDL_Window) !*sdl.SDL_Renderer {
    const renderer = sdl.SDL_CreateRenderer(window, -1, 0) orelse {
        sdl.SDL_Log("Unable to create renderer: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    return renderer;
}

fn initWindow(width: u16, height: u16) !*sdl.SDL_Window {
    const window = sdl.SDL_CreateWindow("My Game Window", sdl.SDL_WINDOWPOS_UNDEFINED, sdl.SDL_WINDOWPOS_UNDEFINED, width, height, sdl.SDL_WINDOW_OPENGL) orelse
        {
        sdl.SDL_Log("Unable to create window: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    return window;
}

fn initSdl() !void {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_EVENTS) < 0) {
        sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    }

    if ((sdl.IMG_Init(sdl.IMG_INIT_PNG) & sdl.IMG_INIT_PNG) == 0) {
        sdl.SDL_Log("Unable to initialize SDL Image: %s", sdl.IMG_GetError());
        return error.SDLInitializationFailed;
    }
}

fn gameLoop(allocator: std.mem.Allocator, renderer: *sdl.SDL_Renderer, atlases: []common.Atlas, logic: *const fn (input: ?common.InputEvent) common.GraphicalGameState) !void {
    var atlasMap = std.StringHashMap(*sdl.SDL_Texture).init(allocator);
    for (atlases) |atlas| {
        const atlasTexture = sdl.IMG_LoadTexture(renderer, @ptrCast(atlas.path)) orelse {
            sdl.SDL_Log("Unable to load textutre: %s", sdl.IMG_GetError());
            return error.SDLInitializationFailed;
        };
        try atlasMap.put(atlas.id, atlasTexture);
    }

    defer {
        var it = atlasMap.valueIterator();
        while (it.next()) |value| {
            sdl.SDL_DestroyTexture(value.*);
        }
        atlasMap.deinit();
    }

    var quit = false;
    while (!quit) {
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl.SDL_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }
        try draw(logic(null));
        // TODO: draw state

        _ = sdl.SDL_RenderClear(renderer);
        _ = sdl.SDL_RenderCopy(renderer, atlasMap.get("tiles"), null, null);
        sdl.SDL_RenderPresent(renderer);

        sdl.SDL_Delay(17);
    }
}

pub fn draw(state: common.GraphicalGameState) !void {
    _ = state;
}
