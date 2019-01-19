import config, util, os, sequtils, options

type
    Sdl2Module* = ref object
        sdl2Version*: string

proc sdl2zip(self: Sdl2Module, conf: Config): string =
    ## Downloads a copy of SDL2
    result = conf.buildDir / "sdl2.zip"

    if result.existsFile:
        conf.log "SDL2 already downloaded", "Location: " & result
        return

    let url = "https://www.libsdl.org/release/SDL2-" & self.sdl2Version & ".zip"
    conf.download(url, result)

proc sdl2dir(self: Sdl2Module, conf: Config): string =
    ## Returns the location of the unzipped SDL2 source, downloading and unzipping if necessary

    # Where we will target the unzip
    let unzipInto = conf.buildDir / "sdl2"

    # The zip file itself contains a directory, which is ultimately what we care about
    result = unzipInto / ("SDL2-" & self.sdl2Version)

    if not result.dirExists:
        unzipInto.ensureDir
        let zip = self.sdl2zip(conf)
        conf.log "Unzipping SDL2", "Destination: " & unzipInto
        conf.requireSh(conf.buildDir, requireExe("unzip"), zip, "-d", unzipInto)

    conf.debug "SDL2 source location: " & result

proc sdl2objects(self: Sdl2Module, conf: Config): seq[string] =
    ## Returns a list of object files built for SDL2

    # Configure the make file
    let dir = self.sdl2dir(conf)
    if not fileExists(dir / "Makefile"):
        conf.log("Configuring SDL2 build")
        conf.requireSh(dir, "configure")

    # Build the source
    let buildOutput = dir / "build"
    if not dirExists(buildOutput):
        conf.log("Building SDL2")
        conf.requireSh(dir, requireExe("make"))

    result = toSeq(walkPattern(buildOutput / "*.o"))

proc sdl2(self: Sdl2Module, conf: Config): string =
    ## Builds SDL2 and returns the resulting .a file

    # Create an archive to bundle all the objects together
    result = conf.buildDir / "sdl2.a"
    if not result.fileExists:
        let objs = self.sdl2objects(conf)
        conf.log("Creating SDL2 archive", "Location: " & result)
        conf.requireSh(self.sdl2dir(conf) / "build", requireExe("ar"), concat(@["rcs", result], objs))

    conf.debug "SDL2 archive location: " & result

proc flags(self: Sdl2Module, conf: Config): seq[string] =
    ## Returns the compiler flags to use
    result =
        case conf.platform
        of Platform.Linux:
            @[
                "--threads:on",
                "--dynlibOverride:SDL2",
                "--passL:" & self.sdl2(conf),
                "--passL:-lm",
                "--passL:-lsndio" ]
        of Platform.MacOS:
            @[
                "--threads:on",
                "--dynlibOverride:SDL2",
                "--passL:" & self.sdl2(conf),
                "--passL:-lm",
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
                "--passL:'-framework Metal'" ]

proc newSdl2Module*(conf: Config): Module =
    let self = Sdl2Module(sdl2Version: "2.0.9")

    result = Module(
        flags: proc(): auto = self.flags(conf)
    )


#proc flags*(self: Sdl2Module, conf: Config): seq[string] =
#    result = @[
#        "--threads:on",
#        "--dynlibOverride:SDL2",
#        "--passL:" & self.sdl2(conf),
#        "--passL:-lm",
#        "--passL:-lsndio"
#    ]



