//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const glfw = @import("zglfw");
const gl = @import("gl");
const zm = @import("zm");
const std = @import("std");
const shaders = @import("shaders.zig");

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

    // Yay! Finally I have reach to something that relates to the superbible,
    // the shaders!!!

    // variables for verifications
    var success: c_int = undefined;
    var infoLog: [512:0]u8 = undefined;

    // Creating, loading and compiling the vectex shader:
    var vertexShader: c_uint = undefined;
    vertexShader = gl.CreateShader(gl.VERTEX_SHADER);
    defer gl.DeleteShader(vertexShader);

    gl.ShaderSource(
        vertexShader,
        1,
        &.{shaders.vertexShaderImpl},
        &.{shaders.vertexShaderImpl.len},
    );
    gl.CompileShader(vertexShader);

    // verify vertex shader
    gl.GetShaderiv(vertexShader, gl.COMPILE_STATUS, &success);

    if (success == gl.FALSE) {
        gl.GetShaderInfoLog(vertexShader, infoLog.len, null, &infoLog);
        std.log.err("{s}", .{std.mem.sliceTo(&infoLog, 0)});
        return error.CompileVertexShaderFailed;
    }

    // Creating, loading and compiling the vectex shader:
    var fragmentShader: c_uint = undefined;
    fragmentShader = gl.CreateShader(gl.FRAGMENT_SHADER);
    defer gl.DeleteShader(fragmentShader);

    gl.ShaderSource(
        fragmentShader,
        1,
        &.{shaders.fragmentShaderImpl},
        &.{shaders.fragmentShaderImpl.len},
    );
    gl.CompileShader(fragmentShader);

    // verify fragment shader
    gl.GetShaderiv(fragmentShader, gl.COMPILE_STATUS, &success);

    if (success == gl.FALSE) {
        gl.GetShaderInfoLog(fragmentShader, infoLog.len, null, &infoLog);
        std.log.err("{s}", .{std.mem.sliceTo(&infoLog, 0)});
        return error.CompileFragmentShaderFailed;
    }

    // create a program and load all the shaders
    var shaderProgram: c_uint = undefined;
    shaderProgram = gl.CreateProgram();
    if (shaderProgram == gl.FALSE) {
        return error.ProgramCreationFailed;
    }
    errdefer gl.DeleteProgram(shaderProgram);

    gl.AttachShader(shaderProgram, vertexShader);
    gl.AttachShader(shaderProgram, fragmentShader);
    gl.LinkProgram(shaderProgram);

    // // verify the linkage of shaders
    gl.GetProgramiv(shaderProgram, gl.LINK_STATUS, &success);

    if (success == gl.FALSE) {
        gl.GetProgramInfoLog(fragmentShader, infoLog.len, null, &infoLog);
        std.log.err("{s}", .{infoLog});
        return error.LinkProgramFailed;
    }

    // define the vao, but since this code is based on the first triangle program of the opengl superbible 7
    // there is nothing in the vao
    var vao: c_uint = undefined;
    gl.GenVertexArrays(1, (&vao)[0..1]);
    errdefer gl.DeleteVertexArrays(1, (&vao)[0..1]);

    gl.BindVertexArray(vao);
    defer gl.BindVertexArray(0);

    // here is the main event loop to stay the window alive
    // and the rendering take place in this loop
    while (!glfw.windowShouldClose(window)) {
        const green: [4]gl.float = .{ 0.0, 0.25, 0.0, 1.0 };
        gl.ClearBufferfv(gl.COLOR, 0, &green);

        gl.UseProgram(shaderProgram);
        gl.DrawArrays(gl.TRIANGLES, 0, 3);

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
    // Viewport used for mapping the screen resolution into a range between -1 and 1
    // Superbible: page 94
    gl.Viewport(0, 0, width, height);
}
