import config, os, util, pegs

type MacSdk = enum
    ## Mac SDKs that can be targeted for compilation
    iPhone,
    iPhoneSim

proc dirName(sdk: MacSdk): string =
    ## Given an SDK, returns the file system name used for it
    case sdk
    of MacSdk.iPhone: "iPhoneOS"
    of MacSdk.iPhoneSim: "iPhoneSimulator"

proc xCodeAppPath*(self: Config): string =
    ## Where to find XCode
    "/Applications/Xcode.app"

proc xCodeSdksPath(self: Config, sdk: MacSdk): string =
    ## Returns the directory name for an SDK. This path contains all the versions for that SDK
    result = self.xCodeAppPath / "Contents/Developer/Platforms/" & sdk.dirName & ".platform/Developer/SDKs"
    discard result.requireDir

proc sdkVersion(self: Config, sdk: MacSdk): string =
    ## Returns the highest installed SDK version
    let searchDir = self.xCodeSdksPath(sdk)

    for file in walkDir(searchDir):
        var dirName = splitFile(file.path).name
        var matches = dirName.findAll(peg"\d+\.\d+")
        if matches.len() > 0:
            return matches[matches.len() - 1]

    raise newException(OSError, "Could not find any SDKs. Searched in " & searchDir)

proc sdkPath*(self: Config, sdk: MacSdk): string =
    ## The file path for a specific SDK
    let filename = sdk.dirName & self.sdkVersion(MacSdk.iPhoneSim) & ".sdk"
    result = self.xCodeSdksPath(sdk) / filename
    discard result.requireFile

proc iOsSimFlags*(self: Config): seq[string] =
    ## Compiler flags for compiling for the ios simulator
    @[
        "--cpu:amd64",
        "-d:ios", "-d:simulator",
        "--passC:-isysroot", "--passL:-isysroot",
        "--passC:" & self.sdkPath(MacSdk.iPhoneSim), "--passL:" & self.sdkPath(MacSdk.iPhoneSim),
        "--passL:-fobjc-link-runtime" ]