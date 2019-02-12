import private/config, private/configutil, private/sdl2, private/mac, private/util, private/nimble, private/readconfig
import os, sequtils, times

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

proc readConfig(): Config =

    let defaultPlatform =
        when defined(macosx): Platform.MacOS
        else: Platform.Linux

    result = Config(
        buildTime: $getTime().toUnix,
        sourceDir: getCurrentDir(),
        buildDir: getCurrentDir() / "build",
        platform: defaultPlatform,
        extraFlags: @[],
        verbose: false
    )

    handleException(result):
        result.parseNimble()
        result.parseConfigFile()
        result.parseCli()

proc compileConfig(self: Config): CompileConfig =
    ## Returns the compiler flags to pass for a platform build
    case self.platform
    of Platform.Linux:
        CompileConfig(
            flags: @[ "--os:linux", "-d:linux" ],
            binOutputPath: self.appName,
            run: proc () = self.requireSh(self.sourceDir, self.appName)
        )
    of Platform.MacOS:
        CompileConfig(
            flags: @[ "--os:macosx", "-d:macosx" ],
            binOutputPath: self.appName,
            run: proc () = self.requireSh(self.sourceDir, self.appName)
        )
    of Platform.iOsSim:
        self.iOsSimCompileConfig()


# General configuration
let conf = readConfig()

handleException(conf):

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
    args.add("--path:" & conf.sourceDir)

    # Keep the nimcache separate for each platform
    args.add("--nimcache:" & conf.nimcacheDir)

    args.add(compile.flags)
    args.add(conf.extraFlags)

    args.add(framework.flags())
    args.add(framework.compilerFlags().mapIt("--passC:" & it))
    args.add(framework.linkerFlags().mapIt("--passL:" & it))

    args.add(compile.compilerFlags.mapIt("--passC:" & it))
    args.add(compile.linkerFlags.mapIt("--passL:" & it))

    # Invoke nimble
    conf.requireSh(conf.sourceDir, conf.requireExe("nimble"), args)

    if conf.run:
        compile.run()

