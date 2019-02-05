import config, os, util, pegs, infoplist, configutil

type MacSdk* = enum
    ## Mac SDKs that can be targeted for compilation
    iPhone,
    iPhoneSim

proc dirName(sdk: MacSdk): string =
    ## Given an SDK, returns the file system name used for it
    case sdk
    of MacSdk.iPhone: "iPhoneOS"
    of MacSdk.iPhoneSim: "iPhoneSimulator"

proc macSdk*(self: Config): MacSdk =
    ## Given an SDK, returns the file system name used for it
    case self.platform
    of Platform.iOsSim: MacSdk.iPhoneSim
    of Platform.MacOs, Platform.Linux: raise newException(AssertionError, "Could not determine mac sdk from platform")

proc xCodeAppPath*(self: Config): string =
    ## Where to find XCode
    "/Applications/Xcode.app"

proc xCodeSdksPath(self: Config, sdk: MacSdk): string =
    ## Returns the directory name for an SDK. This path contains all the versions for that SDK
    result = self.xCodeAppPath / "Contents/Developer/Platforms/" & sdk.dirName & ".platform/Developer/SDKs"
    discard result.requireDir

proc sdkVersion*(self: Config, sdk: MacSdk): string =
    ## Returns the highest installed SDK version
    let searchDir = self.xCodeSdksPath(sdk)

    for file in walkDir(searchDir):
        var dirName = splitFile(file.path).name
        var matches = dirName.findAll(peg"\d+\.\d+")
        if matches.len() > 0:
            return matches[matches.len() - 1]

    raise newException(OSError, "Could not find any SDKs. Searched in " & searchDir)

proc sdkNameVersion*(self: Config, sdk: MacSdk): string =
    ## Returns the name/version form of an sdk
    sdk.dirName & self.sdkVersion(sdk)

proc sdkPath*(self: Config, sdk: MacSdk): string =
    ## The file path for a specific SDK
    result = self.xCodeSdksPath(sdk) / (self.sdkNameVersion(sdk) & ".sdk")
    discard result.requireDir

proc iOsSimCompileConfig*(self: Config): CompileConfig =
    ## Compiler flags for compiling for the ios simulator
    result = CompileConfig(
        flags: @[
            "--cpu:amd64", "--noMain",
            "-d:ios", "-d:simulator",
            "--passC:-isysroot " & self.sdkPath(MacSdk.iPhoneSim),
            "--passL:-isysroot " & self.sdkPath(MacSdk.iPhoneSim),
            "--passL:-fobjc-link-runtime" ],
        binPath: self.appDir / self.appName
    )
