import private/config, private/configutil, private/sdl2, private/mac, private/util
import os, sequtils, parseopt, strutils, times

template handleException(conf: Config, exec: untyped): untyped =
    ## Catches and prints exceptions
    try:
        exec
    except:
        echo getCurrentExceptionMsg()
        if conf.verbose:
            raise
        else:
            quit(QuitFailure)

proc setConfigKey(conf: var Config, key: string, value: string) =
    ## Sets a key/value on a config object
    case key
    of "flag", "f": conf.extraFlags.add(value)
    of "verbose": conf.verbose = true
    of "appName", "n": conf.appName = value
    of "bundleId", "b": conf.bundleId = value
    of "version", "v": conf.version = value
    else: assert(false, "Unrecognized config key: " & key)

proc parseCli(conf: var Config) =
    ## Parses the CLI options into a config
    var parser = initOptParser()
    for kind, key, val in parser.getopt():
        case kind
        of cmdArgument:
            conf.platform = parseEnum[Platform](key)
        of cmdLongOption, cmdShortOption:
            conf.setConfigKey(key, val)
        of cmdEnd:
            assert(false) # cannot happen

proc readConfig(): Config =

    let defaultPlatform =
        when defined(macosx): Platform.MacOS
        else: Platform.Linux

    result = Config(
        buildTime: $getTime().toUnix,
        sourceDir: getCurrentDir(),
        buildDir: getCurrentDir() / "build",
        platform: defaultPlatform,
        macOsSdkVersion: "10.14",
        macOsMinVersion: "10.14",
        iOsSimSdkVersion: "8.1",
        extraFlags: @[],
        verbose: false
    )

    handleException(result):

        # Start by parsing the config file
        for _, key, value in parseConfigFile(getCurrentDir() / "nom.cfg"):
            result.setconfigKey(key, value)

        result.parseCli()

proc flags(self: Config): seq[string] =
    ## Returns the compiler flags to pass for a platform build
    case self.platform
    of Platform.Linux: @[ "--os:linux", "-d:linux" ]
    of Platform.MacOS: @[ "--os:macosx", "-d:macosx" ]
    of Platform.iOsSim: self.iOsSimFlags()


# General configuration
let conf = readConfig()

handleException(conf):

    # Collect the list of modules
    let modules = @[
        newSdl2Module(conf)
    ]

    # Collect the arguments to pass to nimble
    var args = concat(@[ "build" ], conf.flags(), conf.extraFlags)
    for module in modules:
        args.add(module.flags())

    # Invoke nimble
    conf.requireSh(conf.sourceDir, requireExe("nimble"), args)

