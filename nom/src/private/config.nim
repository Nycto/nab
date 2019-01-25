import util, httpclient, os, strutils, osproc, sequtils, system, strtabs

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

proc platformBuildDir*(self: Config): string =
    ## A directory for platform specific builds
    result = self.buildDir / $self.platform
    result.ensureDir

proc xCodeAppPath(self: Config): string =
    ## Where to find XCode
    "/Applications/Xcode.app"

proc iOsSimulatorSdkPath(self: Config): string =
    ## The file path for the ios simulator SDK
    let filename = "iPhoneSimulator" & self.iOsSimSdkVersion & ".sdk"
    result = self.xCodeAppPath / "Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs" / filename

proc flags *(self: Config): seq[string] =
    ## Returns the compiler flags to pass for a platform build
    case self.platform
    of Platform.Linux: @[ "--os:linux", "-d:linux" ]
    of Platform.MacOS: @[ "--os:macosx", "-d:macosx" ]
    of Platform.iOsSim:
        @[
            "--cpu:amd64",
            "-d:ios", "-d:simulator",
            "--passC:-isysroot", "--passL:-isysroot",
            "--passC:" & self.iOsSimulatorSdkPath, "--passL:" & self.iOsSimulatorSdkPath,
            "--passL:-fobjc-link-runtime" ]

proc log*(self: Config, messages: varargs[string, `$`]) =
    ## Logs an event to the console
    var first = true
    for message in messages:
        if first:
            echo message
            first = false
        else:
            echo "  " & message

proc debug*(self: Config, messages: varargs[string, `$`]) =
    ## Logs an event to the console
    if self.verbose:
        self.log(messages)

proc requireExe*(command: string): string =
    ## Requires that a command exist on the path
    result = findExe(command)
    if result == "": raise newException(OSError, "Could not find command: " & command)

proc requireSh*(self: Config, dir: string, env: StringTableRef, command: string, args: varargs[string, `$`]) =
    ## Executes a shell command and throws if it fails
    let fullCommand = command & " " & args.join(" ")
    self.debug("Executing shell command", fullCommand)
    let process = startProcess(
        command = command,
        args = args,
        workingDir = dir,
        env = env,
        options = { poStdErrToStdOut, poParentStreams })
    if process.waitForExit() != 0:
        raise newException(OSError, "Command failed: " & fullCommand)
    self.debug("Command execution complete")

proc requireSh*(self: Config, dir: string, command: string, args: varargs[string, `$`]) =
    requireSh(self, dir, nil, command, args)

proc download*(self: Config, title: string, url: string, to: string): string =
    ## Downloads a file
    result = to
    if to.existsFile:
        self.log title & " already downloaded", "Location: " & to
        return
    to.ensureParentDir
    self.log "Downloading " & title, "from " & url, "to " & to
    newHttpClient().downloadFile(url, to)

proc unzip*(self: Config, title: string, to: string, zipFile: proc(): string): string =
    ## Unzips a zip file

    result = to

    if not to.dirExists:
        to.ensureDir
        let zip = zipFile()
        self.log "Unzipping " & title, "Destination: " & to
        self.requireSh(self.buildDir, requireExe("unzip"), zip, "-d", to)

    self.debug title & " zip file location: " & to

proc objs*(dir: string): seq[string] =
    ## Returns a list of object files in a directory
    toSeq(walkPattern(dir / "*.o"))

proc configure*(self: Config, title: string, dir: string, args: openarray[string] = [], env: StringTableRef = nil) =
    ## Runs the configure command
    if not fileExists(dir / "Makefile"):
        self.log("Configuring build for " & title)
        let configurePath = dir / "configure"

        let permissions = configurePath.getFilePermissions()
        if FilePermission.fpUserExec notin permissions:
            configurePath.setFilePermissions(permissions + { FilePermission.fpUserExec })

        self.requireSh(dir, env, configurePath, args)

proc make*(self: Config, title: string, dir: string, buildsInto: string): string =
    # Call 'make' if the build output dir doesn't exist
    result = buildsInto
    if isEmpty(items(objs(buildsInto))):
        self.log("Building " & title)
        self.requireSh(dir, requireExe("make"))

proc configureAndMake*(self: Config, title: string, dir: string, buildsInto: string): string =
    ## runs configure, then runs make in a directory

    self.configure(title, dir)
    return self.make(title, dir, buildsInto)

proc archiveObjs*(self: Config, title: string, archivePath: string, getBuildDir: proc(): string): string =
    ## Creates an archive of *.o objects in a directory

    result = archivePath

    # Create an archive to bundle all the objects together
    if not archivePath.fileExists:
        let dir = getBuildDir()

        let objs = objs(dir)

        self.log("Creating archive for " & title, "Location: " & archivePath)

        self.requireSh(self.buildDir, requireExe("ar"), concat(@["rcs", archivePath], objs))

    self.debug title & " archive location: " & archivePath

