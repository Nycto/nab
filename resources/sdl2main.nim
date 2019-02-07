# This is the main file to use when compiling with SDL2

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
