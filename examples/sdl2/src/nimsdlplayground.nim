import sdl2, sdl2/gfx, random

discard sdl2.init(INIT_EVERYTHING)

var
  window: WindowPtr
  render: RendererPtr

window = createWindow("SDL Skeleton", 100, 100, 640,480, SDL_WINDOW_SHOWN)
render = createRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)

var
  evt = sdl2.defaultEvent
  runGame = true

while runGame:
  while pollEvent(evt):
    if evt.kind == QuitEvent:
      runGame = false
      break

  render.setDrawColor uint8(rand(255)), 0, 0, 255
  render.clear

  render.present

destroy render
destroy window



{.emit: """
//#include <SDL2/SDL_main.h>
extern int cmdCount;
extern char** cmdLine;
extern char** gEnv;
N_CDECL(void, NimMain)(void);
int main(int argc, char *argv[]) {
  cmdLine = argv;
  cmdCount = argc;
  gEnv = NULL;
  NimMain();
  return nim_program_result;
}
""".}