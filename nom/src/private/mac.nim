import config, os

proc xCodeAppPath*(self: Config): string =
    ## Where to find XCode
    "/Applications/Xcode.app"

proc iOsSimulatorSdkPath*(self: Config): string =
    ## The file path for the ios simulator SDK
    let filename = "iPhoneSimulator" & self.iOsSimSdkVersion & ".sdk"
    result = self.xCodeAppPath / "Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs" / filename

proc iOsSimFlags*(self: Config): seq[string] =
    ## Compiler flags for compiling for the ios simulator
    @[
        "--cpu:amd64",
        "-d:ios", "-d:simulator",
        "--passC:-isysroot", "--passL:-isysroot",
        "--passC:" & self.iOsSimulatorSdkPath, "--passL:" & self.iOsSimulatorSdkPath,
        "--passL:-fobjc-link-runtime" ]
