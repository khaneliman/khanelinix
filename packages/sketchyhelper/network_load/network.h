#include <net/if.h>
#include <net/if_mib.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/sysctl.h>
#include <sys/time.h>

static char unit_str[3][6] = {
    {" Bps"},
    {"KBps"},
    {"MBps"},
};

enum unit { UNIT_BPS, UNIT_KBPS, UNIT_MBPS };
struct network {
  const char *ifname;
  unsigned int row;
  struct ifmibdata data;
  struct timeval tv_nm1, tv_n, tv_delta;

  int up;
  int down;
  enum unit up_unit, down_unit;
};

static inline bool ifdata(unsigned int net_row, struct ifmibdata *data) {
  size_t size = sizeof(*data);
  int data_option[] = {CTL_NET, PF_LINK, NETLINK_GENERIC,
                       IFMIB_IFDATA, (int)net_row, IFDATA_GENERAL};
  return sysctl(data_option, 6, data, &size, NULL, 0) == 0 &&
         size == sizeof(*data);
}

static inline void network_init(struct network *net, const char *ifname) {
  memset(net, 0, sizeof(struct network));
  net->ifname = ifname;
  net->row = if_nametoindex(ifname);
}

static inline void network_update(struct network *net) {
  struct ifmibdata data;
  if (!net->row || !ifdata(net->row, &data) ||
      strcmp(data.ifmd_name, net->ifname) != 0)
    return;

  gettimeofday(&net->tv_n, NULL);
  timersub(&net->tv_n, &net->tv_nm1, &net->tv_delta);
  net->tv_nm1 = net->tv_n;

  uint64_t ibytes_nm1 = net->data.ifmd_data.ifi_ibytes;
  uint64_t obytes_nm1 = net->data.ifmd_data.ifi_obytes;
  net->data = data;

  double time_scale = (net->tv_delta.tv_sec + 1e-6 * net->tv_delta.tv_usec);
  if (time_scale < 1e-6 || time_scale > 1e2 ||
      data.ifmd_data.ifi_ibytes < ibytes_nm1 ||
      data.ifmd_data.ifi_obytes < obytes_nm1)
    return;
  double delta_ibytes =
      (double)(net->data.ifmd_data.ifi_ibytes - ibytes_nm1) / time_scale;
  double delta_obytes =
      (double)(net->data.ifmd_data.ifi_obytes - obytes_nm1) / time_scale;

  if (delta_ibytes < 1000) {
    net->down_unit = UNIT_BPS;
    net->down = delta_ibytes;
  } else if (delta_ibytes < 1000000) {
    net->down_unit = UNIT_KBPS;
    net->down = delta_ibytes / 1000.0;
  } else {
    net->down_unit = UNIT_MBPS;
    net->down = delta_ibytes / 1000000.0;
  }

  if (delta_obytes < 1000) {
    net->up_unit = UNIT_BPS;
    net->up = delta_obytes;
  } else if (delta_obytes < 1000000) {
    net->up_unit = UNIT_KBPS;
    net->up = delta_obytes / 1000.0;
  } else {
    net->up_unit = UNIT_MBPS;
    net->up = delta_obytes / 1000000.0;
  }
}
