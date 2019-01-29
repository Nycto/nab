import util

type
    Platform* = enum
        Linux, MacOS, iOsSim

    Module* = object ## Modules that can inject settings into the build
        flags*: proc(): seq[string]

    Config* = object ## Build configuration
        sourceDir*: string
        buildDir*: string
        platform*: Platform
        macOsSdkVersion*: string
        macOsMinVersion*: string
        iOsSimSdkVersion*: string
        extraFlags*: seq[string]
        verbose*: bool

