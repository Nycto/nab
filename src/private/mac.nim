import config, os, util, pegs, configutil, strutils, plists, streams, json

type MacSdk* = enum
    ## Mac SDKs that can be targeted for compilation
    iPhone,
    iPhoneSim,
    MacOSX

proc dirName(sdk: MacSdk): string =
    ## Given an SDK, returns the file system name used for it
    case sdk
    of MacSdk.iPhone: "iPhoneOS"
    of MacSdk.iPhoneSim: "iPhoneSimulator"
    of MacSdk.MacOSX: "MacOSX"

proc macSdk*(self: Config): MacSdk =
    ## Given an SDK, returns the file system name used for it
    case self.platform
    of Platform.iOsSim: MacSdk.iPhoneSim
    of Platform.MacOs: MacSdk.MacOSX
    of Platform.Linux: raise newException(AssertionError, "Could not determine mac sdk from platform")

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

proc bootedDeviceId(self: Config): string =
    ## Queries for running devices and returns its id
    let args = [ "simctl", "list", "devices", "-j" ]
    let data = self.requireCaptureSh(self.requireExe("xcrun"), self.sourceDir, args) do (stream: auto) -> auto:
        try:
            parseJson(stream, "xcrun simctl list devices -j")
        except JsonParsingError:
            self.fail("Json parsing error while trying to collect simulator device list: " & getCurrentExceptionMsg())
            newJObject()

    let devices = if data.hasKey("devices"): data["devices"] else: newJObject()
    for _, entry in pairs(devices):
        if entry.getStr("state") == "Booted" and entry.getStr("udid").len > 0:
            return entry.getStr("udid")

    self.require(false, "No running devices found when running `xcrun simctl list devices`")
    return "NO-RUNNING-DEVICE"

proc runIOsSimulator(self: Config) =
    ## Executes the iOs simulator

    # Start the simulator
    let iOsSimApp = self.requireDir(self.xCodeAppPath / "Contents/Developer/Applications/Simulator.app")
    self.requireSh(self.requireExe("open"), self.sourceDir, [ iOsSimApp ])

    let xcrun = self.requireExe("xcrun")
    let deviceId = self.bootedDeviceId()

    # Uninstall previous versions of the app
    self.requireSh(xcrun, self.sourceDir, [ "simctl", "uninstall", deviceId, self.appName ])

    # Install the app
    self.requireSh(xcrun, self.sourceDir, [ "simctl", "install", deviceId, self.macAppDir ])

    # Now launch
    var launchArgs = @[ "simctl", "launch" ]
    if self.debugger: launchArgs.add("--wait-for-debugger")
    launchArgs.add([ deviceId, self.appName ])
    self.requireSh(xcrun, self.sourceDir, launchArgs)

proc iOsSimCompileConfig*(self: Config): CompileConfig =
    ## Compiler flags for compiling for the ios simulator
    self.createPlist()
    result = CompileConfig(
        flags: @[ "--cpu:arm64", "-d:ios", "-d:simulator", "--os:macosx" ],
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
        run: proc() = self.runIOsSimulator()
    )

