import config, util
import httpclient, os, strutils, osproc, sequtils, system, strtabs, streams

template require*(self: Config, pass: typed, msg: typed) =
    ## Requires that a value pass
    if not pass:
        if self.dryrun:
            echo "NOTICE: Action failed, but continuing because of dryrun mode. " & msg
        else:
            raise newException(AssertionError, msg)

proc fail*(self: Config, msg: string) =
    ## Fails unless dryruns are enabled
    self.require(false, msg)

proc requireDir*(self: Config, path: string): string =
    ## Requires that a directory exists or throws
    result = path
    self.require(path.dirExists, "Directory does not exist: " & path)

proc requireFile*(self: Config, path: string): string =
    ## Requires that a file exists or throws
    result = path
    self.require(path.fileExists, "File does not exist: " & path)

proc platformBuildDir*(self: Config): string =
    ## A directory for platform specific builds
    result = self.buildDir / $self.platform
    result.ensureDir

proc nimcacheDir*(self: Config): string =
    result = self.platformBuildDir / "nimcache"
    result.ensureDir

proc macAppDir*(self: Config): string =
    ## The directory in which to put content to be bundled
    result = self.platformBuildDir / self.appName & ".app"
    result.ensureDir

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

proc requireExe*(self: Config, command: string): string =
    ## Requires that a command exist on the path
    result = findExe(command)
    self.require(result != "", "Could not find command: " & command)
    if result == "":
        result = command

proc requireSh*(self: Config, dir: string, env: StringTableRef, command: string, args: varargs[string, `$`]) =
    ## Executes a shell command and throws if it fails
    let fullCommand = command & " " & args.join(" ")
    self.debug("Executing shell command", fullCommand)
    if not self.dryrun:
        let process = startProcess(
            command = command,
            args = args,
            workingDir = dir,
            env = env,
            options = { poStdErrToStdOut, poParentStreams })
        defer: close(process)
        self.require(process.waitForExit() == 0, "Command failed: " & fullCommand)
        self.debug("Command execution complete")

proc requireSh*(self: Config, dir: string, command: string, args: varargs[string, `$`]) =
    requireSh(self, dir, nil, command, args)

proc requireCaptureSh*(self: Config, dir: string, command: string, args: varargs[string, `$`]): string =
    ## Executes a command and processes the output through a callback
    let fullCommand = command & " " & args.join(" ")
    self.debug("Executing and capturing shell command", fullCommand)

    if not self.dryrun:
        var handle = startProcess(command, self.sourceDir, args, nil, {})
        defer: close(handle)
        let stream = handle.outputStream
        defer: close(stream)

        while not stream.atEnd:
            self.require(handle.peekExitCode <= 0, "Command failed: " & fullCommand)
            result.add(stream.readAll)

        self.require(handle.waitForExit == 0, "Command failed: " & fullCommand)

proc download*(self: Config, title: string, url: string, to: string): string =
    ## Downloads a file
    result = to
    if to.existsFile:
        self.log title & " already downloaded", "Location: " & to
        return
    to.ensureParentDir
    self.log "Downloading " & title, "from " & url, "to " & to
    if not self.dryrun:
        newHttpClient().downloadFile(url, to)

proc unzip*(self: Config, title: string, to: string, zipFile: proc(): string): string =
    ## Unzips a zip file

    result = to

    if not to.dirExists:
        to.ensureDir
        let zip = zipFile()
        self.log "Unzipping " & title, "Destination: " & to
        self.requireSh(self.buildDir, self.requireExe("unzip"), zip, "-d", to)

    self.debug title & " zip file location: " & to

proc objs*(dir: string): seq[string] =
    ## Returns a list of object files in a directory
    toSeq(walkPattern(dir / "*.o"))

proc configure*(self: Config, title: string, dir: string, args: openarray[string] = [], env: StringTableRef = nil) =
    ## Runs the configure command
    if not fileExists(dir / "Makefile"):
        self.log("Configuring build for " & title)
        let configurePath = dir / "configure"

        if not self.dryrun:
            let permissions = configurePath.getFilePermissions()
            if FilePermission.fpUserExec notin permissions:
                configurePath.setFilePermissions(permissions + { FilePermission.fpUserExec })

        self.requireSh(dir, env, configurePath, args)

proc make*(self: Config, title: string, dir: string, buildsInto: string): string =
    # Call 'make' if the build output dir doesn't exist
    result = buildsInto
    if isEmpty(items(objs(buildsInto))):
        self.log("Building " & title)
        self.requireSh(dir, self.requireExe("make"))

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

        self.requireSh(self.buildDir, self.requireExe("ar"), concat(@["rcs", archivePath], objs))

    self.debug title & " archive location: " & archivePath

template requireKey*(self: Config, key: untyped) =
    ## Requires an entry in the config
    let value = self.`key`
    let name = astToStr(key)
    discard requireNotEmpty(value, name, "Add '" & name & "' to nab.cfg, or pass it via --" & name)

