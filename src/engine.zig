const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});

const assert = @import("std").debug.assert;
const common = @import("common.zig");

pub fn start(width: u16, height: u16, logic: *const fn (input: ?common.InputEvent) common.GraphicalGameState) !void {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_EVENTS) < 0) {
        sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer sdl.SDL_Quit();

    if (sdl.IMG_Init(sdl.IMG_INIT_PNG) < 0) {
        sdl.SDL_Log("Unable to initialize SDL Image: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer sdl.IMG_Quit();

    const screen = sdl.SDL_CreateWindow("My Game Window", sdl.SDL_WINDOWPOS_UNDEFINED, sdl.SDL_WINDOWPOS_UNDEFINED, width, height, sdl.SDL_WINDOW_OPENGL) orelse
        {
        sdl.SDL_Log("Unable to create window: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer sdl.SDL_DestroyWindow(screen);

    const renderer = sdl.SDL_CreateRenderer(screen, -1, 0) orelse {
        sdl.SDL_Log("Unable to create renderer: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer sdl.SDL_DestroyRenderer(renderer);

    const example = @embedFile("../assets/dirt.png");
    const rw = sdl.SDL_RWFromConstMem(example, example.len) orelse {
        sdl.SDL_Log("Unable to get RWFromConstMem: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer assert(sdl.SDL_RWclose(rw) == 0);

    const exampleSurface = sdl.IMG_LoadPNG_RW(rw) orelse {
        sdl.SDL_Log("Unable to load bmp: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer sdl.SDL_FreeSurface(exampleSurface);

    const exampleTexture = sdl.SDL_CreateTextureFromSurface(renderer, exampleSurface) orelse {
        sdl.SDL_Log("Unable to create texture from surface: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer sdl.SDL_DestroyTexture(exampleTexture);

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
        const gameState = logic(null);
        _ = gameState;
        // TODO: draw state

        _ = sdl.SDL_RenderClear(renderer);
        _ = sdl.SDL_RenderCopy(renderer, exampleTexture, null, null);
        sdl.SDL_RenderPresent(renderer);

        sdl.SDL_Delay(17);
    }
}

pub fn draw(state: common.GraphicalGameState) !void {
    _ = state;
}
