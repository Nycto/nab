import config, util, os, sequtils, options, sdl2gfx

type
    Sdl2Module* = ref object
        sdl2Version*: string

proc sdl2source(self: Sdl2Module, conf: Config): string =
    ## Returns the location of the unzipped SDL2 source, downloading and unzipping if necessary

    # Unzip the file, downloading it if it doesn't exist
    let unzippedTo = conf.unzip("SDL2", conf.buildDir / "sdl2") do () -> string:
        conf.download("SDL2",
            "https://www.libsdl.org/release/SDL2-" & self.sdl2Version & ".zip",
            conf.buildDir / "sdl2.zip"
        )

    # The zip file itself contains a directory, which is ultimately what we care about
    return unzippedTo / ("SDL2-" & self.sdl2Version)

proc sdl2ArchivePath(self: Config): string =
    ## Returns the location of the '.a' file for SDL2
    self.buildDir / "sdl2.a"

proc makeSdl2(self: Sdl2Module, conf: Config): string =
    ## Builds SDL2 using make and returns the resulting .a file

    return conf.archiveObjs("SDL2", conf.sdl2ArchivePath) do () -> string:

        # Call `configure` and call `make`, record the build directory
        let sdl2Source = self.sdl2source(conf)
        conf.configureAndMake("SDL2", sdl2Source, sdl2Source / "build")

proc xcodeSdl2(self: Sdl2Module, conf: Config): string =
    ## Builds SDL2 using xcode and returns the resulting .a file
    result = conf.sdl2ArchivePath
    if not result.fileExists:
        conf.requireSh(
            conf.buildDir,
            requireExe("xcodebuild"),
            "-project", self.sdl2source(conf) / "Xcode/SDL/SDL.xcodeproj",
            "-target", "Static\\ Library",
            "-configuration", "Release",
            "-sdk", "macosx" & conf.macOsSdkVersion,
            "SYMROOT=build")

proc flags(self: Sdl2Module, conf: Config): seq[string] =
    ## Returns the compiler flags to use
    let common = @[
        "--threads:on",
        "--dynlibOverride:SDL2",
        "--passL:-lSDL2",
        "--passL:-lm" ]

    result =
        case conf.platform
        of Platform.Linux: common.concat(@[ "--passL:" & self.makeSdl2(conf), "--passL:-lsndio" ])
        of Platform.MacOS:
            common.concat(@[
                "--passL:" & self.xcodeSdl2(conf),
                "--passL:-liconv",
                "--passL:'-framework CoreAudio'",
                "--passL:'-framework AudioToolbox'",
                "--passL:'-framework CoreGraphics'",
                "--passL:'-framework QuartzCore'",
                "--passL:'-framework OpenGL'",
                "--passL:'-framework AppKit'",
                "--passL:'-framework AudioUnit'",
                "--passL:'-framework ForceFeedback'",
                "--passL:'-framework IOKit'",
                "--passL:'-framework Carbon'",
                "--passL:'-framework CoreServices'",
                "--passL:'-framework ApplicationServices'",
                "--passL:'-framework Metal'" ])

proc newSdl2Module*(conf: Config): Module =
    let self = Sdl2Module(sdl2Version: "2.0.9")

    let gfx = newSdl2GfxModule(conf)

    result = Module(
        flags: proc(): auto = concat(self.flags(conf), gfx.flags())
    )

