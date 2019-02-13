import util, config as c, parseopt, strutils, os, parsecfg as pc, nimble

type CliAction* = enum ## The CLI action requested by the user
    Initialize, Compile

proc setConfigKey*(conf: var c.Config, key: string, value: string) =
    ## Sets a key/value on a config object
    tryParseEnum(StrConf, key, strKey):
        conf[strKey] = value
        return

    tryParseEnum(BoolConf, key, boolKey):
        conf[boolKey] = true
        return

    tryParseEnum(StrSeqConf, key, strSeqKey):
        conf.add(strSeqKey, value)
        return

    case key
    of "f": conf.add(extraFlags, value)
    of "r": conf[run] = true
    else: assert(false, "Unrecognized config key: " & key)

proc parseCli*(conf: var c.Config): CliAction =
    ## Parses the CLI options into a config
    result = CliAction.Compile
    var parser = initOptParser()
    for kind, key, val in parser.getopt():
        case kind
        of cmdArgument:
            if key == "init":
                result = CliAction.Initialize
            else:
                conf.platform = parseEnum[Platform](key)
        of cmdLongOption, cmdShortOption:
            conf.setConfigKey(key, val)
        of cmdEnd:
            assert(false) # cannot happen

proc configFilePath*(): string =
    ## The path of the config file
    getCurrentDir() / "nab.cfg"

proc parseConfigFile*(conf: var c.Config) =
    ## Parses the config file in the cwd for settings
    for _, key, value in parseConfigFile(configFilePath()):
        conf.setconfigKey(key, value)

proc parseNimble*(conf: var c.Config) =
    ## Pulls settings out of nimble
    let nimbleConf = conf.nimbleDump()
    let name = nimbleConf.getSectionValue("", "name")
    if name != "":
        conf[appName] = name

