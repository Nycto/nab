import private / [ config, configutil, sdl2, mac, util, nimble, readconfig, initialize ]
import os, sequtils, times

template handleException(conf: Config, exec: untyped): untyped =
    ## Catches and prints exceptions
    try:
        exec
    except:
        echo getCurrentExceptionMsg()
        if conf[verbose]:
            raise
        else:
            quit(QuitFailure)

proc readConfig(): tuple[action: CliAction, conf: Config] =
    ## Reads the configuration to use for this build

    let defaultPlatform =
        when defined(macosx): Platform.MacOS
        else: Platform.Linux

    result.conf = Config(platform: defaultPlatform)
    result.conf[buildTime] = $getTime().toUnix
    result.conf[sourceDir] = getCurrentDir()
    result.conf[buildDir] = getCurrentDir() / "build"
    result.conf[verbose] = false

    handleException(result.conf):
        result.conf.parseNimble()
        result.conf.parseConfigFile()
        result.action = result.conf.parseCli()

proc compileConfig(self: Config): CompileConfig =
    ## Returns the compiler flags to pass for a platform build
    case self.platform
    of Platform.Linux:
        CompileConfig(
            flags: @[ "--os:linux", "-d:linux" ],
            binOutputPath: self[appName],
            run: proc () = self.requireSh(self[sourceDir], self[appName])
        )
    of Platform.MacOS:
        CompileConfig(
            flags: @[ "--os:macosx", "-d:macosx" ],
            binOutputPath: self[appName],
            run: proc () = self.requireSh(self[sourceDir], self[appName])
        )
    of Platform.iOsSim:
        self.iOsSimCompileConfig()

proc compile(conf: Config) =

    # Instantiate the primary framework
    let framework = newSdl2Framework(conf)

    let main = if framework.main == nil: conf.nimbleBin.absPath else: framework.main()

    discard main.requireNotEmpty("framework.main()", "This is an internal error")
    discard conf.requireFile(main)

    # The arguments to pass to nimble
    var args = @[ "c", main ]

    let compile = conf.compileConfig()

    # Define where to put the resulting binary
    compile.binOutputPath.requireNotEmpty("binOutputPath", "This is an internal error").ensureParentDir
    args.add("--out:" & compile.binOutputPath)

    # Make sure the source dir is includable
    args.add("--path:" & conf[sourceDir])

    # Keep the nimcache separate for each platform
    args.add("--nimcache:" & conf.nimcacheDir)

    args.add(compile.flags)
    args.add(conf[extraFlags])

    args.add(framework.flags())
    args.add(framework.compilerFlags().mapIt("--passC:" & it))
    args.add(framework.linkerFlags().mapIt("--passL:" & it))

    args.add(compile.compilerFlags.mapIt("--passC:" & it))
    args.add(compile.linkerFlags.mapIt("--passL:" & it))

    # Invoke nimble
    conf.requireSh(conf[sourceDir], conf.requireExe("nimble"), args)

    if conf[run]:
        compile.run()

# General configuration
let (action, conf) = readConfig()

handleException(conf):
    case action
    of CliAction.Initialize: conf.initialize()
    of CliAction.Compile: conf.compile()

