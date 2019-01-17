import util, httpclient, os, strutils, osproc
#, httpclient, strutils, ospaths, osproc, sequtils

type
    Module* = concept m ## Modules that can inject settings into the build
        flags(m, Config) is seq[string]

    Config* = object ## Build configuration
        sourceDir*: string
        buildDir*: string
        #modules: seq[Module]
        sdl2Version*: string

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

proc download*(self: Config, url: string, to: string) =
    ## Downloads a file
    to.ensureParentDir
    self.log "Downloading", "from " & url, "to " & to
    newHttpClient().downloadFile(url, to)

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
