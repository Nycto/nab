import os, streams, parsecfg

proc ensureDir*(path: string) =
    ## Guarantees a directory exists
    if not path.dirExists:
        path.createDir

proc ensureParentDir*(path: string) =
    ## Guarantees a parent directory exists
    path.parentDir.ensureDir

template isEmpty*(iter: untyped): bool =
    ## Whether an iterator is empty
    var result: bool = true
    for _ in iter:
        result = false
        break
    result

proc requireNotEmpty*(self: string, name: string, message: string): string =
    ## Requires that a string isn't empty, or throws
    if (self.len == 0):
        raise newException(AssertionError, name & " should not be empty. " & message)
    return self


iterator parseConfigFile*(path: string): tuple[section: string, key: string, value: string] =
    ## Iterates over the events in a config file
    var handle = newFileStream(path, fmRead)
    if handle != nil:
        defer: close(handle)

        var parser: CfgParser
        open(parser, handle, path)
        defer: close(parser)

        var section = ""
        while true:
            var event = next(parser)
            case event.kind
            of cfgEof: break
            of cfgSectionStart: section = event.section
            of cfgKeyValuePair: yield (section, event.key, event.value)
            of cfgOption: yield (section, event.key, event.value)
            of cfgError: assert(false, event.msg)

