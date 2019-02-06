import util

type
    Platform* = enum
        Linux, MacOS, iOsSim

    Module* = object ## Modules that can inject settings into the build
        flags*: proc(): seq[string]
        linkerFlags*: proc(): seq[string]
        compilerFlags*: proc(): seq[string]

    Config* = object ## Build configuration
        dryrun*: bool               ## Whether to actually perform actions
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
        binInputPath*: string           ## The primary entry point for the app
        binOutputPath*: string          ## Where to put the executable file
