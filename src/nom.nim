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
    of "dryrun": conf.dryrun = true
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

        discard result.appName.requireNotEmpty("appName", "Add 'appName' to your config, or pass it via --appName")
        discard result.bundleId.requireNotEmpty("bundleId", "Add 'bundleId' to your config, or pass it via --bundleId")
        discard result.version.requireNotEmpty("version", "Add 'version' to your config, or pass it via --version")
        discard result.buildDir.requireNotEmpty("buildDir", "Add 'buildDir' to your config, or pass it via --buildDir")

proc compileConfig(self: Config): CompileConfig =
    ## Returns the compiler flags to pass for a platform build
    case self.platform
    of Platform.Linux: CompileConfig(flags: @[ "--os:linux", "-d:linux" ], binPath: self.appName)
    of Platform.MacOS: CompileConfig(flags: @[ "--os:macosx", "-d:macosx" ], binPath: self.appName)
    of Platform.iOsSim: self.iOsSimCompileConfig()


# General configuration
let conf = readConfig()

handleException(conf):

    # Collect the list of modules
    let modules = @[
        newSdl2Module(conf)
    ]

    let compile = conf.compileConfig()

    # Collect the arguments to pass to nimble
    var args = concat(@[ "build" ], compile.flags, conf.extraFlags)
    for module in modules:
        args.add(module.flags())
        args.add(module.compilerFlags().mapIt("--passC:" & it))
        args.add(module.linkerFlags().mapIt("--passL:" & it))

    args.add(compile.compilerFlags.mapIt("--passC:" & it))
    args.add(compile.linkerFlags.mapIt("--passL:" & it))

    # Define where to put the resulting binary
    compile.binPath.requireNotEmpty("binPath", "This is an internal error").ensureParentDir
    args.add("--out:" & compile.binPath)

    args.add("--nimcache:" & conf.nimcacheDir)

    # Invoke nimble
    conf.requireSh(conf.sourceDir, conf.requireExe("nimble"), args)

