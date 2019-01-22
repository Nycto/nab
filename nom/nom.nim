import src/private/config, src/private/sdl2, os, sequtils

# General configuration
let conf = Config(
    sourceDir: getCurrentDir(),
    buildDir: getCurrentDir() / "build",
    platform: Platform.Linux,
    macOsSdkVersion: "10.10",
    macOsMinVersion: "10.10"
)

# Collect the list of modules
let modules = @[
    newSdl2Module(conf)
]

# Collect the arguments to pass to nimble
var args = concat(@[ "build" ], conf.platform.flags())
for module in modules:
    args.add(module.flags())

# Invoke nimble
conf.requireSh(conf.sourceDir, requireExe("nimble"), args)

