import config as c, readconfig, parsecfg as pc, util

proc strConfMessage(key: StrConf): tuple[message, example: string] =
    ## Returns metadata about a string configuration key
    case key
    of appName:     ("The display name of this application.", "My App")
    of bundleId:    ("The unique namespace of this application.", "com.example.MyApp")
    of version:     ("The version of this release", "1.0.0")
    of sourceDir:   ("Where to find the source code being compiled", ".")
    of buildDir:    ("Where to put all build artifacts", "build")
    of buildTime:   raise newException(AssertionError, "Should not generally be initialized")

proc readStrConf(conf: var pc.Config, key: StrConf, defaults: c.Config) =
    ## Reads a string configuration value from the command line
    let (message, example) = key.strConfMessage()

    echo $key, ": ", message
    echo "For example: ", example
    echo "Default: ", defaults[key]
    echo "What value would you like to use for ", $key, "?"

    stdout.write("> ")
    let value = stdin.readLine().apply(read):
        if read == "": defaults[key] else: read

    echo ""

    if value != "":
        conf.setSectionKey("", $key, value)

proc initialize*(defaults: c.Config) =
    ## Initializes the nab.cfg file by asking for user input
    var configFile = newConfig()

    for strKey in items(StrConf):
        if strKey notin { buildTime }:
            configFile.readStrConf(strKey, defaults)

    configFile.writeConfig(configFilePath())
