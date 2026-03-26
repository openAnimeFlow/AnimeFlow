#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <cstdint>
#include <flutter/dart_project.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <optional>
#include <utility>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Native MethodChannel: network_speed_monitor (start/get/stop).
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      network_speed_channel_;

  // Used to calculate upload/download rate.
  std::optional<uint64_t> last_rx_bytes_;
  std::optional<uint64_t> last_tx_bytes_;
  std::optional<double> last_time_sec_;

  void ResetNetworkSpeedState();
  std::pair<uint64_t, uint64_t> GetCurrentRxTxBytes();
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
