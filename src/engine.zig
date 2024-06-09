const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});
const lodepng = @cImport({
    @cDefine("LODEPNG_NO_COMPILE_CPP", "1");
    @cDefine("LODEPNG_COMPILE_ERROR_TEXT", "1");
    @cInclude("lodepng.h");
});
const assert = @import("std").debug.assert;
const common = @import("common.zig");
const std = @import("std");

pub fn start(allocator: std.mem.Allocator, width: u16, height: u16, fps: u16, atlases: []common.Atlas, fonts: []common.Font, logic: *const common.LogicFuncType) !void {
    try initSdl();
    defer sdl.SDL_Quit();
    defer sdl.TTF_Quit();

    const window = try initWindow(width, height);
    defer sdl.SDL_DestroyWindow(window);

    const renderer = try initRenderer(window);
    defer sdl.SDL_DestroyRenderer(renderer);

    try gameLoop(allocator, fps, renderer, atlases, fonts, logic);
}

fn renderText(font: []const u8, text: []const u8, color: sdl.SDL_Color) !void {
    _ = font;
    _ = text;
    _ = color;
}

// ptsize - font point size
fn getFontFromFile(file: []const u8, ptsize: u8) *sdl.TTF_Font {
    const gFont = sdl.TTF_OpenFont(file, ptsize) orelse {
        sdl.SDL_Log("Failed to load font file: %s", file);
        return error.TTFLoadFontError;
    };
    return gFont;
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

    if (sdl.TTF_Init() == -1) {
        sdl.SDL_Log("SDL_ttf could not initialize! SDL_ttf Error: %s", sdl.TTF_GetError());
        return error.SDLInitializationFailed;
    }
}

fn loadAtlases(allocator: std.mem.Allocator, renderer: *sdl.SDL_Renderer, atlases: []common.Atlas) !std.StringHashMap(*sdl.SDL_Texture) {
    var atlasMap = std.StringHashMap(*sdl.SDL_Texture).init(allocator);
    for (atlases) |atlas| {
        const w: [*c]c_uint = @ptrCast(@alignCast(std.c.malloc(@sizeOf(c_uint)) orelse return undefined));
        const h: [*c]c_uint = @ptrCast(@alignCast(std.c.malloc(@sizeOf(c_uint)) orelse return undefined));
        defer {
            std.c.free(w);
            std.c.free(h);
        }
        var buffer: [*c]u8 = undefined;
        const result = lodepng.lodepng_decode32_file(&buffer, w, h, @ptrCast(atlas.path));
        std.debug.print("atlas width: {}, height: {}\n", .{ w.*, h.* });
        const imageW: c_int = @intCast(w.*);
        const imageH: c_int = @intCast(h.*);
        const pitch: c_int = @intCast(imageW * @sizeOf(u32));
        defer std.c.free(buffer);
        if (result != 0) {
            std.debug.print("decoder error {}, {s}\n", .{ result, lodepng.lodepng_error_text(result) });
            return error.PngError;
        }
        const atlasTexture = sdl.SDL_CreateTexture(renderer, sdl.SDL_PIXELFORMAT_ARGB8888, sdl.SDL_TEXTUREACCESS_STREAMING, imageH, imageW) orelse {
            sdl.SDL_Log("Unable to create textutre: %s", sdl.SDL_GetError());
            return error.IMGLoadTextureError;
        };
        var sdlPixels: []u32 = try allocator.alloc(u32, @intCast(imageW * imageH * @sizeOf(u32)));
        defer allocator.free(sdlPixels);

        // plot the pixels of the PNG file
        var y: u16 = 0;
        while (y < imageH) : (y += 1) {
            var x: u16 = 0;
            while (x < imageW) : (x += 1) {
                // get RGBA components
                var r: u8 = buffer[@intCast(4 * y * imageW + 4 * x + 0)]; // red
                var g: u8 = buffer[@intCast(4 * y * imageW + 4 * x + 1)]; // green
                var b: u8 = buffer[@intCast(4 * y * imageW + 4 * x + 2)]; // blue
                const a: u8 = buffer[@intCast(4 * y * imageW + 4 * x + 3)]; // alpha

                r = @intCast((@as(u16, a) * r + (255 - a)) / @as(u16, 255));
                g = @intCast((@as(u16, a) * g + (255 - a)) / @as(u16, 255));
                b = @intCast((@as(u16, a) * b + (255 - a)) / @as(u16, 255));

                // give the color value to the pixel of the screenbuffer
                sdlPixels[@intCast(y * imageW + x)] = @as(u32, 65536) * r + @as(u32, 256) * g + b;
            }
        }

        // render the pixels to e screen
        _ = sdl.SDL_UpdateTexture(atlasTexture, &sdl.SDL_Rect{
            .x = @intCast(0),
            .y = @intCast(0),
            .w = @intCast(imageW),
            .h = @intCast(imageH),
        }, @ptrCast(sdlPixels), pitch);

        try atlasMap.put(atlas.id, atlasTexture);
    }

    return atlasMap;
}

fn deinitAtlasesMap(atlasMap: *std.StringHashMap(*sdl.SDL_Texture)) void {
    var it = atlasMap.valueIterator();
    while (it.next()) |value| {
        sdl.SDL_DestroyTexture(value.*);
    }
    atlasMap.deinit();
}

fn gameLoop(allocator: std.mem.Allocator, fps: u16, renderer: *sdl.SDL_Renderer, atlases: []common.Atlas, fonts: []common.Font, logic: *const common.LogicFuncType) !void {
    var atlasMap = try loadAtlases(allocator, renderer, atlases);
    defer deinitAtlasesMap(&atlasMap);
    _ = fonts; // TODO implement fonts
    var quit = false;
    while (!quit) {
        const startP = sdl.SDL_GetPerformanceCounter();

        var event: sdl.SDL_Event = undefined;
        var inputEvent: ?common.InputEvent = null;
        while (sdl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl.SDL_QUIT => {
                    quit = true;
                },
                sdl.SDL_MOUSEBUTTONDOWN => {
                    inputEvent = common.InputEvent{
                        .position = castFromSDL_MouseButtonEvent(event.button),
                        .eventType = common.EventType.CLICK,
                    };
                },
                sdl.SDL_MOUSEMOTION => {
                    inputEvent = common.InputEvent{
                        .position = castFromSDL_MouseButtonEvent(event.button),
                        .eventType = common.EventType.MOTION,
                    };
                },
                else => {},
            }
        }
        _ = sdl.SDL_RenderClear(renderer);
        try draw(allocator, renderer, atlasMap, logic(inputEvent, allocator));
        sdl.SDL_RenderPresent(renderer);

        const end = sdl.SDL_GetPerformanceCounter();

        const elapsedMS = @as(f64, @floatFromInt(end - startP)) / @as(f64, @floatFromInt(sdl.SDL_GetPerformanceFrequency())) * @as(f64, 1000.0);

        // Cap FPS
        var delay = 1000 / @as(f64, @floatFromInt(fps)) - elapsedMS;
        // use to show FPS
        if (delay < 0) {
            delay = elapsedMS;
            // std.debug.print("FPS: {d}\n", .{1000.0 / delay});
        } else {
            // std.debug.print("FPS: {d}\n", .{1000.0 / (elapsedMS + delay)});
        }

        sdl.SDL_Delay(@as(u32, @intFromFloat(delay)));
    }
}

pub fn draw(allocator: std.mem.Allocator, renderer: *sdl.SDL_Renderer, atlasMap: std.StringHashMap(*sdl.SDL_Texture), state: *common.GraphicalGameState) !void {
    defer state.deinit(allocator);
    if (state.objects) |objects| {
        for (objects) |object| {
            const position = object.position;
            const camera = state.camera;
            // check if in screen
            if (position.x >= camera.x and position.x <= (camera.x + camera.w) and position.y >= camera.y and position.y <= (camera.y + camera.h)) {
                // std.debug.print("\n\nobject.atlas: {s}  !!!\n\n", .{object.atlas});

                // std.debug.print("\nHere: {s}  !!!\n", .{object.atlas});
                const atlas = atlasMap.get(object.atlas);
                const srcRect = object.positionInAtlas;
                // std.debug.print("Here1: {d}  !!!\n", .{srcRect.h});
                // std.debug.print("Here4: {d}  !!!\n", .{object.*.position.x});

                _ = sdl.SDL_RenderCopy(renderer, atlas, &castToSDLRect(srcRect), &fromWorldPostionToRendererTargetRect(object.position, camera, srcRect.w, srcRect.h));
            }
        }
    }
}

fn fromWorldPostionToRendererTargetRect(position: common.Point, camera: common.Rectangle, w: u16, h: u16) sdl.SDL_Rect {
    // const x: c_int = @intCast(position.x);
    // std.debug.print("Here2: {d}  !!!\n", .{x});
    return castToSDLRect(.{
        .x = position.x - camera.x,
        .y = position.y - camera.y,
        .w = w,
        .h = h,
    });
}

fn castToSDLRect(srcRect: common.Rectangle) sdl.SDL_Rect {
    // const x: c_int = @intCast(srcRect.w);
    // std.debug.print("Here3: {d}  !!!\n", .{x});
    return sdl.SDL_Rect{
        .x = @intCast(srcRect.x),
        .y = @intCast(srcRect.y),
        .w = @intCast(srcRect.w),
        .h = @intCast(srcRect.h),
    };
}

fn castFromSDL_MouseButtonEvent(button: sdl.SDL_MouseButtonEvent) common.Point {
    return .{
        .x = if (button.x > 0) @intCast(button.x) else 0,
        .y = if (button.y > 0) @intCast(button.y) else 0,
    };
}
