import safegl, sdl2/sdl, opengl, options

template sdl2assert(condition: untyped) =
    ## Asserts that an sdl2 related expression is truthy
    let outcome =
        when compiles(condition != 0): condition != 0
        elif compiles(condition == nil): condition == nil:
        else: not condition
    if outcome:
        let msg = astToStr(condition) & "; " & $sdl.getError()
        raise AssertionError.newException(msg)

proc getScreenSize(): tuple[width, height: cint, fullScreenFlag: uint32] =
    ## Determine the size of the display
    when defined(ios):
        var bounds: Rect
        sdl2assert sdl.getDisplayBounds(displayIndex = 0, rect = addr bounds)
        result.width = bounds.w
        result.height = bounds.h
        result.fullScreenFlag = sdl.WindowFullscreen
    else:
        result.width = 640
        result.height = 480
        result.fullScreenFlag = 0

template initialize(window, code: untyped) =
    try:

        # Initialize SDL2 and opengl
        sdl2assert sdl.init(sdl.InitEverything)
        defer: sdl.quit()

        # Ask for a new version of opengl
        sdl2assert sdl.glSetAttribute(GLattr.GL_ACCELERATED_VISUAL, 1)
        sdl2assert sdl.glSetAttribute(GLattr.GL_CONTEXT_MAJOR_VERSION, 3)
        sdl2assert sdl.glSetAttribute(GLattr.GL_CONTEXT_MINOR_VERSION, 0)
        sdl2assert sdl.glSetAttribute(GLattr.GL_CONTEXT_PROFILE_MASK, sdl.GL_CONTEXT_PROFILE_CORE)

        # Turn on double buffering with a 24bit Z buffer.
        sdl2assert sdl.glSetAttribute(GLattr.GL_DOUBLEBUFFER, 1)
        sdl2assert sdl.glSetAttribute(GLattr.GL_DEPTH_SIZE, 24)

        let screenSize = getScreenSize()

        let window = sdl.createWindow(
            "Example",
            sdl.WindowPosUndefined,
            sdl.WindowPosUndefined,
            w = screenSize.width,
            h = screenSize.height,
            screenSize.fullScreenFlag or sdl.WindowOpenGL or sdl.WindowShown
        )
        sdl2assert window
        defer: window.destroyWindow()

        let glcontext = glCreateContext(window)
        sdl2assert glcontext
        defer: sdl.glDeleteContext(glcontext)

        initOpenGl(screenSize = some((width: screenSize.width.int, height: screenSize.height.int)))

        code
    except:
        sdl.log(getCurrentExceptionMsg())
        echo getCurrentExceptionMsg()
        raise

template gameLoop*(code: untyped) =
    ## Run the game loop
    var e: sdl.Event
    block endGame:
        while true:
            while sdl.pollEvent(addr e) != 0:
                if e.kind == sdl.Quit:
                    break endGame
            code

# A basic vertex shader that just forwards the vector position
const vertexShader = """
#version 300 es
layout (location = 0) in mediump vec3 position;
void main() {
   gl_Position = vec4(position, 1.0);
}
"""

# A basic fragment shader that sets the color to orange
const fragmentShader = """
#version 300 es
out lowp vec4 FragColor;
void main() {
   FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}
"""

type Uniform = object

type Vertex = object
    position: array[3, GLfloat]

# Vertices of a triangle
var vertices = [
    Vertex(position: [ -0.5.GLfloat, -0.5.GLfloat, 0.0.GLfloat ]), # left
    Vertex(position: [ 0.5.GLfloat, -0.5.GLfloat, 0.0.GLfloat ]),  # right
    Vertex(position: [ 0.0.GLfloat,  0.5.GLfloat, 0.0.GLfloat ]) # top
]

initialize(window):

    # Build and compile our shader program
    let program = createProgram[Uniform, Vertex](vertexShader, fragmentShader)

    # Create a vertex array to store the vertices and their data shape
    let vao = newVertexArray(vertices)

    gameLoop:
        # Reset the scene
        glClearColor(0.2, 0.3, 0.3, 1.0)
        glClear(GL_COLOR_BUFFER_BIT)

        # Draw the triangle
        program.draw(Uniform(), vao)

        # Swap in the new rendering
        window.glSwapWindow()

