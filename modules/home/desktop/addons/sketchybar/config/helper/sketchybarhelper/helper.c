#include "sketchybar.h"

void handler(env env) {
  // Environment variables passed from sketchybar can be accessed as seen below
  char* name = env_get_value_for_key(env, "NAME");
  char* sender = env_get_value_for_key(env, "SENDER");
  char* info = env_get_value_for_key(env, "INFO");

  if (strcmp(sender, "front_app_switched") == 0) {
    // front_app item update
    char command[256];
    snprintf(command, 256, "--set %s label=\"%s\"", name, info);
    sketchybar(command);
  }
}

int main (int argc, char** argv) {
  if (argc < 2) {
    printf("Usage: provider \"<bootstrap name>\"\n");
    exit(1);
  }

  event_server_begin(handler, argv[1]);
  return 0;
}
