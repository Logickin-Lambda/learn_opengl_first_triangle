//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const glfw = @import("zglfw");
const gl = @import("gl");
const zm = @import("zm");
const std = @import("std");
const shaders = @import("shaders.zig");

// const c = @cImport({
//     @cDefine("SDL_DISABLE_OLD_NAMES", {});
//     @cInclude("SDL3/SDL.h");
//     @cInclude("SDL3/SDL_revision.h");
//     @cDefine("SDL_MAIN_HANDLED", {}); // We are providing our own entry point
//     @cInclude("SDL3/SDL_main.h");
// });

// constants and structs
var procs: gl.ProcTable = undefined;
const WindowSize = struct {
    pub const width: u32 = 800;
    pub const height: u32 = 600;
};

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("<!--Skri-a Kaark-->", .{});

    // glfw initialization process:
    glfw.init() catch {
        std.log.err("GLFW initialization failed", .{});
        return;
    };

    glfw.windowHint(glfw.WindowHint.context_version_major, 4);
    glfw.windowHint(glfw.WindowHint.context_version_minor, 3);
    glfw.windowHint(glfw.WindowHint.opengl_profile, glfw.OpenGLProfile.opengl_core_profile);

    defer glfw.terminate();

    // create window with glfw
    const window = glfw.Window.create(WindowSize.width, WindowSize.height, "Opengl Triangle", null) catch {
        std.log.err("GLFW Window creation failed", .{});
        return;
    };

    defer window.destroy();

    // Will try to find that on openfl sb7 to see if there are any explanations
    glfw.makeContextCurrent(window);
    defer glfw.makeContextCurrent(null);

    // Manage function pointers
    if (!procs.init(glfw.getProcAddress)) return error.InitFailed;

    gl.makeProcTableCurrent(&procs);
    defer gl.makeProcTableCurrent(null);

    // define the callback function when the framebuffer has a rezise
    _ = glfw.Window.setFramebufferSizeCallback(window, framebuffer_size_callback);

    // here is the main event loop to stay the window alive
    while (!glfw.windowShouldClose(window)) {
        glfw.swapBuffers(window);
        glfw.pollEvents();
    }
}

// The reason why this callback is defined is due to the callback standard
// in setFramebufferSizeCallback: https://glfw-d.dpldocs.info/~develop/glfw3.api.glfwSetFramebufferSizeCallback.html
// Since it is mendatory to have window as the callback parameter,
// we have to ditch all the variable using '_' to comply the zig rules on unused variables.
fn framebuffer_size_callback(window: *glfw.Window, width: c_int, height: c_int) callconv(.c) void {
    _ = window;

    std.debug.print("width: {d}\nheight: {d}", .{ width, height });

    // Viewport used for mapping the screen resolution into a range between -1 and 1
    // Superbible: page 94
    gl.Viewport(0, 0, width, height);
}
