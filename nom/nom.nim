import src/private/config, src/private/sdl2, os, sequtils, parseopt, strutils

proc parseCli(): Config =
    ## Parses the CLI options into a config

    # General configuration
    result = Config(
        sourceDir: getCurrentDir(),
        buildDir: getCurrentDir() / "build",
        platform: Platform.Linux,
        macOsSdkVersion: "10.10",
        macOsMinVersion: "10.10",
        extraFlags: @[],
        verbose: false
    )

    var parser = initOptParser()
    for kind, key, val in parser.getopt():
        case kind
        of cmdArgument:
            result.platform = parseEnum[Platform](key)
        of cmdLongOption, cmdShortOption:
            case key
            of "flag", "f": result.extraFlags.add(val)
            of "verbose", "v": result.verbose = true
        of cmdEnd:
            assert(false) # cannot happen


let conf = parseCli()

try:

    # Collect the list of modules
    let modules = @[
        newSdl2Module(conf)
    ]

    # Collect the arguments to pass to nimble
    var args = concat(@[ "build" ], conf.platform.flags(), conf.extraFlags)
    for module in modules:
        args.add(module.flags())

    # Invoke nimble
    conf.requireSh(conf.sourceDir, requireExe("nimble"), args)

except:
    echo getCurrentExceptionMsg()
    if conf.verbose:
        raise
    else:
        quit(QuitFailure)

