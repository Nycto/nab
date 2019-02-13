import sdl2, random

proc render(renderer: RendererPtr) =
    var renderW, renderH: cint
    renderer.getLogicalSize(renderW, renderH)

    # Come up with a random rectangle
    var rectangle = rect(
        x = cint(rand(renderW)),
        y = cint(rand(renderH)),
        w = cint(rand(64) + 64),
        h = cint(rand(64) + 64))

    # Come up with a random color
    let r = uint8(rand(205) + 50)
    let g = uint8(rand(205) + 50)
    let b = uint8(rand(205) + 50)

    # Fill the rectangle in the color
    renderer.setDrawColor(r, g, b, 255)
    renderer.fillRect(rectangle)

    # update screen
    renderer.present

template sdl2assert(condition: SDL_Return, message: typed): untyped =
    if condition == SDL_Return.SdlError:
        raise newException(AssertionError, message & "; " & $getError())

template sdl2assert(condition: cint, message: typed): untyped =
    if condition != 0:
        raise newException(AssertionError, message & "; " & $getError())

proc main() =

    # initialize SDL
    sdl2assert(sdl2.init(INIT_VIDEO), "Failed to initialize SDL")

    # seed random number generator
    randomize()

    # create window and renderer */
    let window = createWindow(nil, 0, 0, 320, 480, SDL_WINDOW_ALLOW_HIGHDPI or SDL_WINDOW_FULLSCREEN)
    let renderer = createRenderer(window, -1, 0)

    defer: sdl2.quit()

    let (windowW, windowH) = window.getSize()
    sdl2assert(renderer.setLogicalSize(windowW, windowH), "Unable to set logical size")

    # Fill screen with black
    renderer.setDrawColor(0, 0, 0, 255)
    renderer.clear()

    # Enter render loop, waiting for user to quit
    var done = false
    while not done:
        var event: Event
        while (pollEvent(event)):
            if event.kind in { QuitEvent, KeyDown, FingerDown, MouseButtonDown }:
                done = true
        renderer.render()
        delay(1)

try:
    main()
except:
    echo "ERROR: ", getCurrentExceptionMsg()
    discard showSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "INTERNAL ERROR", getCurrentExceptionMsg(), nil)

