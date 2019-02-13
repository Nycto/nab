import parsecfg as pc, streams, osproc, os
import config as c, configutil, util

proc nimbleDump*(self: c.Config): pc.Config =
    ## Reads the nimble config
    return self.requireCaptureSh(self[sourceDir], self.requireExe("nimble"), [ "dump" ]).apply(it):
        loadConfig(newStringStream(it), "nimble dump")

proc nimbleBin*(self: c.Config): tuple[absPath, importable: string] =
    ## Returns the primary bin file expecting to be compiled for this project
    let nimbleConfig = self.nimbleDump()
    let binName = nimbleConfig.getSectionValue("", "bin")
    self.require(binName.len > 0, "Binary name defined in nimble config must not be empty")
    let srcDir = nimbleConfig.getSectionValue("", "srcDir")
    self.require(srcDir.len > 0, "Source directory defined in nimble config must not be empty")
    let importable = srcDir / binName
    let absPath = self[sourceDir] / importable & ".nim"
    self.require(absPath.fileExists, "Binary file defined in nimble config does not exist: " & absPath)
    return (absPath, importable)

