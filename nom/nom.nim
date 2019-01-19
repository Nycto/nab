import src/private/config, src/private/sdl2, os

# General configuration
let conf = Config(
    sourceDir: getCurrentDir(),
    buildDir: getCurrentDir() / "build",
    platform: Platform.Linux
)

# Collect the list of modules
let modules = @[
    newSdl2Module(conf)
]

# Collect the arguments to pass to nimble
var args = @[ "build" ]
for module in modules:
    args.add(module.flags())

# Invoke nimble
conf.requireSh(conf.sourceDir, requireExe("nimble"), args)

