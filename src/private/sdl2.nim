import config, configutil, util, os, sequtils, options, strtabs, mac, nimble

type
    Sdl2Framework* = ref object
        sdl2Version*: string

proc sdl2source(self: Sdl2Framework, conf: Config): string =
    ## Returns the location of the unzipped SDL2 source, downloading and unzipping if necessary

    # Unzip the file, downloading it if it doesn't exist
    let unzippedTo = conf.unzip("SDL2", conf.platformBuildDir / "sdl2") do () -> string:
        conf.download("SDL2",
            "https://www.libsdl.org/release/SDL2-" & self.sdl2Version & ".zip",
            conf.buildDir / "sdl2.zip"
        )

    # The zip file itself contains a directory, which is ultimately what we care about
    return unzippedTo / ("SDL2-" & self.sdl2Version)

proc sdl2ArchivePath(self: Config): string =
    ## Returns the location of the '.a' file for SDL2
    self.platformBuildDir / "sdl2.a"

proc sdl2InstallDir(conf: Config): string =
    ## The installation dir for SDL
    result = conf.platformBuildDir / "sdl2_install"

proc makeSdl2(self: Sdl2Framework, conf: Config): string =
    ## Builds SDL2 using make and returns the resulting .a file

    return conf.archiveObjs("SDL2", conf.sdl2ArchivePath) do () -> string:

        # Call `configure` and call `make`, record the build directory
        let sdl2Source = self.sdl2source(conf)
        conf.configure("SDL2", sdl2Source, [ "--prefix", conf.sdl2InstallDir ])
        conf.make("SDL2", sdl2Source, sdl2Source / "build")

proc xcodeSdl2(self: Sdl2Framework, conf: Config, xcodeDir: string, sdkVersion: string): string =
    ## Builds SDL2 using xcode and returns the resulting .a file

    let fullXcodePath = self.sdl2source(conf) / xcodeDir / "SDL"

    let releaseSubdir =
        case conf.platform
        of Platform.iOsSim: "Release-iphonesimulator"
        else: raise newException(AssertionError, "Platform does not support xcode builds of sdl2: " & $conf.platform)

    result = fullXcodePath / "build" / releaseSubdir / "libSDL2.a"

    if not result.fileExists:
        conf.requireSh(
            conf.platformBuildDir,
            conf.requireExe("xcodebuild"),
            "-project", fullXcodePath / "SDL.xcodeproj",
            "-sdk", conf.sdkNameVersion(conf.macSdk))

proc linkerFlags(self: Sdl2Framework, conf: Config): seq[string] =
    ## Returns the compiler flags to use
    case conf.platform
    of Platform.Linux:
        @[ self.makeSdl2(conf), "-lsndio", "-lm" ]
    of Platform.MacOS:
        @[ self.xcodeSdl2(conf, "Xcode", conf.sdkNameVersion(MacSdk.MacOSX)) ]
    of Platform.iOsSim:
        @[
            self.xcodeSdl2(conf, "Xcode-iOS", conf.sdkNameVersion(MacSdk.iPhoneSim)),
            "-framework", "OpenGLES", "-framework", "UIKit", "-framework", "GameController",
            "-framework", "CoreMotion", "-framework", "Metal", "-framework", "AVFoundation",
            "-framework", "AudioToolbox", "-framework", "CoreAudio", "-framework", "CoreGraphics",
            "-framework", "QuartzCore"
        ]

const customMain = staticRead("../../resources/sdl2main.nim")

proc mainFile(self: Config): string =
    ## Returns the path to the main custom main entry point
    result = self.platformBuildDir / "nim" / "main.nim"
    if not result.fileExists:
        result.ensureParentDir
        result.writeFile("import " & self.nimbleBin.importable & "\n" & customMain)

proc newSdl2Framework*(conf: Config): Framework =
    let self = Sdl2Framework(sdl2Version: "2.0.9")

    result = Framework(
        flags: proc(): auto = @[ "--threads:on", "--dynlibOverride:SDL2", "--noMain" ],
        linkerFlags: proc(): auto = self.linkerFlags(conf),
        compilerFlags: proc(): seq[string] = @[],
        main: proc(): auto = conf.mainFile()
    )

