import config, os, util, pegs, configutil, strutils, nimble, plists, streams, json

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
    self.requireDir("/Applications/Xcode.app")

proc xCodeSdksPath(self: Config, sdk: MacSdk): string =
    ## Returns the directory name for an SDK. This path contains all the versions for that SDK
    self.requireDir(self.xCodeAppPath / "Contents/Developer/Platforms/" & sdk.dirName & ".platform/Developer/SDKs")

proc sdkVersion*(self: Config, sdk: MacSdk): string =
    ## Returns the highest installed SDK version
    let searchDir = self.xCodeSdksPath(sdk)

    for file in walkDir(searchDir):
        var dirName = splitFile(file.path).name
        var matches = dirName.findAll(peg"\d+\.\d+")
        if matches.len() > 0:
            return matches[matches.len() - 1]

    self.require(true, "Could not find any SDKs. Searched in " & searchDir)
    return "12.1"

proc sdkNameVersion*(self: Config, sdk: MacSdk): string =
    ## Returns the name/version form of an sdk
    sdk.dirName.toLowerAscii & self.sdkVersion(sdk)

proc sdkPath*(self: Config, sdk: MacSdk): string =
    ## The file path for a specific SDK
    result = self.requireDir(self.xCodeSdksPath(sdk) / (sdk.dirName & self.sdkVersion(sdk) & ".sdk"))

const customMain = staticRead("../../resources/main.nim")

proc mainFile(self: Config): string =
    ## Returns the path to the main custom main entry point
    result = self.platformBuildDir / "nim" / "main.nim"
    if not result.fileExists:
        result.ensureParentDir
        result.writeFile("import " & self.nimbleBin.importable & "\n" & customMain)

const defaultInfoPlist = staticRead("../../resources/Info.plist")

proc createPlist*(self: Config) =
    ## Returns the JsonNode representint the Info.plist file
    let plist = parsePlist(newStringStream(defaultInfoPlist))
    plist["CFBundleName"] = %self.appName
    plist["CFBundleIdentifier"] = %self.bundleId
    plist["CFBundleExecutable"] = %self.appName
    plist["CFBundleShortVersionString"] = %self.version
    plist["CFBundleVersion"] = %self.buildTime

    plist.writePlist(self.macAppDir / "Info.plist")

proc iOsSimCompileConfig*(self: Config): CompileConfig =
    ## Compiler flags for compiling for the ios simulator
    self.createPlist()
    result = CompileConfig(
        flags: @[ "--cpu:arm64", "--noMain", "-d:ios", "-d:simulator", "--os:macosx" ],
        linkerFlags: @[
            "-isysroot", self.sdkPath(MacSdk.iPhoneSim),
            "-fobjc-link-runtime",
            "-mios-version-min=" & self.sdkVersion(MacSdk.iPhoneSim)
        ],
        compilerFlags: @[
            "-isysroot", self.sdkPath(MacSdk.iPhoneSim),
            "-mios-version-min=" & self.sdkVersion(MacSdk.iPhoneSim),
            "-liconv"
        ],
        binOutputPath: self.macAppDir / self.appName,
        binInputPath: self.mainFile
    )

