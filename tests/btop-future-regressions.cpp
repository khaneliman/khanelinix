
#include <atomic>
#include <chrono>
#include <deque>
#include <future>
#include <iostream>
#include <thread>
#include <utility>
#include <vector>
struct SensorResult {
  long long package_temp{};
  std::vector<long long> core_temps;
  bool valid{false};
};
struct Cpu {
  long long temp_max{};
  std::vector<std::deque<long long>> temp{2};
} current_cpu;
bool got_sensors = true, macM1 = true, cpu_temp_only = false;
namespace Shared {
int coreCount = 1;
}
namespace Config {
bool getB(const char *) { return true; }
} // namespace Config
using std::cmp_less;
std::promise<void> release_promise;
auto release_gate = release_promise.get_future().share();
std::atomic<int> collections = 0;
SensorResult collect_sensors() {
  ++collections;
  release_gate.wait();
  return {60, {59}, true};
}

void update_sensors();

// UPDATE_SENSORS

int main() {
  update_sensors();
  while (collections.load() != 1)
    std::this_thread::yield();
  auto call = std::async(std::launch::async, update_sensors);
  bool returned = call.wait_for(std::chrono::milliseconds(100)) ==
                  std::future_status::ready;
  int pending_calls = collections.load();
  release_promise.set_value();
  call.get();
  auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(1);
  while (current_cpu.temp[0].empty() &&
         std::chrono::steady_clock::now() < deadline) {
    update_sensors();
    std::this_thread::yield();
  }
  bool consumed =
      !current_cpu.temp[0].empty() && current_cpu.temp[0].back() == 60;
  std::cout << "{\"returned_while_sensor_blocked\":"
            << (returned ? "true" : "false")
            << ",\"pending_sensor_calls\":" << pending_calls
            << ",\"completed_result_consumed\":"
            << (consumed ? "true" : "false") << "}\n";
}
