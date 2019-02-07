import parsecfg as pc, streams, osproc, os
import config as c, configutil

proc nimbleDump(self: c.Config): pc.Config =
    ## Reads the nimble config
    self.requireCaptureSh(self.requireExe("nimble"), self.sourceDir, [ "dump" ]) do (stream: auto) -> auto:
        loadConfig(stream, "nimble dump")

proc nimbleBin*(self: c.Config): tuple[absPath, importable: string] =
    ## Returns the primary bin file expecting to be compiled for this project
    let nimbleConfig = self.nimbleDump()
    let binName = nimbleConfig.getSectionValue("", "bin")
    self.require(binName.len > 0, "Binary name defined in nimble config must not be empty")
    let importable = "src" / binName
    let absPath = self.sourceDir / importable & ".nim"
    self.require(absPath.fileExists, "Binary file defined in nimble config does not exist: " & absPath)
    return (absPath, importable)

