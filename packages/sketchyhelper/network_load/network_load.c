#include "../sketchybar.h"
#include "network.h"
#include <unistd.h>

int main(int argc, char **argv) {
  float update_freq;
  if (argc < 4 || (sscanf(argv[3], "%f", &update_freq) != 1)) {
    printf("Usage: %s \"<interface>\" \"<event-name>\" \"<event_freq>\"\n",
           argv[0]);
    exit(1);
  }

  alarm(0);
  // Setup the event in sketchybar
  char event_message[512];
  snprintf(event_message, 512, "--add event '%s'", argv[2]);
  sketchybar(event_message);

  struct network network;
  network_init(&network, argv[1]);
  char trigger_message[512];
  int last_up = -1;
  int last_down = -1;
  enum unit last_up_unit = -1;
  enum unit last_down_unit = -1;
  for (;;) {
    // Acquire new info
    network_update(&network);

    if (network.up == last_up && network.down == last_down &&
        network.up_unit == last_up_unit &&
        network.down_unit == last_down_unit) {
      usleep(update_freq * 1000000);
      continue;
    }

    last_up = network.up;
    last_down = network.down;
    last_up_unit = network.up_unit;
    last_down_unit = network.down_unit;

    // Prepare the event message
    snprintf(trigger_message, 512,
             "--trigger '%s' upload='%03d%s' download='%03d%s'", argv[2],
             network.up, unit_str[network.up_unit], network.down,
             unit_str[network.down_unit]);

    // Trigger the event
    sketchybar(trigger_message);

    // Wait
    usleep(update_freq * 1000000);
  }
  return 0;
}
