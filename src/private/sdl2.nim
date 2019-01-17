import config, util, os, sequtils

proc sdl2zip(self: Config): string =
    ## Downloads a copy of SDL2
    result = self.buildDir / "sdl2.zip"

    if result.existsFile:
        self.log "SDL2 already downloaded", "Location: " & result
        return

    let url = "https://www.libsdl.org/release/SDL2-" & self.sdl2Version & ".zip"
    self.download(url, result)

proc sdl2dir(self: Config): string =
    ## Returns the location of the unzipped SDL2 source, downloading and unzipping if necessary

    # Where we will target the unzip
    let unzipInto = self.buildDir / "sdl2"

    # The zip file itself contains a directory, which is ultimately what we care about
    result = unzipInto / ("SDL2-" & self.sdl2Version)

    if not result.dirExists:
        unzipInto.ensureDir
        let zip = self.sdl2zip()
        self.log "Unzipping SDL2", "Destination: " & unzipInto
        self.requireSh(self.buildDir, requireExe("unzip"), zip, "-d", unzipInto)

    self.debug "SDL2 source location: " & result

proc sdl2objects(self: Config): seq[string] =
    ## Returns a list of object files built for SDL2

    # Configure the make file
    let dir = self.sdl2dir
    if not fileExists(dir / "Makefile"):
        self.log("Configuring SDL2 build")
        self.requireSh(dir, "configure")

    # Build the source
    let buildOutput = dir / "build"
    if not dirExists(buildOutput):
        self.log("Building SDL2")
        self.requireSh(dir, requireExe("make"))

    result = toSeq(walkPattern(buildOutput / "*.o"))

proc sdl2*(self: Config): string =
    ## Builds SDL2 and returns the resulting .a file

    # Create an archive to bundle all the objects together
    result = self.buildDir / "sdl2.a"
    if not result.fileExists:
        let objs = self.sdl2objects()
        self.log("Creating SDL2 archive", "Location: " & result)
        self.requireSh(self.sdl2dir / "build", requireExe("ar"), concat(@["rcs", result], objs))

    self.debug "SDL2 archive location: " & result

proc flags*(self: Config): seq[string] =
    result = @[
        "--threads:on",
        "--dynlibOverride:SDL2",
        "--passL:" & self.sdl2(),
        "--passL:-lm",
        "--passL:-lsndio"
    ]
