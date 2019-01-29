import src/private/config, src/private/configutil, src/private/sdl2
import os, sequtils, parseopt, strutils

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

proc parseCli(): Config =
    ## Parses the CLI options into a config

    # General configuration
    result = Config(
        sourceDir: getCurrentDir(),
        buildDir: getCurrentDir() / "build",
        platform: Platform.Linux,
        macOsSdkVersion: "10.14",
        macOsMinVersion: "10.14",
        iOsSimSdkVersion: "8.1",
        extraFlags: @[],
        verbose: false
    )

    handleException(result):
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

