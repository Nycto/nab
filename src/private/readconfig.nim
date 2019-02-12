import util, config as c, parseopt, strutils, os, parsecfg as pc, nimble

proc setConfigKey*(conf: var c.Config, key: string, value: string) =
    ## Sets a key/value on a config object
    case key
    of "dryrun": conf.dryrun = true
    of "flag", "f": conf.extraFlags.add(value)
    of "verbose": conf.verbose = true
    of "appName", "n": conf.appName = value
    of "bundleId", "b": conf.bundleId = value
    of "version", "v": conf.version = value
    of "run", "r": conf.run = true
    of "debugger": conf.debugger = true
    else: assert(false, "Unrecognized config key: " & key)

proc parseCli*(conf: var c.Config) =
    ## Parses the CLI options into a config
    var parser = initOptParser()
    for kind, key, val in parser.getopt():
        case kind
        of cmdArgument:
            conf.platform = parseEnum[Platform](key)
        of cmdLongOption, cmdShortOption:
            conf.setConfigKey(key, val)
        of cmdEnd:
            assert(false) # cannot happen

proc parseConfigFile*(conf: var c.Config) =
    ## Parses the config file in the cwd for settings
    for _, key, value in parseConfigFile(getCurrentDir() / "nab.cfg"):
        conf.setconfigKey(key, value)

proc parseNimble*(conf: var c.Config) =
    ## Pulls settings out of nimble
    let nimbleConf = conf.nimbleDump()
    let name = nimbleConf.getSectionValue("", "name")
    if name != "":
        conf.appName = name
