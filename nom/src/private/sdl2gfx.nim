import config, util, os, sequtils, options

type
    Sdl2GfxModule = ref object
        version*: string

proc sdl2gfxSource(self: Sdl2GfxModule, conf: Config): string =
    ## Returns the location of the unzipped SDL2_gfx source, downloading and unzipping if necessary

    # Unzip the file, downloading it if it doesn't exist
    let unzippedTo = conf.unzip("SDL2_gfx", conf.buildDir / "sdl2_gfx") do () -> auto:
        conf.download("SDL2_gfx",
            "http://www.ferzkopp.net/Software/SDL2_gfx/SDL2_gfx-" & self.version & ".zip",
            conf.buildDir / "sdl2_gfx.zip"
        )

    # The zip file itself contains a directory, which is ultimately what we care about
    return unzippedTo / ("SDL2_gfx-" & self.version)

proc sdl2gfx(self: Sdl2GfxModule, conf: Config): string =
    ## Builds SDL2 and returns the resulting .a file

    return conf.archiveObjs("SDL2_gfx", conf.buildDir / "sdl2_gfx.a") do () -> auto:

        # Call `configure` and call `make`, record the build directory
        let src = self.sdl2gfxSource(conf)
        conf.configureAndMake("SDL2_gfx", src, src)

proc flags(self: Sdl2GfxModule, conf: Config): seq[string] =
    ## Returns the compiler flags to use
    result =
        @[
            "--dynlibOverride:SDL2_gfx",
            "--passL:-lSDL2_gfx",
            "--passL:" & self.sdl2gfx(conf) ]

proc newSdl2GfxModule*(conf: Config): Module =
    let self = Sdl2GfxModule(version: "1.0.4")

    result = Module(
        flags: proc(): auto = self.flags(conf)
    )


