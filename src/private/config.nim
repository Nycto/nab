import util

type
    Platform* = enum
        Linux, MacOS, iOsSim

    Framework* = object ## The primary framework being used
        flags*: proc(): seq[string]             ## Flags to pass to nimble
        linkerFlags*: proc(): seq[string]       ## Flags to pass to the linker
        compilerFlags*: proc(): seq[string]     ## Flags to pass to the compiler
        main*: proc(): string                   ## The path to the main nim file being compiled

    StrConf* {. pure .} = enum
        appName,    ## The name of this application. For example, "MyApp"
        bundleId,   ## The namespace of this application. For example, "com.example.MyApp"
        version,    ## The version of this release. For example, "1.0.0"
        buildTime,  ## The time at which this build was performed
        sourceDir,  ## Where to find the source code being compiled
        buildDir    ## Where to put all build artifacts

    BoolConf* {. pure .} = enum
        dryrun,     ## Whether to actually perform actions
        run,        ## Triggers an execution of the app after it is built
        debugger,   ## Attempt to wait for a debugger when running
        verbose     ## Whether to display detailed build information

    StrSeqConf* {. pure .} = enum
        extraFlags  ## Additional flags to pass to the nim compiler

    Config* = object ## Build configuration
        platform*: Platform         ## The platform being targetted
        strs*: array[StrConf, string]
        bools*: array[BoolConf, bool]
        strSeqs*: array[StrSeqConf, seq[string]]

    CompileConfig* = object ## Platform configuration for the compiler
        flags*: seq[string]             ## Flags to pass to the nim compiler
        linkerFlags*: seq[string]       ## Flags to pass to the linker
        compilerFlags*: seq[string]     ## Flags to pass to the compiler
        binOutputPath*: string          ## Where to put the executable file
        run*: proc()                    ## Triggers the run

proc `[]`*(self: Config, key: StrConf): string =
    ## Returns as a string key
    self.strs[key]

proc `[]`*(self: Config, key: BoolConf): bool =
    ## Returns as a boolean key
    self.bools[key]

proc `[]`*(self: Config, key: StrSeqConf): seq[string] =
    ## Returns as a str seq key
    self.strSeqs[key]

proc `[]=`*(self: var Config, key: StrConf, value: string) =
    ## Sets a string key
    self.strs[key] = value

proc `[]=`*(self: var Config, key: BoolConf, value: bool) =
    ## Sets a boolean key
    self.bools[key] = value

proc add*(self: var Config, key: StrSeqConf, value: string) =
    ## Adds a string seq key
    self.strSeqs[key].add(value)

