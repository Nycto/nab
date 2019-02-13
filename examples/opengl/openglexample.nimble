# Package

version       = "0.1.0"
author        = "Nycto"
description   = "Example app using OpenGL"
license       = "MIT"
srcDir        = "src"
bin           = @["openglexample"]


# Dependencies

requires "nim >= 0.19.2", "sdl2 >= 2.0", "opengl >= 1.2.0"
