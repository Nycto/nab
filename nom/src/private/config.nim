import util, httpclient, os, strutils, osproc, sequtils

type
    Platform* = enum
        Linux, MacOS

    Module* = object ## Modules that can inject settings into the build
        flags*: proc(): seq[string]

    Config* = object ## Build configuration
        sourceDir*: string
        buildDir*: string
        platform*: Platform

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
    self.log(messages)

proc requireExe*(command: string): string =
    ## Requires that a command exist on the path
    result = findExe(command)
    if result == "": raise newException(OSError, "Could not find command: " & command)

proc requireSh*(self: Config, dir: string, command: string, args: varargs[string, `$`]) =
    ## Executes a shell command and throws if it fails
    let fullCommand = command & " " & args.join(" ")
    self.debug("Executing shell command", fullCommand)
    let process = startProcess(
        command = command,
        args = args,
        workingDir = dir,
        options = { poStdErrToStdOut, poParentStreams })
    if process.waitForExit() != 0:
        raise newException(OSError, "Command failed: " & fullCommand)
    self.debug("Command execution complete")

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

proc configureAndMake*(self: Config, title: string, dir: string, buildsInto: string): string =
    ## runs configure, then runs make in a directory

    result = buildsInto

    # Configure the make file
    if not fileExists(dir / "Makefile"):
        self.log("Configuring build for " & title)
        self.requireSh(dir, "configure")

    # Call 'make' if the build output dir doesn't exist
    if not buildsInto.dirExists:
        self.log("Building " & title)
        self.requireSh(dir, requireExe("make"))

proc archiveObjs*(self: Config, title: string, archivePath: string, getBuildDir: proc(): string): string =
    ## Creates an archive of *.o objects in a directory

    result = archivePath

    # Create an archive to bundle all the objects together
    if not archivePath.fileExists:
        let dir = getBuildDir()

        let objs = toSeq(walkPattern(dir / "*.o"))

        self.log("Creating archive for " & title, "Location: " & archivePath)

        self.requireSh(self.buildDir, requireExe("ar"), concat(@["rcs", archivePath], objs))

    self.debug title & " archive location: " & archivePath

