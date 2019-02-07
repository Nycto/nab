import util

type
    Platform* = enum
        Linux, MacOS, iOsSim

    Framework* = object ## The primary framework being used
        flags*: proc(): seq[string]             ## Flags to pass to nimble
        linkerFlags*: proc(): seq[string]       ## Flags to pass to the linker
        compilerFlags*: proc(): seq[string]     ## Flags to pass to the compiler
        main*: proc(): string                   ## The path to the main nim file being compiled

    Config* = object ## Build configuration
        dryrun*: bool               ## Whether to actually perform actions
        run*: bool                  ## Triggers an execution of the app after it is built
        debugger*: bool             ## Attempt to wait for a debugger when running
        appName*: string            ## The name of this application. For example, "MyApp"
        bundleId*: string           ## The namespace of this application. For example, "com.example.MyApp"
        version*: string            ## The version of this release. For example, "1.0.0"
        buildTime*: string          ## The time at which this build was performed
        sourceDir*: string          ## Where to find the source code being compiled
        buildDir*: string           ## Where to put all build artifacts
        platform*: Platform         ## The platform being targetted
        extraFlags*: seq[string]    ## Additional flags to pass to the nim compiler
        verbose*: bool              ## Whether to display detailed build information

    CompileConfig* = object ## Platform configuration for the compiler
        flags*: seq[string]             ## Flags to pass to the nim compiler
        linkerFlags*: seq[string]       ## Flags to pass to the linker
        compilerFlags*: seq[string]     ## Flags to pass to the compiler
        binOutputPath*: string          ## Where to put the executable file
        run*: proc()                    ## Triggers the run
