import src/private/config, src/private/sdl2, os

proc build(self: Config) =
    let sdl2 = self.sdl2()
    self.requireSh(
        self.sourceDir,
        requireExe("nimble"),
        "build",
        "--threads:on",
        "--dynlibOverride:SDL2",
        "--passL:" & sdl2,
        "--passL:-lm",
        "--passL:-liconv",
        "--passL:'-framework CoreAudio'",
        "--passL:'-framework AudioToolbox'",
        "--passL:'-framework CoreGraphics'",
        "--passL:'-framework QuartzCore'",
        "--passL:'-framework OpenGL'",
        "--passL:'-framework AppKit'",
        "--passL:'-framework AudioUnit'",
        "--passL:'-framework ForceFeedback'",
        "--passL:'-framework IOKit'",
        "--passL:'-framework Carbon'",
        "--passL:'-framework CoreServices'",
        "--passL:'-framework ApplicationServices'",
        "--passL:'-framework Metal'"
    )

let conf = Config(
    sourceDir: getCurrentDir(),
    buildDir: getCurrentDir() / "build",
    sdl2Version: "2.0.9"
)

conf.build()

